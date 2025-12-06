-- Fix foreign key relationship for PostgREST nested queries
-- This allows PostgREST to understand the relationship between task_participants and profiles

-- Add foreign key from task_participants.user_id to profiles.id
-- This enables PostgREST to do nested queries like profiles:user_id
DO $$
BEGIN
  -- Check if foreign key already exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_schema = 'public' 
    AND table_name = 'task_participants' 
    AND constraint_name = 'task_participants_user_id_profiles_fkey'
  ) THEN
    -- Add foreign key constraint
    ALTER TABLE public.task_participants
    ADD CONSTRAINT task_participants_user_id_profiles_fkey
    FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Do the same for task_comments
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_schema = 'public' 
    AND table_name = 'task_comments' 
    AND constraint_name = 'task_comments_user_id_profiles_fkey'
  ) THEN
    ALTER TABLE public.task_comments
    ADD CONSTRAINT task_comments_user_id_profiles_fkey
    FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
  END IF;
END $$;

