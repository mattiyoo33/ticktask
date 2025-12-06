-- Update RLS policies to allow task participants to access comments
-- Run this in Supabase SQL Editor

-- Drop existing comment policies
DROP POLICY IF EXISTS "Users can view task comments" ON public.task_comments;
DROP POLICY IF EXISTS "Users can create task comments" ON public.task_comments;

-- Updated policy: Users can view comments if they own the task, 
-- OR if the task is collaborative, OR if they are a participant
CREATE POLICY "Users can view task comments"
  ON public.task_comments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.tasks 
      WHERE tasks.id = task_comments.task_id 
      AND (
        tasks.user_id = auth.uid() 
        OR tasks.is_collaborative = true
        OR EXISTS (
          SELECT 1 FROM public.task_participants tp
          WHERE tp.task_id = tasks.id
          AND tp.user_id = auth.uid()
        )
      )
    )
  );

-- Updated policy: Users can create comments if they own the task,
-- OR if the task is collaborative, OR if they are a participant
CREATE POLICY "Users can create task comments"
  ON public.task_comments FOR INSERT
  WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM public.tasks 
      WHERE tasks.id = task_comments.task_id 
      AND (
        tasks.user_id = auth.uid() 
        OR tasks.is_collaborative = true
        OR EXISTS (
          SELECT 1 FROM public.task_participants tp
          WHERE tp.task_id = tasks.id
          AND tp.user_id = auth.uid()
        )
      )
    )
  );

