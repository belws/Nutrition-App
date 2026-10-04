CREATE TYPE public.nutrition_basis_unit AS ENUM ('g', 'ml');
CREATE TYPE public.product_data_source AS ENUM (
    'manual', 'open_food_facts', 'user_submission'
);
CREATE TYPE public.product_verification_status AS ENUM (
    'unverified', 'user_confirmed', 'verified'
);

CREATE TABLE public.foods (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    category text,
    nutrition_basis_unit public.nutrition_basis_unit NOT NULL DEFAULT 'g',
    energy_kcal numeric CHECK (energy_kcal >= 0),
    protein_g numeric CHECK (protein_g >= 0),
    carbohydrates_g numeric CHECK (carbohydrates_g >= 0),
    sugars_g numeric CHECK (sugars_g >= 0),
    fat_g numeric CHECK (fat_g >= 0),
    saturated_fat_g numeric CHECK (saturated_fat_g >= 0),
    fiber_g numeric CHECK (fiber_g >= 0),
    salt_g numeric CHECK (salt_g >= 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON COLUMN public.foods.nutrition_basis_unit IS
    'All nutrition values are per 100 g or per 100 ml according to this unit.';

CREATE TABLE public.products (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    food_id uuid REFERENCES public.foods(id) ON DELETE SET NULL,
    barcode text NOT NULL UNIQUE,
    name text NOT NULL,
    brand text,
    net_quantity numeric CHECK (net_quantity >= 0),
    net_quantity_unit text,
    nutrition_basis_unit public.nutrition_basis_unit NOT NULL DEFAULT 'g',
    energy_kcal numeric CHECK (energy_kcal >= 0),
    protein_g numeric CHECK (protein_g >= 0),
    carbohydrates_g numeric CHECK (carbohydrates_g >= 0),
    sugars_g numeric CHECK (sugars_g >= 0),
    fat_g numeric CHECK (fat_g >= 0),
    saturated_fat_g numeric CHECK (saturated_fat_g >= 0),
    fiber_g numeric CHECK (fiber_g >= 0),
    salt_g numeric CHECK (salt_g >= 0),
    data_source public.product_data_source NOT NULL,
    verification_status public.product_verification_status NOT NULL DEFAULT 'unverified',
    front_image_path text,
    nutrition_image_path text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON COLUMN public.products.nutrition_basis_unit IS
    'All nutrition values are per 100 g or per 100 ml according to this unit.';
COMMENT ON COLUMN public.products.front_image_path IS
    'Storage path for the product front image, not a public URL.';
COMMENT ON COLUMN public.products.nutrition_image_path IS
    'Storage path for the nutrition label image, not a public URL.';

CREATE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER foods_set_updated_at
BEFORE UPDATE ON public.foods
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER products_set_updated_at
BEFORE UPDATE ON public.products
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();
