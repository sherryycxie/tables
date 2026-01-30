# Supabase Database Setup Instructions

## Problems Fixed
1. **Cards not being created**: Row Level Security (RLS) policies were blocking card insertions
2. **Share functionality failing**: RLS policies prevented users from querying other users' profiles

## Solution
We've implemented:
1. Comprehensive RLS policies for all tables (tables, cards, comments, nudges, table_shares)
2. An RPC function for safely searching users by email when sharing

## Setup Steps

### STEP 1: Set Up Row-Level Security Policies (REQUIRED)

**This step is CRITICAL - without it, you cannot add cards to tables!**

1. Go to your Supabase project dashboard
2. Navigate to the **SQL Editor** (in the left sidebar)
3. Click **New Query**
4. Copy the **entire contents** of `supabase_rls_policies.sql`
5. Paste it into the SQL Editor
6. Click **Run** or press `Cmd/Ctrl + Enter`
7. You should see "Success. No rows returned" - this is expected!

This sets up all the security policies that allow:
- Users to create, view, and manage their own tables
- Users to add cards to tables they own or have been shared with
- Users to comment on accessible cards
- Table owners to share tables with others

### STEP 2: Set Up User Search Function (for sharing feature)

1. Go to your Supabase project dashboard (again, if needed)
2. Navigate to the **SQL Editor** (in the left sidebar)
3. Click **New Query**
4. Copy the contents of `supabase_functions.sql`
5. Paste it into the SQL Editor
6. Click **Run** or press `Cmd/Ctrl + Enter`

The SQL creates a function called `find_user_by_email` that:
- Searches for users by email (case-insensitive)
- Bypasses RLS policies using `SECURITY DEFINER`
- Only returns necessary information (user_id, email, display_name)
- Is only accessible to authenticated users

### STEP 3: Verify Everything Works

**Test Card Creation:**
1. Build and run the app
2. Navigate to any table
3. Try adding a card - it should work now!

**Test the Share Functionality (Optional):**
After running the SQL, you can test it by running:

```sql
SELECT * FROM find_user_by_email('test@example.com');
```

### 4. Test the Share Functionality
1. Build and run the app on your simulator
2. Create a table with one account
3. Use the share button to share it with another account's email
4. The "User not found" error should no longer appear

## What Changed in the Code

The Swift code in `SupabaseManager.swift` now uses:
```swift
postgrest.rpc("find_user_by_email", params: ["user_email": email])
```

Instead of:
```swift
postgrest.from("profiles").select().eq("email", value: email)
```

This allows the function to run with elevated privileges while maintaining security.

## Security Notes
- The function is marked as `SECURITY DEFINER` which means it runs with the privileges of the user who created it (usually the database owner)
- It only returns user_id, email, and display_name - no sensitive information
- It's only accessible to authenticated users (via `GRANT EXECUTE ON FUNCTION`)
- The email search is case-insensitive for better user experience
