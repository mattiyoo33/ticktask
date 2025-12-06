# Fix: Collaboration Invitations Not Showing

## Problem
Collaboration invitations don't appear in the task list with Accept/Refuse buttons, even though participants exist in the database.

## Root Cause
RLS (Row Level Security) policies are missing or blocking queries to the `task_participants` table.

## Solution

### Step 1: Run SQL Fixes

Run these SQL files in Supabase SQL Editor (in order):

1. **`sql/ADD_PARTICIPANT_STATUS.sql`** - Adds status column (if not already done)
2. **`sql/FIX_TASK_PARTICIPANTS_RLS_VIEW.sql`** ⭐ **MAIN FIX** - Allows users to view their own participants
3. **`sql/FIX_COLLABORATIVE_TASKS_RLS.sql`** - Allows participants to view collaborative tasks

**How to run:**
- Open Supabase Dashboard → SQL Editor
- Copy entire file contents
- Paste and click "Run"
- Verify you see success messages

### Step 2: Hot Restart App

1. Stop the app completely
2. Start it again (hot restart, not hot reload)
3. Log in as the invited user
4. Navigate to task list

### Step 3: Check Console

You should see:
```
✅ Query succeeded: Found X pending participants
📊 UI: Pending tasks count: X
```

If you still see `Found 0 pending participants`, the RLS policy wasn't created. Run `FIX_TASK_PARTICIPANTS_RLS_VIEW.sql` again.

## Quick Checklist

- [ ] Ran `sql/ADD_PARTICIPANT_STATUS.sql`
- [ ] Ran `sql/FIX_TASK_PARTICIPANTS_RLS_VIEW.sql` (CRITICAL)
- [ ] Ran `sql/FIX_COLLABORATIVE_TASKS_RLS.sql`
- [ ] Hot restarted the app
- [ ] Logged in as invited user (not task owner)
- [ ] Checked console for success messages

## Expected Result

After fixes, you should see:
- Collaboration invitations section at top of task list
- Task owner's name and avatar
- Task title and description
- **Accept** and **Refuse** buttons

