-- ============================================
-- COMPLETE DATABASE SCHEMA FOR TICKTASK APP
-- ============================================
-- Run this entire file in Supabase SQL Editor
-- This creates all tables needed for the app

-- ============================================
-- 1. PROFILES TABLE (Enhanced)
-- ============================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  full_name TEXT,
  avatar_url TEXT,
  level INTEGER DEFAULT 1,
  current_xp INTEGER DEFAULT 0,
  total_xp INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can view other profiles" ON public.profiles;

-- Policies for profiles
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can view other profiles"
  ON public.profiles FOR SELECT
  USING (true); -- Allow viewing other users' profiles for leaderboard/friends

-- ============================================
-- 2. TASKS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.tasks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT, -- Work, Health, Learning, Personal, etc.
  difficulty TEXT CHECK (difficulty IN ('Easy', 'Medium', 'Hard', 'easy', 'medium', 'hard')) DEFAULT 'Medium',
  status TEXT CHECK (status IN ('active', 'completed', 'overdue', 'scheduled', 'cancelled')) DEFAULT 'active',
  due_date TIMESTAMP WITH TIME ZONE,
  due_time TEXT, -- e.g., "8:00 AM"
  xp_reward INTEGER DEFAULT 10,
  is_recurring BOOLEAN DEFAULT false,
  recurrence_frequency TEXT, -- Daily, Weekly, Monthly
  recurrence_interval INTEGER DEFAULT 1, -- Every N days/weeks/months
  next_occurrence TIMESTAMP WITH TIME ZONE,
  is_collaborative BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE
);

-- Enable RLS
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own tasks" ON public.tasks;
DROP POLICY IF EXISTS "Users can create own tasks" ON public.tasks;
DROP POLICY IF EXISTS "Users can update own tasks" ON public.tasks;
DROP POLICY IF EXISTS "Users can delete own tasks" ON public.tasks;
DROP POLICY IF EXISTS "Users can view collaborative tasks" ON public.tasks;

-- Basic policies for tasks (without collaborative reference)
CREATE POLICY "Users can view own tasks"
  ON public.tasks FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own tasks"
  ON public.tasks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own tasks"
  ON public.tasks FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own tasks"
  ON public.tasks FOR DELETE
  USING (auth.uid() = user_id);

-- Indexes for tasks
CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON public.tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON public.tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON public.tasks(due_date);
CREATE INDEX IF NOT EXISTS idx_tasks_category ON public.tasks(category);

-- ============================================
-- 3. TASK PARTICIPANTS (for collaborative tasks)
-- ============================================
CREATE TABLE IF NOT EXISTS public.task_participants (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id UUID REFERENCES public.tasks(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role TEXT CHECK (role IN ('owner', 'participant')) DEFAULT 'participant',
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(task_id, user_id)
);

-- Enable RLS
ALTER TABLE public.task_participants ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view task participants" ON public.task_participants;
DROP POLICY IF EXISTS "Task owners can view participants" ON public.task_participants;
DROP POLICY IF EXISTS "Users can join tasks" ON public.task_participants;
DROP POLICY IF EXISTS "Users can leave tasks" ON public.task_participants;

-- Create helper function to check task ownership (avoids RLS recursion)
CREATE OR REPLACE FUNCTION public.user_owns_task(p_task_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.tasks
    WHERE id = p_task_id AND user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Policies (using helper function to avoid recursion)
-- Policy 1: Users can see themselves as participants
CREATE POLICY "Users can view task participants"
  ON public.task_participants FOR SELECT
  USING (auth.uid() = user_id);

-- Policy 2: Task owners can see all participants (uses function to avoid recursion)
CREATE POLICY "Task owners can view participants"
  ON public.task_participants FOR SELECT
  USING (public.user_owns_task(task_id));

CREATE POLICY "Users can join tasks"
  ON public.task_participants FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    -- Note: Task must be collaborative, but we check this at application level
    -- to avoid circular policy dependency
  );

CREATE POLICY "Users can leave tasks"
  ON public.task_participants FOR DELETE
  USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_task_participants_task_id ON public.task_participants(task_id);
CREATE INDEX IF NOT EXISTS idx_task_participants_user_id ON public.task_participants(user_id);

-- Now create the collaborative tasks policy (after task_participants table exists)
-- Use a simple IN subquery to avoid policy recursion
CREATE POLICY "Users can view collaborative tasks"
  ON public.tasks FOR SELECT
  USING (
    is_collaborative = true AND 
    id IN (
      SELECT task_id FROM public.task_participants tp
      WHERE tp.user_id = auth.uid()
    )
  );

-- ============================================
-- 4. TASK COMPLETIONS (for streaks and history)
-- ============================================
CREATE TABLE IF NOT EXISTS public.task_completions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id UUID REFERENCES public.tasks(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  xp_gained INTEGER,
  streak_count INTEGER DEFAULT 1 -- Current streak at time of completion
);

-- Enable RLS
ALTER TABLE public.task_completions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own completions" ON public.task_completions;
DROP POLICY IF EXISTS "Users can create own completions" ON public.task_completions;
DROP POLICY IF EXISTS "Users can delete own completions" ON public.task_completions;

-- Policies
CREATE POLICY "Users can view own completions"
  ON public.task_completions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own completions"
  ON public.task_completions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own completions"
  ON public.task_completions FOR DELETE
  USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_task_completions_task_id ON public.task_completions(task_id);
CREATE INDEX IF NOT EXISTS idx_task_completions_user_id ON public.task_completions(user_id);
CREATE INDEX IF NOT EXISTS idx_task_completions_completed_at ON public.task_completions(completed_at);

-- Note: Uniqueness constraint (one completion per day per task per user) 
-- is enforced via trigger (see trigger_check_daily_completion below)

-- ============================================
-- 5. TASK STREAKS (calculated streak data)
-- ============================================
CREATE TABLE IF NOT EXISTS public.task_streaks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id UUID REFERENCES public.tasks(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  current_streak INTEGER DEFAULT 0,
  max_streak INTEGER DEFAULT 0,
  last_completed_at TIMESTAMP WITH TIME ZONE,
  week_progress BOOLEAN[] DEFAULT ARRAY[false, false, false, false, false, false, false],
  has_streak_bonus BOOLEAN DEFAULT false,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(task_id, user_id)
);

-- Enable RLS
ALTER TABLE public.task_streaks ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own streaks" ON public.task_streaks;
DROP POLICY IF EXISTS "Users can create own streaks" ON public.task_streaks;
DROP POLICY IF EXISTS "Users can update own streaks" ON public.task_streaks;

-- Policies
CREATE POLICY "Users can view own streaks"
  ON public.task_streaks FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own streaks"
  ON public.task_streaks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own streaks"
  ON public.task_streaks FOR UPDATE
  USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_task_streaks_task_id ON public.task_streaks(task_id);
CREATE INDEX IF NOT EXISTS idx_task_streaks_user_id ON public.task_streaks(user_id);

-- ============================================
-- 6. TASK COMMENTS
-- ============================================
CREATE TABLE IF NOT EXISTS public.task_comments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id UUID REFERENCES public.tasks(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.task_comments ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view task comments" ON public.task_comments;
DROP POLICY IF EXISTS "Users can create task comments" ON public.task_comments;
DROP POLICY IF EXISTS "Users can update own comments" ON public.task_comments;
DROP POLICY IF EXISTS "Users can delete own comments" ON public.task_comments;

-- Policies
CREATE POLICY "Users can view task comments"
  ON public.task_comments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.tasks 
      WHERE tasks.id = task_comments.task_id 
      AND (tasks.user_id = auth.uid() OR tasks.is_collaborative = true)
    )
  );

CREATE POLICY "Users can create task comments"
  ON public.task_comments FOR INSERT
  WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM public.tasks 
      WHERE tasks.id = task_id 
      AND (tasks.user_id = auth.uid() OR tasks.is_collaborative = true)
    )
  );

CREATE POLICY "Users can update own comments"
  ON public.task_comments FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own comments"
  ON public.task_comments FOR DELETE
  USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_task_comments_task_id ON public.task_comments(task_id);
CREATE INDEX IF NOT EXISTS idx_task_comments_user_id ON public.task_comments(user_id);

-- ============================================
-- 7. FRIENDSHIPS
-- ============================================
CREATE TABLE IF NOT EXISTS public.friendships (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  friend_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  status TEXT CHECK (status IN ('pending', 'accepted', 'blocked')) DEFAULT 'pending',
  requested_by UUID REFERENCES auth.users(id) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, friend_id),
  CHECK (user_id != friend_id)
);

-- Enable RLS
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own friendships" ON public.friendships;
DROP POLICY IF EXISTS "Users can create friendships" ON public.friendships;
DROP POLICY IF EXISTS "Users can update own friendships" ON public.friendships;
DROP POLICY IF EXISTS "Users can delete own friendships" ON public.friendships;

-- Policies
CREATE POLICY "Users can view own friendships"
  ON public.friendships FOR SELECT
  USING (auth.uid() = user_id OR auth.uid() = friend_id);

CREATE POLICY "Users can create friendships"
  ON public.friendships FOR INSERT
  WITH CHECK (auth.uid() = requested_by AND (auth.uid() = user_id OR auth.uid() = friend_id));

CREATE POLICY "Users can update own friendships"
  ON public.friendships FOR UPDATE
  USING (auth.uid() = user_id OR auth.uid() = friend_id);

CREATE POLICY "Users can delete own friendships"
  ON public.friendships FOR DELETE
  USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_friendships_user_id ON public.friendships(user_id);
CREATE INDEX IF NOT EXISTS idx_friendships_friend_id ON public.friendships(friend_id);
CREATE INDEX IF NOT EXISTS idx_friendships_status ON public.friendships(status);

-- ============================================
-- 8. ACTIVITIES (Activity Feed)
-- ============================================
CREATE TABLE IF NOT EXISTS public.activities (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL, -- task_completed, streak_achieved, level_up, friend_added, badge_earned
  task_id UUID REFERENCES public.tasks(id) ON DELETE SET NULL,
  friend_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  message TEXT NOT NULL,
  xp_gained INTEGER,
  metadata JSONB, -- Additional data for different activity types
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view activities" ON public.activities;
DROP POLICY IF EXISTS "Users can create activities" ON public.activities;

-- Policies
CREATE POLICY "Users can view activities"
  ON public.activities FOR SELECT
  USING (
    -- Users can see their own activities
    auth.uid() = user_id OR
    -- Users can see friends' activities
    EXISTS (
      SELECT 1 FROM public.friendships
      WHERE (friendships.user_id = auth.uid() AND friendships.friend_id = activities.user_id)
         OR (friendships.friend_id = auth.uid() AND friendships.user_id = activities.user_id)
      AND friendships.status = 'accepted'
    )
  );

CREATE POLICY "Users can create activities"
  ON public.activities FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_activities_user_id ON public.activities(user_id);
CREATE INDEX IF NOT EXISTS idx_activities_type ON public.activities(type);
CREATE INDEX IF NOT EXISTS idx_activities_created_at ON public.activities(created_at DESC);

-- ============================================
-- 9. FUNCTIONS AND TRIGGERS
-- ============================================

-- Function to automatically create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1))
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger to call function on new user
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update task status to overdue
CREATE OR REPLACE FUNCTION public.update_overdue_tasks()
RETURNS void AS $$
BEGIN
  UPDATE public.tasks
  SET status = 'overdue'
  WHERE status = 'active'
    AND due_date < NOW()
    AND due_date IS NOT NULL;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate and update streaks
CREATE OR REPLACE FUNCTION public.update_task_streak(p_task_id UUID, p_user_id UUID)
RETURNS void AS $$
DECLARE
  v_current_streak INTEGER;
  v_max_streak INTEGER;
  v_last_completed TIMESTAMP WITH TIME ZONE;
  v_week_progress BOOLEAN[];
  v_day_of_week INTEGER;
  v_has_completion BOOLEAN;
BEGIN
  -- Calculate current streak (consecutive days with completion)
  SELECT COUNT(*)
  INTO v_current_streak
  FROM (
    SELECT DISTINCT DATE(completed_at) as completion_date
    FROM public.task_completions
    WHERE task_id = p_task_id AND user_id = p_user_id
    ORDER BY completion_date DESC
    LIMIT 30
  ) recent_completions;

  -- Get max streak
  SELECT COALESCE(MAX(streak_count), 0)
  INTO v_max_streak
  FROM public.task_completions
  WHERE task_id = p_task_id AND user_id = p_user_id;

  -- Get last completed date
  SELECT MAX(completed_at)
  INTO v_last_completed
  FROM public.task_completions
  WHERE task_id = p_task_id AND user_id = p_user_id;

  -- Calculate week progress (last 7 days)
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

-- Function to update XP and level when task is completed
CREATE OR REPLACE FUNCTION public.update_user_xp(p_user_id UUID, p_xp_gained INTEGER)
RETURNS void AS $$
DECLARE
  v_current_xp INTEGER;
  v_total_xp INTEGER;
  v_level INTEGER;
  v_next_level_xp INTEGER;
BEGIN
  -- Get current profile data
  SELECT current_xp, total_xp, level
  INTO v_current_xp, v_total_xp, v_level
  FROM public.profiles
  WHERE id = p_user_id;

  -- Update XP
  v_current_xp := COALESCE(v_current_xp, 0) + p_xp_gained;
  v_total_xp := COALESCE(v_total_xp, 0) + p_xp_gained;

  -- Calculate next level XP
  v_next_level_xp := (100 * (v_level * v_level * 1.5))::INTEGER;

  -- Level up if needed
  WHILE v_current_xp >= v_next_level_xp LOOP
    v_current_xp := v_current_xp - v_next_level_xp;
    v_level := v_level + 1;
    v_next_level_xp := (100 * (v_level * v_level * 1.5))::INTEGER;
  END LOOP;

  -- Update profile
  UPDATE public.profiles
  SET 
    current_xp = v_current_xp,
    total_xp = v_total_xp,
    level = v_level,
    updated_at = NOW()
  WHERE id = p_user_id;

  -- Create level up activity if leveled up
  IF v_level > (SELECT level FROM public.profiles WHERE id = p_user_id) THEN
    INSERT INTO public.activities (user_id, type, message, metadata)
    VALUES (p_user_id, 'level_up', format('leveled up to Level %s!', v_level), 
            jsonb_build_object('level', v_level));
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to check for duplicate daily completions
CREATE OR REPLACE FUNCTION public.check_daily_completion()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if there's already a completion for this task/user on the same day
  IF EXISTS (
    SELECT 1 FROM public.task_completions
    WHERE task_id = NEW.task_id
      AND user_id = NEW.user_id
      AND DATE(completed_at) = DATE(NEW.completed_at)
      AND id != NEW.id
  ) THEN
    RAISE EXCEPTION 'Task already completed today. Only one completion per day per task is allowed.';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to check for duplicate daily completions
DROP TRIGGER IF EXISTS trigger_check_daily_completion ON public.task_completions;
CREATE TRIGGER trigger_check_daily_completion
  BEFORE INSERT ON public.task_completions
  FOR EACH ROW EXECUTE FUNCTION public.check_daily_completion();

-- Trigger to update streak when task is completed
CREATE OR REPLACE FUNCTION public.on_task_completed()
RETURNS TRIGGER AS $$
BEGIN
  -- Update streak
  PERFORM public.update_task_streak(NEW.task_id, NEW.user_id);
  
  -- Update XP
  PERFORM public.update_user_xp(NEW.user_id, COALESCE(NEW.xp_gained, 0));
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to check for duplicate daily completions
CREATE OR REPLACE FUNCTION public.check_daily_completion()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if there's already a completion for this task/user on the same day
  IF EXISTS (
    SELECT 1 FROM public.task_completions
    WHERE task_id = NEW.task_id
      AND user_id = NEW.user_id
      AND DATE(completed_at) = DATE(NEW.completed_at)
      AND id != NEW.id
  ) THEN
    RAISE EXCEPTION 'Task already completed today. Only one completion per day per task is allowed.';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to check for duplicate daily completions (BEFORE INSERT)
DROP TRIGGER IF EXISTS trigger_check_daily_completion ON public.task_completions;
CREATE TRIGGER trigger_check_daily_completion
  BEFORE INSERT ON public.task_completions
  FOR EACH ROW EXECUTE FUNCTION public.check_daily_completion();

-- Trigger to update streak when task is completed (AFTER INSERT)
DROP TRIGGER IF EXISTS trigger_task_completed ON public.task_completions;
CREATE TRIGGER trigger_task_completed
  AFTER INSERT ON public.task_completions
  FOR EACH ROW EXECUTE FUNCTION public.on_task_completed();

-- ============================================
-- 10. INITIAL DATA FOR EXISTING USERS
-- ============================================

-- Create profiles for existing users
INSERT INTO public.profiles (id, full_name, created_at)
SELECT 
  id,
  COALESCE(raw_user_meta_data->>'full_name', split_part(email, '@', 1)) as full_name,
  created_at
FROM auth.users
WHERE id NOT IN (SELECT id FROM public.profiles)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- DONE! All tables and functions created
-- ============================================

