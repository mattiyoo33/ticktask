-- Fix RLS Policy for Users to View Their Own Participant Records
-- This is CRITICAL for pending invitations to work
-- The issue: Query finds 0 participants even though they exist in database
-- Root cause: RLS policy blocking users from viewing their own participant records
-- Run this in Supabase SQL Editor

-- Ensure RLS is enabled
ALTER TABLE public.task_participants ENABLE ROW LEVEL SECURITY;

-- Drop existing policy if it exists (to recreate it cleanly)
DROP POLICY IF EXISTS "Users can view task participants" ON public.task_participants;

-- Create/Recreate the policy that allows users to see their own participant records
-- This is essential for the pending invitations query to work
-- Users MUST be able to see their own records to check for pending invitations
CREATE POLICY "Users can view task participants"
  ON public.task_participants FOR SELECT
  USING (auth.uid() = user_id);

-- Verify the policy was created
SELECT 
  'RLS Policy Check' as check_type,
  policyname,
  CASE 
    WHEN policyname = 'Users can view task participants' THEN '✅ Policy exists'
    ELSE '❌ Policy not found'
  END as status,
  qual as policy_definition
FROM pg_policies 
WHERE tablename = 'task_participants' 
AND schemaname = 'public'
AND policyname = 'Users can view task participants';

-- Also check all task_participants policies
SELECT 
  'All Task Participants RLS Policies' as check_type,
  COUNT(*) as policy_count,
  CASE 
    WHEN COUNT(*) >= 3 THEN '✅ All required policies exist'
    ELSE '⚠️ Some policies missing'
  END as status,
  string_agg(policyname, ', ') as policies
FROM pg_policies 
WHERE tablename = 'task_participants' 
AND schemaname = 'public';

