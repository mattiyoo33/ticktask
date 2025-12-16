-- ============================================
-- CREATE PUBLIC PLAN PARTICIPANTS TABLE
-- ============================================
-- Run this file in Supabase SQL Editor
-- This creates the public_plan_participants table for users to join/leave public plans

-- ============================================
-- 1. CREATE PUBLIC_PLAN_PARTICIPANTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.public_plan_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES public.plans(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  contribution INTEGER DEFAULT 0, -- Percentage of contribution (for future use)
  completed_count INTEGER DEFAULT 0, -- Number of tasks completed in this plan
  UNIQUE(plan_id, user_id)
);

-- Create indexes for public_plan_participants
CREATE INDEX IF NOT EXISTS idx_public_plan_participants_plan ON public.public_plan_participants(plan_id);
CREATE INDEX IF NOT EXISTS idx_public_plan_participants_user ON public.public_plan_participants(user_id);

-- ============================================
-- 2. ENABLE RLS ON PUBLIC_PLAN_PARTICIPANTS
-- ============================================
ALTER TABLE public.public_plan_participants ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 3. RLS POLICIES FOR PUBLIC_PLAN_PARTICIPANTS
-- ============================================

-- Anyone can view all public plan participants
DROP POLICY IF EXISTS "Anyone can view public plan participants" ON public.public_plan_participants;
CREATE POLICY "Anyone can view public plan participants"
  ON public.public_plan_participants FOR SELECT
  USING (true);

-- Users can insert their own participant record (join)
DROP POLICY IF EXISTS "Users can join public plans" ON public.public_plan_participants;
CREATE POLICY "Users can join public plans"
  ON public.public_plan_participants FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own participant record
DROP POLICY IF EXISTS "Users can update their own public plan participation" ON public.public_plan_participants;
CREATE POLICY "Users can update their own public plan participation"
  ON public.public_plan_participants FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own participant record (leave plan)
DROP POLICY IF EXISTS "Users can leave public plans" ON public.public_plan_participants;
CREATE POLICY "Users can leave public plans"
  ON public.public_plan_participants FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- 4. FUNCTION TO UPDATE PUBLIC JOIN COUNT (if needed)
-- ============================================
-- Note: This is optional - you may want to add a public_join_count column to plans table
-- similar to how tasks have public_join_count

-- Add public_join_count column to plans table if it doesn't exist
ALTER TABLE public.plans
ADD COLUMN IF NOT EXISTS public_join_count INTEGER DEFAULT 0;

-- Create function to update public_join_count
DROP FUNCTION IF EXISTS update_public_plan_join_count() CASCADE;
CREATE OR REPLACE FUNCTION update_public_plan_join_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.plans
    SET public_join_count = public_join_count + 1
    WHERE id = NEW.plan_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.plans
    SET public_join_count = GREATEST(public_join_count - 1, 0)
    WHERE id = OLD.plan_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update join count
DROP TRIGGER IF EXISTS trigger_update_public_plan_join_count ON public.public_plan_participants;
CREATE TRIGGER trigger_update_public_plan_join_count
  AFTER INSERT OR DELETE ON public.public_plan_participants
  FOR EACH ROW
  EXECUTE FUNCTION update_public_plan_join_count();

-- ============================================
-- 5. VERIFY TABLE WAS CREATED
-- ============================================
SELECT 
  'Public Plan Participants' as table_name,
  COUNT(*) as row_count
FROM public.public_plan_participants;
