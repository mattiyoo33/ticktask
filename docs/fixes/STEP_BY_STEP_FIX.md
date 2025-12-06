# Complete Fix Guide: Collaboration Invitations Not Showing

## Problem
Collaboration invitations are not visible in the task list, even though:
- ✅ Participants exist in database
- ✅ Status is set to 'pending'
- ✅ Tasks are marked as collaborative

## Root Cause
RLS (Row Level Security) policy is blocking the query from reading `task_participants` table. Users cannot see their own participant records.

## Solution

### Step 1: Run Required SQL Fixes (CRITICAL)

**Run these SQL files in Supabase SQL Editor (in this order):**

1. **`docs/database/ADD_PARTICIPANT_STATUS.sql`**
   - Adds the `status` column to track invitation status
   - Run this first if status column doesn't exist

2. **`docs/database/FIX_TASK_PARTICIPANTS_RLS_VIEW.sql`** ⭐ **MAIN FIX**
   - Allows users to view their own participant records
   - **This fixes "Found 0 pending participants" error**

3. **`docs/database/FIX_COLLABORATIVE_TASKS_RLS.sql`**
   - Allows participants to view tasks they're invited to
   - Run if collaborative tasks RLS policy is missing

**How to run:**
1. Open **Supabase Dashboard** → **SQL Editor**
2. Open each file, copy entire contents
3. Paste into Supabase SQL Editor
4. Click "Run"
5. Verify you see success messages (✅ Policy exists)

### Step 2: Hot Restart the App

1. **Stop the app completely**
2. **Start it again** (hot restart, not hot reload)
3. **Log in as the invited user** (not the task owner)
4. **Navigate to task list**

### Step 3: Check Console Logs

After hot restart, you should see:

**✅ Success:**
```
🔄 Refreshed pendingCollaborationTasksProvider on screen load
Fetching pending collaboration tasks for user: [USER_ID]
🔍 Querying task_participants for user: [USER_ID] with status=pending
✅ Query succeeded: Found 1 pending participants with status field
📋 Participant details: [task_id: ..., status: pending]
✅ Found 1 pending invitations
📋 Fetching tasks with IDs: [...]
🔍 Attempting to fetch task [TASK_ID] directly...
✅ Direct query succeeded for task [TASK_ID]
✅ Task [TASK_ID] is an invitation
✅ Fetched owner profile: [OWNER_NAME]
✅ Added task to invitations list: [TASK_TITLE]
📊 Final result: Found 1 pending collaboration tasks after filtering
📊 UI: Pending tasks count: 1
📋 UI: Pending task titles: [[TASK_TITLE]]
```

**❌ If you still see errors:**
- `❌ Status column query failed` → RLS still blocking
- `⚠️ No participants found at all` → RLS policy not working
- `❌ Fallback query also failed` → RLS definitely blocking

## Troubleshooting

### If You Still See "Found 0 pending participants"

1. **Verify RLS Policy Exists:**
   ```sql
   SELECT * FROM pg_policies 
   WHERE tablename = 'task_participants' 
   AND policyname = 'Users can view task participants';
   ```
   If this returns 0 rows, run `FIX_TASK_PARTICIPANTS_RLS_VIEW.sql` again.

2. **Verify User ID Matches:**
   - Console shows: `Fetching pending collaboration tasks for user: [USER_ID]`
   - Database query: `SELECT user_id FROM task_participants WHERE status = 'pending'`
   - They must match exactly!

3. **Verify Status is 'pending':**
   ```sql
   SELECT task_id, user_id, status 
   FROM task_participants 
   WHERE user_id = 'USER_ID_HERE';
   ```
   Status should be 'pending', not NULL or 'accepted'

4. **Check if RLS is Still Blocking:**
   - Look for `❌ Fallback query also failed` in console
   - This means RLS is still blocking - run the fix script again

## Quick Checklist

- [ ] **Ran `docs/database/ADD_PARTICIPANT_STATUS.sql`** (if status column missing)
- [ ] **Ran `docs/database/FIX_TASK_PARTICIPANTS_RLS_VIEW.sql`** (CRITICAL)
- [ ] **Ran `docs/database/FIX_COLLABORATIVE_TASKS_RLS.sql`** (if needed)
- [ ] **Hot restarted** the app (not just hot reload)
- [ ] **Logged in as the invited user** (not the task owner)
- [ ] **Checked console logs** for success messages
- [ ] **Verified user ID** in console matches user_id in database
- [ ] **Verified status** is 'pending' in database

## Expected Result

After running the fixes and hot restarting, you should see:
- ✅ Collaboration invitations section at the top of task list
- ✅ Task owner's name and avatar
- ✅ Task title and description
- ✅ **Accept** and **Refuse** buttons

If you see this, the fix worked! 🎉
