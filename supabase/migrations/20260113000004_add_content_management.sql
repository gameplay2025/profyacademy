-- Create content table for managing lessons/videos
CREATE TABLE IF NOT EXISTS public.content (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    grade_level INTEGER NOT NULL CHECK (grade_level IN (5, 6, 7)),
    title TEXT NOT NULL,
    description TEXT,
    youtube_url TEXT,
    work_url TEXT,
    correction_url TEXT,
    fb_work_url TEXT,
    fb_correction_url TEXT,
    lesson_date DATE NOT NULL DEFAULT CURRENT_DATE,
    is_published BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES public.user_profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.content ENABLE ROW LEVEL SECURITY;

-- Everyone can read published content
CREATE POLICY "Anyone can read published content" ON public.content
    FOR SELECT
    TO authenticated
    USING (is_published = TRUE);

-- Admins can do everything with content
CREATE POLICY "Admins full access to content" ON public.content
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles up
            WHERE up.id = auth.uid() AND up.role = 'admin'
        )
    );

-- Trigger for updated_at
CREATE TRIGGER update_content_updated_at
    BEFORE UPDATE ON public.content
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
