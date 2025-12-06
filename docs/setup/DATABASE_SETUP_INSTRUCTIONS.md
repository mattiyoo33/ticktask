# Complete Database Setup Instructions

## 🚀 Step 1: Run the SQL Schema

1. **Open Supabase Dashboard** → Go to **SQL Editor**
2. **Copy the entire contents** of `COMPLETE_DATABASE_SCHEMA.sql`
3. **Paste and Run** the SQL
4. **Wait for completion** - This creates all tables, policies, functions, and triggers

---

## 📊 What Gets Created

### Tables:
- ✅ **profiles** - User profiles with XP and level
- ✅ **tasks** - All user tasks
- ✅ **task_participants** - Collaborative task participants
- ✅ **task_completions** - Task completion history (for streaks)
- ✅ **task_streaks** - Calculated streak data per task
- ✅ **task_comments** - Comments on tasks
- ✅ **friendships** - Friend requests and friendships
- ✅ **activities** - Activity feed (recent activities)

### Functions:
- ✅ **handle_new_user()** - Auto-creates profile on signup
- ✅ **update_overdue_tasks()** - Marks overdue tasks
- ✅ **update_task_streak()** - Calculates and updates streaks
- ✅ **update_user_xp()** - Updates XP and levels on task completion

### Triggers:
- ✅ **on_auth_user_created** - Creates profile when user signs up
- ✅ **trigger_task_completed** - Updates streak and XP when task completed

---

## ✅ Step 2: Verify Setup

After running the SQL:

1. **Check Tables:**
   - Go to **Table Editor** in Supabase
   - You should see all 8 tables listed

2. **Check Policies:**
   - Go to **Authentication** → **Policies**
   - Each table should have RLS enabled with policies

3. **Test Profile Creation:**
   - Create a new user account in your app
   - Check `profiles` table - should have a new row

---

## 🔧 Step 3: Update Your App

The app now has:
- ✅ **TaskService** - Handles all task operations
- ✅ **FriendService** - Handles friends and friend requests
- ✅ **ActivityService** - Handles activity feed
- ✅ **Service Providers** - Riverpod providers for all services

### Next Steps:
1. Update screens to use real data (remove mock data)
2. Connect task creation to database
3. Connect friend requests to database
4. Connect activity feed to database

---

## 📝 Data Flow

```
User Action
  ↓
Service (TaskService/FriendService/etc.)
  ↓
Supabase Database
  ↓
Triggers & Functions (auto-update streaks, XP, etc.)
  ↓
UI Updates (via Riverpod providers)
```

---

## 🐛 Troubleshooting

### Issue: "relation does not exist"
**Solution:** Make sure you ran the entire SQL file, not just parts of it.

### Issue: "permission denied"
**Solution:** Check that RLS policies are created correctly. The SQL includes all necessary policies.

### Issue: Profile not created on signup
**Solution:** Check that the trigger `on_auth_user_created` exists and is enabled.

### Issue: Streaks not updating
**Solution:** The streak function runs automatically when tasks are completed via the trigger.

---

## ✅ What's Working Now

After setup:
- ✅ **User profiles** with XP and levels
- ✅ **Task creation** and management
- ✅ **Task completion** with automatic XP/streak updates
- ✅ **Friend requests** and friendships
- ✅ **Activity feed** tracking
- ✅ **Leaderboard** based on XP
- ✅ **Task comments** and collaboration
- ✅ **Streak tracking** per task

---

## 🎉 Ready to Use!

Your database is now fully set up and ready for the app to use real data instead of mockups!

