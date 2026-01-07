-- Fix streak calculation when task completion is deleted (reverted)
-- This adds a trigger to recalculate streaks when a completion is removed

-- Function to update streak when task completion is deleted
CREATE OR REPLACE FUNCTION public.on_task_completion_deleted()
RETURNS TRIGGER AS $$
BEGIN
  -- Recalculate streak after deletion
  -- This ensures streaks are updated when a completion is reverted
  PERFORM public.update_task_streak(OLD.task_id, OLD.user_id);
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update streak when task completion is deleted (AFTER DELETE)
DROP TRIGGER IF EXISTS trigger_task_completion_deleted ON public.task_completions;
CREATE TRIGGER trigger_task_completion_deleted
  AFTER DELETE ON public.task_completions
  FOR EACH ROW EXECUTE FUNCTION public.on_task_completion_deleted();

-- Note: The update_task_streak function already recalculates streaks based on
-- remaining completion records, so it will correctly reflect the deletion.

