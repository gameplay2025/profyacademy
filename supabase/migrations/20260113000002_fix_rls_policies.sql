-- Drop existing policies
DROP POLICY IF EXISTS "Users can read own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Admins can read all profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Admins can delete profiles" ON public.user_profiles;

-- Simpler policies that work correctly

-- Anyone authenticated can read their own profile
CREATE POLICY "Users can read own profile" ON public.user_profiles
    FOR SELECT 
    TO authenticated
    USING (auth.uid() = id);

-- Anyone authenticated can update their own profile
CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE 
    TO authenticated
    USING (auth.uid() = id);

-- Allow the trigger to insert profiles (runs as SECURITY DEFINER)
CREATE POLICY "Allow profile creation" ON public.user_profiles
    FOR INSERT 
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- Admins can do everything
CREATE POLICY "Admins full access" ON public.user_profiles
    FOR ALL 
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles up
            WHERE up.id = auth.uid() AND up.role = 'admin'
        )
    );
