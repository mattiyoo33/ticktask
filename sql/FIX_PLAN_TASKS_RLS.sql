-- Fix RLS Policy for Tasks in Public Plans
-- This allows users who have joined a public plan to view tasks in that plan
-- Run this in Supabase SQL Editor

-- Drop existing policy if it exists
DROP POLICY IF EXISTS "Users can view tasks in public plans they joined" ON public.tasks;

-- Create policy to allow viewing tasks in public plans that user has joined
CREATE POLICY "Users can view tasks in public plans they joined"
  ON public.tasks FOR SELECT
  USING (
    -- Allow if user owns the task
    user_id = auth.uid()
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
    -- Allow if user is viewing their own plan's tasks
    (
      plan_id IS NOT NULL
      AND plan_id IN (
        SELECT id 
        FROM public.plans 
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
  AND policyname = 'Users can view tasks in public plans they joined';
