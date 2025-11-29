-- Fix missing XP columns in profiles table
-- Run this if you get "column current_xp does not exist" error

-- Add missing columns if they don't exist
DO $$ 
BEGIN
  -- Add current_xp column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'profiles' 
    AND column_name = 'current_xp'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN current_xp INTEGER DEFAULT 0;
  END IF;

  -- Add total_xp column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'profiles' 
    AND column_name = 'total_xp'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN total_xp INTEGER DEFAULT 0;
  END IF;

  -- Add level column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'profiles' 
    AND column_name = 'level'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN level INTEGER DEFAULT 1;
  END IF;
END $$;

-- Update existing rows to have default values
UPDATE public.profiles 
SET 
  current_xp = COALESCE(current_xp, 0),
  total_xp = COALESCE(total_xp, 0),
  level = COALESCE(level, 1)
WHERE current_xp IS NULL OR total_xp IS NULL OR level IS NULL;

