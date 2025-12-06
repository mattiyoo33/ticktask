-- Fix Missing RLS Policy for Collaborative Tasks
-- This script adds the "Users can view collaborative tasks" policy if it's missing
-- Run this in Supabase SQL Editor if the verification script shows missing RLS policies

-- First, ensure RLS is enabled on tasks table
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

-- Drop the policy if it exists (to recreate it cleanly)
DROP POLICY IF EXISTS "Users can view collaborative tasks" ON public.tasks;

-- Create the collaborative tasks policy
-- This allows users to view tasks where they are participants
CREATE POLICY "Users can view collaborative tasks"
  ON public.tasks FOR SELECT
  USING (
    is_collaborative = true AND 
    id IN (
      SELECT task_id FROM public.task_participants tp
      WHERE tp.user_id = auth.uid()
    )
  );

-- Verify the policy was created
SELECT 
  'RLS Policy Check' as check_type,
  policyname,
  CASE 
    WHEN policyname = 'Users can view collaborative tasks' THEN '✅ Policy created successfully'
    ELSE '❌ Policy not found'
  END as status
FROM pg_policies 
WHERE tablename = 'tasks' 
AND schemaname = 'public'
AND policyname = 'Users can view collaborative tasks';

-- Also verify all required task policies exist
SELECT 
  'All Task RLS Policies' as check_type,
  COUNT(*) as policy_count,
  CASE 
    WHEN COUNT(*) >= 5 THEN '✅ All required policies exist'
    ELSE '⚠️ Some policies missing'
  END as status,
  string_agg(policyname, ', ') as policies
FROM pg_policies 
WHERE tablename = 'tasks' 
AND schemaname = 'public';

