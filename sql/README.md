# SQL Files for TickTask Database

This folder contains all SQL schema and migration files for the TickTask database.

## Setup Order

1. **`COMPLETE_DATABASE_SCHEMA.sql`** - Run this first!
   - Creates all tables, indexes, RLS policies, and functions
   - This is the foundation for the entire database

2. **`ADD_PARTICIPANT_STATUS.sql`** - Adds status column to task_participants
   - Required for collaboration invitation tracking
   - Status values: 'pending', 'accepted', 'refused'

3. **Other FIX_*.sql files** - Run as needed if you encounter issues
   - Most are idempotent (safe to run multiple times)
   - Check file comments for specific purposes

## How to Use

1. Open **Supabase Dashboard** → **SQL Editor**
2. Copy the entire contents of the SQL file
3. Paste into Supabase SQL Editor
4. Click "Run"
5. Verify success messages

## Important Notes

- Always backup your database before running scripts
- Run `COMPLETE_DATABASE_SCHEMA.sql` first
- Most fix scripts check if changes already exist before applying

