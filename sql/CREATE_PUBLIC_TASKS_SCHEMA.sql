-- Public Tasks Schema
-- This schema enables users to publish tasks publicly and allows anyone to join them
-- Run this in Supabase SQL Editor

-- 1. Create categories table
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  icon TEXT, -- Icon name for the category
  color TEXT, -- Color code for the category
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default categories
INSERT INTO public.categories (name, icon, color) VALUES
  ('Life', 'home', '#4CAF50'),
  ('Business', 'business', '#2196F3'),
  ('Music', 'music_note', '#9C27B0'),
  ('Food', 'restaurant', '#FF9800'),
  ('Health', 'favorite', '#F44336'),
  ('Education', 'school', '#3F51B5'),
  ('Travel', 'flight', '#00BCD4'),
  ('Sports', 'sports', '#4CAF50'),
  ('Technology', 'computer', '#607D8B'),
  ('Art', 'palette', '#E91E63')
ON CONFLICT (name) DO NOTHING;

-- 2. Add is_public column to tasks table
ALTER TABLE public.tasks
ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT FALSE;

ALTER TABLE public.tasks
ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES public.categories(id);

ALTER TABLE public.tasks
ADD COLUMN IF NOT EXISTS public_join_count INTEGER DEFAULT 0;

-- Create index for public tasks
CREATE INDEX IF NOT EXISTS idx_tasks_is_public ON public.tasks(is_public);
CREATE INDEX IF NOT EXISTS idx_tasks_category ON public.tasks(category_id);

-- 3. Create public_task_participants table
CREATE TABLE IF NOT EXISTS public.public_task_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  contribution INTEGER DEFAULT 0, -- Percentage of contribution
  completed_count INTEGER DEFAULT 0, -- Number of times task was completed
  UNIQUE(task_id, user_id)
);

-- Create indexes for public_task_participants
CREATE INDEX IF NOT EXISTS idx_public_task_participants_task ON public.public_task_participants(task_id);
CREATE INDEX IF NOT EXISTS idx_public_task_participants_user ON public.public_task_participants(user_id);

-- 4. Enable RLS on new tables
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.public_task_participants ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for categories (everyone can read)
DROP POLICY IF EXISTS "Anyone can view categories" ON public.categories;
CREATE POLICY "Anyone can view categories"
  ON public.categories FOR SELECT
  USING (true);

-- 6. RLS Policies for public_task_participants
-- Users can view all public task participants
DROP POLICY IF EXISTS "Anyone can view public task participants" ON public.public_task_participants;
CREATE POLICY "Anyone can view public task participants"
  ON public.public_task_participants FOR SELECT
  USING (true);

-- Users can insert their own participant record
DROP POLICY IF EXISTS "Users can join public tasks" ON public.public_task_participants;
CREATE POLICY "Users can join public tasks"
  ON public.public_task_participants FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own participant record
DROP POLICY IF EXISTS "Users can update their own public task participation" ON public.public_task_participants;
CREATE POLICY "Users can update their own public task participation"
  ON public.public_task_participants FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own participant record (leave task)
DROP POLICY IF EXISTS "Users can leave public tasks" ON public.public_task_participants;
CREATE POLICY "Users can leave public tasks"
  ON public.public_task_participants FOR DELETE
  USING (auth.uid() = user_id);

-- 7. RLS Policy for public tasks (anyone can view public tasks)
-- Drop existing policy if it exists
DROP POLICY IF EXISTS "Anyone can view public tasks" ON public.tasks;

CREATE POLICY "Anyone can view public tasks"
  ON public.tasks FOR SELECT
  USING (is_public = true OR user_id = auth.uid() OR 
         id IN (
           SELECT task_id FROM public.public_task_participants 
           WHERE user_id = auth.uid()
         ));

-- 8. Function to update public_join_count
DROP FUNCTION IF EXISTS update_public_task_join_count() CASCADE;
CREATE OR REPLACE FUNCTION update_public_task_join_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.tasks
    SET public_join_count = public_join_count + 1
    WHERE id = NEW.task_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.tasks
    SET public_join_count = GREATEST(public_join_count - 1, 0)
    WHERE id = OLD.task_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update join count
DROP TRIGGER IF EXISTS trigger_update_public_join_count ON public.public_task_participants;
CREATE TRIGGER trigger_update_public_join_count
  AFTER INSERT OR DELETE ON public.public_task_participants
  FOR EACH ROW
  EXECUTE FUNCTION update_public_task_join_count();

-- 9. Verify tables were created
SELECT 
  'Categories' as table_name,
  COUNT(*) as row_count
FROM public.categories
UNION ALL
SELECT 
  'Public Tasks' as table_name,
  COUNT(*) as row_count
FROM public.tasks
WHERE is_public = true
UNION ALL
SELECT 
  'Public Task Participants' as table_name,
  COUNT(*) as row_count
FROM public.public_task_participants;

