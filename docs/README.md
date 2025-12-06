# TickTask Documentation

This directory contains all documentation for the TickTask application, organized by category.

## 📁 Directory Structure

```
docs/
├── database/          # SQL schema and migration files
├── setup/            # Setup and installation guides
├── features/         # Feature documentation
└── fixes/            # Bug fixes and troubleshooting guides
```

## 📚 Documentation Index

### Setup & Installation
- **[Complete Setup Summary](setup/COMPLETE_SETUP_SUMMARY.md)** - Overview of the complete setup process
- **[Database Setup Instructions](setup/DATABASE_SETUP_INSTRUCTIONS.md)** - Step-by-step database setup guide

### Features
- **[AI Features Setup](features/AI_FEATURES_SETUP.md)** - How to configure and use AI features (task generation, animations)
- **[Task Reward Logic Update](features/TASK_REWARD_LOGIC_UPDATE.md)** - XP reward system documentation
- **[Friend Selection and Comments Implementation](features/FRIEND_SELECTION_AND_COMMENTS_IMPLEMENTATION.md)** - Collaboration features documentation

### Bug Fixes & Troubleshooting
- **[Fix Data Leakage](fixes/FIX_DATA_LEAKAGE.md)** - Fix for data leakage between accounts
- **[Fix Collaborator Self Issue](fixes/FIX_COLLABORATOR_SELF_ISSUE.md)** - Fix for current user appearing as collaborator
- **[Step-by-Step Fix for Collaboration Invitations](fixes/STEP_BY_STEP_FIX.md)** - Complete guide for fixing collaboration invitations

### Database
- **[Complete Database Schema](database/COMPLETE_DATABASE_SCHEMA.sql)** - Full database schema (run this first)
- **[Add Participant Status](database/ADD_PARTICIPANT_STATUS.sql)** - Migration to add status column to task_participants
- **[Update Comments RLS Policy](database/UPDATE_COMMENTS_RLS_POLICY.sql)** - Row Level Security policy for comments
- **[Fix Task Participants RLS](database/FIX_TASK_PARTICIPANTS_RLS.sql)** - RLS policy fixes for task participants
- **[Fix Task Participants FK](database/FIX_TASK_PARTICIPANTS_FK.sql)** - Foreign key fixes for task participants
- **[Fix Friendships FK](database/FIX_FRIENDSHIPS_FK.sql)** - Foreign key fixes for friendships
- **[Fix Profiles XP Columns](database/FIX_PROFILES_XP_COLUMNS.sql)** - XP column fixes for profiles
- **[Fix Task Streaks RLS](database/FIX_TASK_STREAKS_RLS.sql)** - RLS policy fixes for task streaks
- **[Fix Policy Recursion](database/FIX_POLICY_RECURSION.sql)** - Fix for recursive RLS policies

## 🚀 Quick Start

1. **Database Setup**: Start with `database/COMPLETE_DATABASE_SCHEMA.sql`
2. **Run Migrations**: Apply any additional SQL files in `database/` as needed
3. **Feature Setup**: Follow guides in `setup/` and `features/` directories
4. **Troubleshooting**: Check `fixes/` directory if you encounter issues

## 📝 Notes

- SQL files should be run in Supabase SQL Editor in the order they appear in this README
- Always backup your database before running migration scripts
- Check the main [README.md](../README.md) for general project information

