-- Fix foreign key relationship for PostgREST nested queries
-- This allows PostgREST to understand the relationship between friendships and profiles

-- Add foreign key from friendships.user_id to profiles.id
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_schema = 'public' 
    AND table_name = 'friendships' 
    AND constraint_name = 'friendships_user_id_profiles_fkey'
  ) THEN
    ALTER TABLE public.friendships
    ADD CONSTRAINT friendships_user_id_profiles_fkey
    FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Add foreign key from friendships.friend_id to profiles.id
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_schema = 'public' 
    AND table_name = 'friendships' 
    AND constraint_name = 'friendships_friend_id_profiles_fkey'
  ) THEN
    ALTER TABLE public.friendships
    ADD CONSTRAINT friendships_friend_id_profiles_fkey
    FOREIGN KEY (friend_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Add foreign key from friendships.requested_by to profiles.id (if column exists)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'friendships' 
    AND column_name = 'requested_by'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_schema = 'public' 
    AND table_name = 'friendships' 
    AND constraint_name = 'friendships_requested_by_profiles_fkey'
  ) THEN
    ALTER TABLE public.friendships
    ADD CONSTRAINT friendships_requested_by_profiles_fkey
    FOREIGN KEY (requested_by) REFERENCES public.profiles(id) ON DELETE CASCADE;
  END IF;
END $$;

