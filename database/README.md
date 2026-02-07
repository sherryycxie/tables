# Database Scripts

This folder contains all SQL scripts for setting up and maintaining the Supabase PostgreSQL database.

## Folder Structure

```
database/
├── setup/          # Initial setup scripts (run once)
├── migrations/     # Schema changes and fixes
└── realtime/       # Realtime subscription configuration
```

## Setup Order

Run these scripts in your Supabase SQL Editor in the following order:

### 1. Initial Setup

```
setup/00_rls_policies_original.sql  # Original RLS policies (reference only)
setup/01_rls_policies.sql           # Fixed RLS policies
setup/02_functions.sql              # Database functions
```

### 2. Enable Realtime

```
realtime/enable_tables.sql          # Enable realtime for tables
realtime/enable_shares.sql          # Enable realtime for shares
realtime/notification_queue.sql     # Notification queue setup
```

### 3. Migrations (as needed)

```
migrations/add_member_function.sql  # Add member function
migrations/fix_members.sql          # Fix members migration
```

## Notes

- Always run setup scripts before migrations
- Realtime scripts can be run after the initial setup
- Back up your database before running migrations in production
