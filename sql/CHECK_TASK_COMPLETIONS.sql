-- Diagnostic query to check task completions for a specific user and task
-- Replace 'TASK_ID_HERE' with the actual task ID
-- Replace 'USER_ID_HERE' with the actual user ID

-- Check all completions for a specific task today
SELECT 
  tc.id,
  tc.task_id,
  tc.user_id,
  tc.completed_at,
  tc.xp_gained,
  u.email as user_email,
  t.title as task_title,
  t.user_id as task_owner_id
FROM public.task_completions tc
JOIN auth.users u ON tc.user_id = u.id
JOIN public.tasks t ON tc.task_id = t.id
WHERE tc.task_id = 'TASK_ID_HERE'
  AND DATE(tc.completed_at) = CURRENT_DATE
ORDER BY tc.completed_at DESC;

-- Check if a specific user has completed a specific task today
SELECT 
  tc.id,
  tc.task_id,
  tc.user_id,
  tc.completed_at,
  tc.xp_gained,
  t.title as task_title
FROM public.task_completions tc
JOIN public.tasks t ON tc.task_id = t.id
WHERE tc.task_id = 'TASK_ID_HERE'
  AND tc.user_id = 'USER_ID_HERE'
  AND DATE(tc.completed_at) = CURRENT_DATE;

-- Check task status and owner
SELECT 
  id,
  title,
  user_id as task_owner_id,
  status,
  plan_id,
  is_public
FROM public.tasks
WHERE id = 'TASK_ID_HERE';
