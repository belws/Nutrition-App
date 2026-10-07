CREATE TYPE public.sex AS ENUM ('male', 'female');
CREATE TYPE public.activity_level AS ENUM (
    'sedentary', 'lightly_active', 'moderately_active',
    'very_active', 'extra_active'
);
CREATE TYPE public.goal AS ENUM ('lose', 'maintain', 'gain');

CREATE TABLE public.user_profiles (
    user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    sex public.sex NOT NULL,
    date_of_birth date NOT NULL,
    height_cm numeric NOT NULL CHECK (height_cm > 0),
    weight_kg numeric NOT NULL CHECK (weight_kg > 0),
    activity_level public.activity_level NOT NULL,
    goal public.goal NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER user_profiles_set_updated_at
BEFORE UPDATE ON public.user_profiles
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Remove any privileges inherited from default table grants.
REVOKE ALL PRIVILEGES ON TABLE public.user_profiles FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.user_profiles TO authenticated;

CREATE POLICY user_profiles_select_own
ON public.user_profiles
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY user_profiles_insert_own
ON public.user_profiles
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY user_profiles_update_own
ON public.user_profiles
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);
