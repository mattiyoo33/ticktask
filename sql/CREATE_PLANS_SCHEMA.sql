-- ============================================
-- PLANS SCHEMA FOR TICKTASK APP
-- ============================================
-- Run this file in Supabase SQL Editor
-- This creates the plans table and updates tasks table to support plans

-- ============================================
-- 1. PLANS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.plans (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  plan_date DATE, -- Specific date for the plan (e.g., "2025-01-15")
  start_time TEXT, -- Optional start time (e.g., "08:00")
  end_time TEXT, -- Optional end time (e.g., "22:00")
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.plans ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own plans" ON public.plans;
DROP POLICY IF EXISTS "Users can create own plans" ON public.plans;
DROP POLICY IF EXISTS "Users can update own plans" ON public.plans;
DROP POLICY IF EXISTS "Users can delete own plans" ON public.plans;

-- Policies for plans
CREATE POLICY "Users can view own plans"
  ON public.plans FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own plans"
  ON public.plans FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own plans"
  ON public.plans FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own plans"
  ON public.plans FOR DELETE
  USING (auth.uid() = user_id);

-- Indexes for plans
CREATE INDEX IF NOT EXISTS idx_plans_user_id ON public.plans(user_id);
CREATE INDEX IF NOT EXISTS idx_plans_plan_date ON public.plans(plan_date);
CREATE INDEX IF NOT EXISTS idx_plans_created_at ON public.plans(created_at);

-- ============================================
-- 2. ADD PLAN_ID COLUMN TO TASKS TABLE
-- ============================================
ALTER TABLE public.tasks
ADD COLUMN IF NOT EXISTS plan_id UUID REFERENCES public.plans(id) ON DELETE SET NULL;

-- Create index for plan_id
CREATE INDEX IF NOT EXISTS idx_tasks_plan_id ON public.tasks(plan_id);

-- ============================================
-- 3. ADD TASK ORDER COLUMN TO TASKS TABLE
-- ============================================
-- This allows tasks within a plan to be ordered
ALTER TABLE public.tasks
ADD COLUMN IF NOT EXISTS task_order INTEGER DEFAULT 0;

-- Create index for task_order within plans
CREATE INDEX IF NOT EXISTS idx_tasks_plan_order ON public.tasks(plan_id, task_order);

