-- ============================================
-- ADD TUTORIAL COMPLETION FIELD
-- ============================================
-- This adds a field to track if user has completed the tutorial

-- Add tutorial_completed column to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS tutorial_completed BOOLEAN DEFAULT FALSE;

-- Update existing users to have tutorial_completed = false (so they can see tutorial)
UPDATE public.profiles 
SET tutorial_completed = FALSE 
WHERE tutorial_completed IS NULL;

