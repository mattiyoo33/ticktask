-- Verify and Fix RLS Policy for Tasks in Plans
-- This ensures users can view tasks in their own plans and public plans they've joined
-- Run this in Supabase SQL Editor

-- First, check existing policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'tasks'
ORDER BY policyname;

-- Drop the existing policy if it exists
DROP POLICY IF EXISTS "Users can view tasks in public plans they joined" ON public.tasks;

-- Create a comprehensive policy that allows:
-- 1. Users to view their own tasks
-- 2. Users to view tasks in plans they own
-- 3. Users to view tasks in public plans they've joined
CREATE POLICY "Users can view tasks in plans"
  ON public.tasks FOR SELECT
  USING (
    -- Allow if user owns the task
    user_id = auth.uid()
    OR
    -- Allow if task is in a plan owned by the user
    (
      plan_id IS NOT NULL
      AND plan_id IN (
        SELECT id 
        FROM public.plans 
        WHERE user_id = auth.uid()
      )
    )
    OR
    -- Allow if task is in a public plan that user has joined
    (
      plan_id IS NOT NULL
      AND plan_id IN (
        SELECT plan_id 
        FROM public.public_plan_participants 
        WHERE user_id = auth.uid()
      )
      AND EXISTS (
        SELECT 1 
        FROM public.plans 
        WHERE id = plan_id 
        AND is_public = true
      )
    )
    OR
    -- Allow if task is collaborative and user is a participant
    (
      is_collaborative = true
      AND id IN (
        SELECT task_id 
        FROM public.task_participants 
        WHERE user_id = auth.uid() 
        AND status = 'accepted'
      )
    )
    OR
    -- Allow if task is public and user has joined
    (
      is_public = true
      AND id IN (
        SELECT task_id 
        FROM public.public_task_participants 
        WHERE user_id = auth.uid()
      )
    )
  );

-- Verify the policy was created
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'tasks'
  AND policyname = 'Users can view tasks in plans';
