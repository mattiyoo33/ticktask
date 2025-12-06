-- Fix RLS Policy for Users to UPDATE Their Own Participant Status
-- This is CRITICAL for accept/refuse invitation to work
-- The issue: Users cannot update their own participant status from 'pending' to 'accepted' or 'refused'
-- Root cause: Missing UPDATE policy on task_participants table
-- Run this in Supabase SQL Editor

-- Ensure RLS is enabled
ALTER TABLE public.task_participants ENABLE ROW LEVEL SECURITY;

-- Drop existing UPDATE policy if it exists (to recreate it cleanly)
DROP POLICY IF EXISTS "Users can update their own participant status" ON public.task_participants;

-- Create/Recreate the policy that allows users to update their own participant records
-- This is essential for the accept/refuse invitation functionality to work
-- Users MUST be able to update their own status from 'pending' to 'accepted' or 'refused'
CREATE POLICY "Users can update their own participant status"
  ON public.task_participants FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Verify the policy was created
SELECT
  'RLS Policy Check' as check_type,
  policyname,
  CASE
    WHEN policyname = 'Users can update their own participant status' THEN '✅ Policy exists'
    ELSE '❌ Policy not found'
  END as status,
  cmd as policy_command,
  qual as using_clause,
  with_check as with_check_clause
FROM pg_policies
WHERE tablename = 'task_participants'
AND schemaname = 'public'
AND policyname = 'Users can update their own participant status';

-- Also check all task_participants policies
SELECT
  'All Task Participants RLS Policies' as check_type,
  COUNT(*) as policy_count,
  CASE
    WHEN COUNT(*) >= 4 THEN '✅ All required policies exist'
    ELSE '⚠️ Some policies missing'
  END as status,
  string_agg(policyname, ', ') as policies
FROM pg_policies
WHERE tablename = 'task_participants'
AND schemaname = 'public';

