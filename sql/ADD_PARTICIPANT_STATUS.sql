-- Add status field to task_participants to track invitation status
-- This allows tracking pending/accepted/refused collaboration invitations

-- Add status column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'task_participants' 
    AND column_name = 'status'
  ) THEN
    ALTER TABLE public.task_participants
    ADD COLUMN status TEXT CHECK (status IN ('pending', 'accepted', 'refused')) DEFAULT 'pending';
  END IF;
END $$;

-- Update existing participants to 'accepted' status (they were already added)
UPDATE public.task_participants
SET status = 'accepted'
WHERE status IS NULL OR status = 'pending';

-- Add index for faster queries on status
CREATE INDEX IF NOT EXISTS idx_task_participants_status 
ON public.task_participants(status);

-- Add index for user_id and status (for finding pending invitations)
CREATE INDEX IF NOT EXISTS idx_task_participants_user_status 
ON public.task_participants(user_id, status);

