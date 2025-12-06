-- Fix RLS Policy for Users to DELETE Their Own Participant Records
-- This is CRITICAL for "leave task" functionality to work
-- The issue: Users cannot delete their own participant records to leave a task
-- Root cause: Missing DELETE policy on task_participants table
-- Run this in Supabase SQL Editor

-- Ensure RLS is enabled
ALTER TABLE public.task_participants ENABLE ROW LEVEL SECURITY;

-- Drop existing DELETE policy if it exists (to recreate it cleanly)
DROP POLICY IF EXISTS "Users can delete their own participant records" ON public.task_participants;

-- Create/Recreate the policy that allows users to delete their own participant records
-- This is essential for the "leave task" functionality to work
-- Users MUST be able to delete their own records to leave a collaborative task
CREATE POLICY "Users can delete their own participant records"
  ON public.task_participants FOR DELETE
  USING (auth.uid() = user_id);

-- Verify the policy was created
SELECT
  'RLS Policy Check' as check_type,
  policyname,
  CASE
    WHEN policyname = 'Users can delete their own participant records' THEN '✅ Policy exists'
    ELSE '❌ Policy not found'
  END as status,
  cmd as policy_command,
  qual as using_clause
FROM pg_policies
WHERE tablename = 'task_participants'
AND schemaname = 'public'
AND policyname = 'Users can delete their own participant records';

-- Also check all task_participants policies
SELECT
  'All Task Participants RLS Policies' as check_type,
  COUNT(*) as policy_count,
  CASE
    WHEN COUNT(*) >= 5 THEN '✅ All required policies exist'
    ELSE '⚠️ Some policies missing'
  END as status,
  string_agg(policyname, ', ') as policies
FROM pg_policies
WHERE tablename = 'task_participants'
AND schemaname = 'public';

