-- Fix Infinite Recursion in Tasks Policy
-- Run this in Supabase SQL Editor

-- Step 1: Create a SECURITY DEFINER function to check task ownership
-- This bypasses RLS and avoids recursion
CREATE OR REPLACE FUNCTION public.user_owns_task(p_task_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.tasks
    WHERE id = p_task_id AND user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 2: Drop ALL problematic policies
DROP POLICY IF EXISTS "Users can view collaborative tasks" ON public.tasks;
DROP POLICY IF EXISTS "Users can view task participants" ON public.task_participants;
DROP POLICY IF EXISTS "Task owners can view participants" ON public.task_participants;
DROP POLICY IF EXISTS "Users can join tasks" ON public.task_participants;

-- Step 3: Recreate task_participants policies (no circular dependency)
-- Policy 1: Users can see themselves as participants
CREATE POLICY "Users can view task participants"
  ON public.task_participants FOR SELECT
  USING (auth.uid() = user_id);

-- Policy 2: Task owners can see all participants (uses function to avoid recursion)
CREATE POLICY "Task owners can view participants"
  ON public.task_participants FOR SELECT
  USING (public.user_owns_task(task_id));

-- Policy 3: Users can join tasks
CREATE POLICY "Users can join tasks"
  ON public.task_participants FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Step 4: Recreate collaborative tasks policy (simple IN query)
CREATE POLICY "Users can view collaborative tasks"
  ON public.tasks FOR SELECT
  USING (
    is_collaborative = true AND 
    id IN (
      SELECT task_id FROM public.task_participants tp
      WHERE tp.user_id = auth.uid()
    )
  );
