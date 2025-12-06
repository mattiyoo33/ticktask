-- Fix RLS policies for task_participants to allow task owners to add friends
-- Run this in Supabase SQL Editor

-- Ensure the helper function exists (creates if not exists, updates if exists)
CREATE OR REPLACE FUNCTION public.user_owns_task(p_task_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.tasks
    WHERE id = p_task_id AND user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing INSERT policies
DROP POLICY IF EXISTS "Users can join tasks" ON public.task_participants;
DROP POLICY IF EXISTS "Task owners can add participants" ON public.task_participants;

-- Policy 1: Users can insert themselves as participants (for joining tasks)
CREATE POLICY "Users can join tasks"
  ON public.task_participants FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy 2: Task owners can add any user as a participant (for adding friends)
-- This uses the helper function to check task ownership without RLS recursion
CREATE POLICY "Task owners can add participants"
  ON public.task_participants FOR INSERT
  WITH CHECK (public.user_owns_task(task_id));

-- Note: The SELECT policies remain unchanged:
-- - "Users can view task participants" - users can see themselves
-- - "Task owners can view participants" - owners can see all participants

