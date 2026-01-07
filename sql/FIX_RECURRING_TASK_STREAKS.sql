-- Fix recurring task streak calculation to properly handle daily, weekly, and custom frequencies
-- This updates the update_task_streak function to calculate streaks based on task frequency

CREATE OR REPLACE FUNCTION public.update_task_streak(p_task_id UUID, p_user_id UUID)
RETURNS void AS $$
DECLARE
  v_current_streak INTEGER := 0;
  v_max_streak INTEGER := 0;
  v_last_completed TIMESTAMP WITH TIME ZONE;
  v_week_progress BOOLEAN[];
  v_day_of_week INTEGER;
  v_has_completion BOOLEAN;
  v_task_frequency TEXT;
  v_recurrence_days JSONB;
  v_completion_dates DATE[];
  v_expected_date DATE;
  v_streak_count INTEGER := 0;
  v_temp_streak INTEGER := 0;
  v_prev_date DATE;
  v_date DATE;
  v_day_map JSONB := '{"Mon": 1, "Tue": 2, "Wed": 3, "Thu": 4, "Fri": 5, "Sat": 6, "Sun": 7}'::JSONB;
  v_selected_days INTEGER[];
  v_day_name TEXT;
  v_weekday INTEGER;
BEGIN
  -- Get task frequency and recurrence days
  SELECT recurrence_frequency, recurrence_days
  INTO v_task_frequency, v_recurrence_days
  FROM public.tasks
  WHERE id = p_task_id AND is_recurring = true;

  -- Get all completion dates for this task, ordered by date descending
  SELECT ARRAY_AGG(DISTINCT DATE(completed_at) ORDER BY DATE(completed_at) DESC)
  INTO v_completion_dates
  FROM public.task_completions
  WHERE task_id = p_task_id AND user_id = p_user_id;

  -- Get last completed date
  SELECT MAX(completed_at)
  INTO v_last_completed
  FROM public.task_completions
  WHERE task_id = p_task_id AND user_id = p_user_id;

  -- Calculate streak based on frequency
  IF v_task_frequency = 'Daily' THEN
    -- For daily tasks: count consecutive days from today backwards
    v_expected_date := CURRENT_DATE;
    IF v_completion_dates IS NOT NULL AND array_length(v_completion_dates, 1) > 0 THEN
      FOREACH v_date IN ARRAY v_completion_dates
      LOOP
        IF v_date = v_expected_date OR v_date = v_expected_date - INTERVAL '1 day' THEN
          -- Today or yesterday - continue streak
          IF v_date = v_expected_date THEN
            v_streak_count := v_streak_count + 1;
            v_expected_date := v_expected_date - INTERVAL '1 day';
          ELSE
            -- Yesterday - continue streak
            v_streak_count := v_streak_count + 1;
            v_expected_date := v_date - INTERVAL '1 day';
          END IF;
        ELSE
          -- Gap found - streak ends
          EXIT;
        END IF;
      END LOOP;
    END IF;
    v_current_streak := v_streak_count;

  ELSIF v_task_frequency = 'Weekly' THEN
    -- For weekly tasks: count consecutive weeks
    IF v_completion_dates IS NOT NULL AND array_length(v_completion_dates, 1) > 0 THEN
      -- Group completions by week (ISO week)
      v_expected_date := DATE_TRUNC('week', CURRENT_DATE)::DATE;
      v_streak_count := 0;
      
      FOREACH v_date IN ARRAY v_completion_dates
      LOOP
        DECLARE
          v_completion_week DATE := DATE_TRUNC('week', v_date)::DATE;
          v_expected_week DATE;
        BEGIN
          IF v_streak_count = 0 THEN
            -- First completion - check if it's this week or last week
            v_expected_week := DATE_TRUNC('week', CURRENT_DATE)::DATE;
            IF v_completion_week = v_expected_week OR v_completion_week = v_expected_week - INTERVAL '7 days' THEN
              v_streak_count := 1;
              v_expected_date := v_expected_week - INTERVAL '7 days';
            ELSE
              EXIT; -- Not this week or last week, no streak
            END IF;
          ELSE
            -- Check if this completion is in the expected week
            v_expected_week := v_expected_date;
            IF v_completion_week = v_expected_week THEN
              v_streak_count := v_streak_count + 1;
              v_expected_date := v_expected_date - INTERVAL '7 days';
            ELSE
              -- Gap found - streak ends
              EXIT;
            END IF;
          END IF;
        END;
      END LOOP;
    END IF;
    v_current_streak := v_streak_count;

  ELSIF v_task_frequency = 'Custom' AND v_recurrence_days IS NOT NULL THEN
    -- For custom frequency: count consecutive occurrence days
    -- Build array of selected weekday numbers
    v_selected_days := ARRAY[]::INTEGER[];
    FOR v_day_name IN SELECT jsonb_array_elements_text(v_recurrence_days)
    LOOP
      v_weekday := (v_day_map->>v_day_name)::INTEGER;
      IF v_weekday IS NOT NULL THEN
        v_selected_days := array_append(v_selected_days, v_weekday);
      END IF;
    END LOOP;

    IF array_length(v_selected_days, 1) > 0 AND v_completion_dates IS NOT NULL AND array_length(v_completion_dates, 1) > 0 THEN
      -- Find the most recent occurrence day that should have been completed
      v_expected_date := CURRENT_DATE;
      -- Go back to find the most recent occurrence day
      WHILE NOT (EXTRACT(DOW FROM v_expected_date)::INTEGER = ANY(v_selected_days)) LOOP
        v_expected_date := v_expected_date - INTERVAL '1 day';
        -- Safety check to prevent infinite loop
        IF v_expected_date < CURRENT_DATE - INTERVAL '14 days' THEN
          EXIT;
        END IF;
      END LOOP;

      -- Count consecutive occurrence days
      FOREACH v_date IN ARRAY v_completion_dates
      LOOP
        DECLARE
          v_date_weekday INTEGER := EXTRACT(DOW FROM v_date)::INTEGER;
        BEGIN
          IF v_date_weekday = ANY(v_selected_days) THEN
            -- This is a valid occurrence day
            IF v_date = v_expected_date OR (v_streak_count > 0 AND v_date <= v_expected_date + INTERVAL '7 days') THEN
              -- Check if this is the expected occurrence or within a week
              IF v_date = v_expected_date THEN
                v_streak_count := v_streak_count + 1;
                -- Find previous occurrence day
                v_expected_date := v_expected_date - INTERVAL '1 day';
                WHILE NOT (EXTRACT(DOW FROM v_expected_date)::INTEGER = ANY(v_selected_days)) LOOP
                  v_expected_date := v_expected_date - INTERVAL '1 day';
                  IF v_expected_date < CURRENT_DATE - INTERVAL '30 days' THEN
                    EXIT;
                  END IF;
                END LOOP;
              ELSE
                -- Gap found - streak ends
                EXIT;
              END IF;
            ELSE
              -- Too far in the past or future
              EXIT;
            END IF;
          END IF;
        END;
      END LOOP;
    END IF;
    v_current_streak := v_streak_count;

  ELSE
    -- For non-recurring or unknown frequency: use daily calculation as fallback
    v_expected_date := CURRENT_DATE;
    IF v_completion_dates IS NOT NULL AND array_length(v_completion_dates, 1) > 0 THEN
      FOREACH v_date IN ARRAY v_completion_dates
      LOOP
        IF v_date = v_expected_date OR v_date = v_expected_date - INTERVAL '1 day' THEN
          IF v_date = v_expected_date THEN
            v_streak_count := v_streak_count + 1;
            v_expected_date := v_expected_date - INTERVAL '1 day';
          ELSE
            v_streak_count := v_streak_count + 1;
            v_expected_date := v_date - INTERVAL '1 day';
          END IF;
        ELSE
          EXIT;
        END IF;
      END LOOP;
    END IF;
    v_current_streak := v_streak_count;
  END IF;

  -- Calculate max streak (longest consecutive streak ever)
  IF v_completion_dates IS NOT NULL AND array_length(v_completion_dates, 1) > 0 THEN
    v_temp_streak := 1;
    v_prev_date := NULL;
    
    FOREACH v_date IN ARRAY v_completion_dates
    LOOP
      IF v_prev_date IS NOT NULL THEN
        DECLARE
          v_days_diff INTEGER;
        BEGIN
          IF v_task_frequency = 'Daily' THEN
            v_days_diff := v_prev_date - v_date;
            IF v_days_diff = 1 THEN
              v_temp_streak := v_temp_streak + 1;
            ELSE
              v_max_streak := GREATEST(v_max_streak, v_temp_streak);
              v_temp_streak := 1;
            END IF;
          ELSIF v_task_frequency = 'Weekly' THEN
            v_days_diff := v_prev_date - v_date;
            IF v_days_diff >= 7 AND v_days_diff <= 14 THEN
              -- Check if they're in consecutive weeks
              DECLARE
                v_prev_week DATE := DATE_TRUNC('week', v_prev_date)::DATE;
                v_curr_week DATE := DATE_TRUNC('week', v_date)::DATE;
              BEGIN
                IF v_prev_week - v_curr_week = INTERVAL '7 days' THEN
                  v_temp_streak := v_temp_streak + 1;
                ELSE
                  v_max_streak := GREATEST(v_max_streak, v_temp_streak);
                  v_temp_streak := 1;
                END IF;
              END;
            ELSE
              v_max_streak := GREATEST(v_max_streak, v_temp_streak);
              v_temp_streak := 1;
            END IF;
          ELSE
            -- For custom or unknown, use daily logic
            v_days_diff := v_prev_date - v_date;
            IF v_days_diff = 1 THEN
              v_temp_streak := v_temp_streak + 1;
            ELSE
              v_max_streak := GREATEST(v_max_streak, v_temp_streak);
              v_temp_streak := 1;
            END IF;
          END IF;
        END;
      END IF;
      v_prev_date := v_date;
    END LOOP;
    v_max_streak := GREATEST(v_max_streak, v_temp_streak);
  END IF;

  -- Calculate week progress (last 7 days) - always show last 7 days regardless of frequency
  v_week_progress := ARRAY[false, false, false, false, false, false, false];
  FOR v_day_of_week IN 0..6 LOOP
    SELECT EXISTS (
      SELECT 1 FROM public.task_completions
      WHERE task_id = p_task_id 
        AND user_id = p_user_id
        AND DATE(completed_at) = CURRENT_DATE - (6 - v_day_of_week)
    ) INTO v_has_completion;
    
    v_week_progress[v_day_of_week + 1] := v_has_completion;
  END LOOP;

  -- Upsert streak data
  INSERT INTO public.task_streaks (
    task_id, user_id, current_streak, max_streak, 
    last_completed_at, week_progress, has_streak_bonus, updated_at
  )
  VALUES (
    p_task_id, p_user_id, v_current_streak, v_max_streak,
    v_last_completed, v_week_progress, (v_current_streak >= 7), NOW()
  )
  ON CONFLICT (task_id, user_id) DO UPDATE SET
    current_streak = EXCLUDED.current_streak,
    max_streak = GREATEST(task_streaks.max_streak, EXCLUDED.max_streak),
    last_completed_at = EXCLUDED.last_completed_at,
    week_progress = EXCLUDED.week_progress,
    has_streak_bonus = EXCLUDED.has_streak_bonus,
    updated_at = EXCLUDED.updated_at;
END;
$$ LANGUAGE plpgsql;

