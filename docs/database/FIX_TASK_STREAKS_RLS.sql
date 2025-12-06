-- Fix RLS Policy for task_streaks table
-- This allows the update_task_streak function to insert streak records

-- Drop existing policy if it exists
DROP POLICY IF EXISTS "Users can create own streaks" ON public.task_streaks;

-- Add INSERT policy for task_streaks
CREATE POLICY "Users can create own streaks"
  ON public.task_streaks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

