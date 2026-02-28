-- ============================================
-- DAILY LOGINS TABLE (login streak + daily XP bonus)
-- ============================================
-- One row per user per calendar day. Used to compute consecutive-day streak
-- and to award daily login XP (20–55 based on streak).

CREATE TABLE IF NOT EXISTS public.daily_logins (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  login_date DATE NOT NULL,
  xp_awarded INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, login_date)
);

-- RLS
ALTER TABLE public.daily_logins ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own daily logins" ON public.daily_logins;
DROP POLICY IF EXISTS "Users can insert own daily logins" ON public.daily_logins;

CREATE POLICY "Users can view own daily logins"
  ON public.daily_logins FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own daily logins"
  ON public.daily_logins FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_daily_logins_user_date ON public.daily_logins(user_id, login_date DESC);
