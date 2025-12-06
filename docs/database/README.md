# Database Documentation

This directory contains all SQL schema and migration files for the TickTask database.

## 📋 Files Overview

### Main Schema
- **`COMPLETE_DATABASE_SCHEMA.sql`** - Complete database schema (run this first!)
  - Creates all tables, indexes, RLS policies, and functions
  - This is the foundation for the entire database

### Migrations (Run in Order)

1. **`ADD_PARTICIPANT_STATUS.sql`** - Adds `status` column to `task_participants` table
   - Required for collaboration invitation tracking
   - Status values: 'pending', 'accepted', 'refused'

2. **`FIX_TASK_PARTICIPANTS_FK.sql`** - Fixes foreign key relationships for task participants

3. **`FIX_TASK_PARTICIPANTS_RLS.sql`** - Fixes Row Level Security policies for task participants

4. **`FIX_FRIENDSHIPS_FK.sql`** - Fixes foreign key relationships for friendships

5. **`FIX_PROFILES_XP_COLUMNS.sql`** - Fixes XP-related columns in profiles table

6. **`FIX_TASK_STREAKS_RLS.sql`** - Fixes RLS policies for task streaks

7. **`FIX_POLICY_RECURSION.sql`** - Fixes recursive RLS policy issues

8. **`UPDATE_COMMENTS_RLS_POLICY.sql`** - Updates RLS policies for task comments

9. **`FIX_COLLABORATIVE_TASKS_RLS.sql`** - Fixes missing RLS policy for collaborative tasks
   - Adds "Users can view collaborative tasks" policy
   - Required for participants to view tasks they're invited to

10. **`FIX_TASK_PARTICIPANTS_RLS_VIEW.sql`** - Fixes RLS policy for viewing participants
    - Allows users to view their own participant records
    - Required for pending invitations to work

## 🚀 Setup Instructions

1. **Initial Setup**:
   ```sql
   -- Run this first in Supabase SQL Editor
   -- Copy and paste the entire contents of COMPLETE_DATABASE_SCHEMA.sql
   ```

2. **Apply Migrations**:
   ```sql
   -- Run migrations in order as needed
   -- Most migrations check if changes already exist before applying
   ```

3. **Verify Setup**:
   - Check that all tables exist
   - Verify RLS policies are enabled
   - Test that foreign keys are properly set up

## ⚠️ Important Notes

- **Always backup your database** before running migration scripts
- Run migrations in a test environment first
- Some migrations are idempotent (safe to run multiple times)
- Check migration comments for specific requirements

## 🔍 Troubleshooting

If you encounter issues:
1. Check the error message in Supabase SQL Editor
2. Verify that `COMPLETE_DATABASE_SCHEMA.sql` was run first
3. Check if the migration has already been applied
4. Review the main [README.md](../README.md) for general troubleshooting

