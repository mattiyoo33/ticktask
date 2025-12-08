-- ============================================
-- ADD PUBLIC PLANS SUPPORT
-- ============================================
-- Run this file in Supabase SQL Editor
-- This adds is_public column to plans table and updates RLS policies

-- ============================================
-- 1. ADD IS_PUBLIC COLUMN TO PLANS TABLE
-- ============================================
ALTER TABLE public.plans
ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT false;

-- Create index for public plans
CREATE INDEX IF NOT EXISTS idx_plans_is_public ON public.plans(is_public);

-- ============================================
-- 2. UPDATE RLS POLICIES FOR PUBLIC PLANS
-- ============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own plans" ON public.plans;
DROP POLICY IF EXISTS "Anyone can view public plans" ON public.plans;

-- Users can view their own plans (private or public)
CREATE POLICY "Users can view own plans"
  ON public.plans FOR SELECT
  USING (auth.uid() = user_id);

-- Anyone can view public plans
CREATE POLICY "Anyone can view public plans"
  ON public.plans FOR SELECT
  USING (is_public = true);

-- ============================================
-- 3. UPDATE CREATE POLICY TO ALLOW IS_PUBLIC
-- ============================================
-- The existing "Users can create own plans" policy already allows users to create plans
-- with any data, including is_public, so no changes needed here.

