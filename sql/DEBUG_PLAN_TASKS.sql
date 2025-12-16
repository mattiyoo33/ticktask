-- Debug script to check tasks in plans
-- Run this in Supabase SQL Editor to verify tasks exist and RLS is working

-- Replace 'YOUR_PLAN_ID' with an actual plan ID from your plans table
-- Replace 'YOUR_USER_ID' with your user ID (from auth.users)

-- 1. Check if plan exists
SELECT 
  id,
  title,
  user_id as plan_owner_id,
  is_public,
  created_at
FROM public.plans
WHERE id = 'YOUR_PLAN_ID'; -- Replace with actual plan ID

-- 2. Check tasks in the plan (without RLS - run as service role)
SELECT 
  id,
  title,
  user_id as task_owner_id,
  plan_id,
  status,
  created_at
FROM public.tasks
WHERE plan_id = 'YOUR_PLAN_ID'; -- Replace with actual plan ID
ORDER BY task_order, due_time;

-- 3. Check if user has joined the plan (if it's public)
SELECT 
  ppp.id,
  ppp.plan_id,
  ppp.user_id,
  ppp.joined_at
FROM public.public_plan_participants ppp
WHERE ppp.plan_id = 'YOUR_PLAN_ID' -- Replace with actual plan ID
  AND ppp.user_id = 'YOUR_USER_ID'; -- Replace with your user ID

-- 4. Test RLS policy - this simulates what the app query does
-- This should return tasks if RLS allows it
-- Note: This query runs with your current user's permissions
SELECT 
  t.id,
  t.title,
  t.user_id as task_owner_id,
  t.plan_id,
  t.status,
  p.user_id as plan_owner_id,
  p.is_public as plan_is_public
FROM public.tasks t
LEFT JOIN public.plans p ON t.plan_id = p.id
WHERE t.plan_id = 'YOUR_PLAN_ID' -- Replace with actual plan ID
ORDER BY t.task_order, t.due_time;

-- 5. Check RLS policies on tasks table
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
ORDER BY policyname;
