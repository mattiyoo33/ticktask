-- Add recurrence_days column to tasks table for custom frequency
-- Run this in Supabase SQL Editor

-- Add recurrence_days column (stored as JSON array of day names)
ALTER TABLE public.tasks
ADD COLUMN IF NOT EXISTS recurrence_days JSONB DEFAULT NULL;

-- Create index for potential queries
CREATE INDEX IF NOT EXISTS idx_tasks_recurrence_days ON public.tasks USING GIN (recurrence_days);

-- Verify the column was added
SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'tasks'
  AND column_name = 'recurrence_days';
