ALTER TABLE public.foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON TABLE public.foods, public.products TO anon, authenticated;

CREATE POLICY foods_public_read
ON public.foods
FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY products_public_read
ON public.products
FOR SELECT
TO anon, authenticated
USING (true);
