-- Add category_id column to plans table for public plans
-- Run this in Supabase SQL Editor

-- Add category_id column to plans table
ALTER TABLE public.plans
ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES public.categories(id);

-- Create index for category lookups
CREATE INDEX IF NOT EXISTS idx_plans_category ON public.plans(category_id);

-- Verify the column was added
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'plans'
  AND column_name = 'category_id';
