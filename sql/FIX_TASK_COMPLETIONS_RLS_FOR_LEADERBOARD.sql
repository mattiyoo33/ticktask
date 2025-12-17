-- Fix RLS Policy for Task Completions to allow leaderboard viewing
-- This allows users to view completion data (XP) for public tasks and plans they've joined
-- Run this in Supabase SQL Editor

-- Drop existing policy if it exists
DROP POLICY IF EXISTS "Users can view completions for public tasks and plans" ON public.task_completions;

-- Create policy to allow viewing completions for:
-- 1. Own completions (existing)
-- 2. Completions for public tasks user has joined
-- 3. Completions for tasks in public plans user has joined
CREATE POLICY "Users can view completions for public tasks and plans"
  ON public.task_completions FOR SELECT
  USING (
    -- Allow if user owns the completion
    user_id = auth.uid()
    OR
    -- Allow if task is public and user has joined
    (
      task_id IN (
        SELECT id 
        FROM public.tasks 
        WHERE is_public = true
      )
      AND task_id IN (
        SELECT task_id 
        FROM public.public_task_participants 
        WHERE user_id = auth.uid()
      )
    )
    OR
    -- Allow if task is in a public plan that user has joined
    (
      task_id IN (
        SELECT id 
        FROM public.tasks 
        WHERE plan_id IS NOT NULL
      )
      AND task_id IN (
        SELECT t.id 
        FROM public.tasks t
        INNER JOIN public.plans p ON t.plan_id = p.id
        WHERE p.is_public = true
        AND p.id IN (
          SELECT plan_id 
          FROM public.public_plan_participants 
          WHERE user_id = auth.uid()
        )
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
WHERE tablename = 'task_completions'
  AND policyname = 'Users can view completions for public tasks and plans';
