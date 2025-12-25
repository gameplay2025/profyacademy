-- ============================================
-- Simple LMS - Supabase Database Setup Script
-- ============================================
-- Run this script in the Supabase SQL Editor
-- ============================================

-- ============================================
-- 1.1 Create profiles table
-- ============================================
-- Stores user profiles with role-based access control
-- Links to auth.users via foreign key

CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'student' CHECK (role IN ('admin', 'assistant', 'student')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add comment for documentation
COMMENT ON TABLE public.profiles IS 'User profiles with role-based access control';
COMMENT ON COLUMN public.profiles.role IS 'User role: admin, assistant, or student';


-- ============================================
-- 1.2 Create materials table
-- ============================================
-- Stores educational materials (PDFs and YouTube links)

CREATE TABLE IF NOT EXISTS public.materials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('pdf', 'youtube')),
  url TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add comment for documentation
COMMENT ON TABLE public.materials IS 'Educational materials: PDFs and YouTube links';
COMMENT ON COLUMN public.materials.type IS 'Material type: pdf or youtube';


-- ============================================
-- 1.3 Create schedule table
-- ============================================
-- Stores class schedule entries

CREATE TABLE IF NOT EXISTS public.schedule (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  day TEXT NOT NULL,
  time TEXT NOT NULL,
  subject TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add comment for documentation
COMMENT ON TABLE public.schedule IS 'Class schedule with day, time, and subject';


-- ============================================
-- 1.4 Create trigger for automatic profile creation
-- ============================================
-- Automatically creates a profile with 'student' role when a new user registers

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, role)
  VALUES (NEW.id, 'student');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on auth.users table
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ============================================
-- 1.5 Enable RLS and create policies
-- ============================================

-- Enable Row Level Security on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schedule ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------
-- Profiles table policies
-- ----------------------------------------
-- Users can only read their own profile
CREATE POLICY "Users can read own profile"
  ON public.profiles
  FOR SELECT
  USING (auth.uid() = id);

-- ----------------------------------------
-- Materials table policies
-- ----------------------------------------
-- All authenticated users can read materials
CREATE POLICY "Authenticated users can read materials"
  ON public.materials
  FOR SELECT
  TO authenticated
  USING (true);

-- Only admin and assistant can insert materials
CREATE POLICY "Admin and assistant can insert materials"
  ON public.materials
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'assistant')
    )
  );

-- Only admin and assistant can update materials
CREATE POLICY "Admin and assistant can update materials"
  ON public.materials
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'assistant')
    )
  );

-- Only admin and assistant can delete materials
CREATE POLICY "Admin and assistant can delete materials"
  ON public.materials
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'assistant')
    )
  );

-- ----------------------------------------
-- Schedule table policies
-- ----------------------------------------
-- All authenticated users can read schedule
CREATE POLICY "Authenticated users can read schedule"
  ON public.schedule
  FOR SELECT
  TO authenticated
  USING (true);

-- Only admin and assistant can insert schedule entries
CREATE POLICY "Admin and assistant can insert schedule"
  ON public.schedule
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'assistant')
    )
  );

-- Only admin and assistant can update schedule entries
CREATE POLICY "Admin and assistant can update schedule"
  ON public.schedule
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'assistant')
    )
  );

-- Only admin and assistant can delete schedule entries
CREATE POLICY "Admin and assistant can delete schedule"
  ON public.schedule
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'assistant')
    )
  );


-- ============================================
-- 1.6 Storage bucket policies
-- ============================================
-- NOTE: The 'materials' bucket must be created manually in the Supabase Dashboard:
-- 1. Go to Storage in your Supabase project
-- 2. Click "New bucket"
-- 3. Name it "materials"
-- 4. Set it as private (not public)

-- Storage policies for the 'materials' bucket
-- All authenticated users can read/download files
CREATE POLICY "Authenticated users can read materials files"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (bucket_id = 'materials');

-- Only admin and assistant can upload files
CREATE POLICY "Admin and assistant can upload materials files"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'materials'
    AND EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'assistant')
    )
  );

-- Only admin and assistant can update files
CREATE POLICY "Admin and assistant can update materials files"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'materials'
    AND EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'assistant')
    )
  );

-- Only admin and assistant can delete files
CREATE POLICY "Admin and assistant can delete materials files"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'materials'
    AND EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'assistant')
    )
  );

-- ============================================
-- Setup Complete!
-- ============================================
-- After running this script:
-- 1. Create the 'materials' storage bucket manually in the Supabase Dashboard
-- 2. Verify tables are created: profiles, materials, schedule
-- 3. Verify RLS is enabled on all tables
-- 4. Test by creating a user and checking the profile is auto-created
-- ============================================
