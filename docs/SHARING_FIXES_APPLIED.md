# Sharing Errors Fixed

## Issues Resolved

### 1. "new row violates row-level security policy" Error

**Root Cause:**
The `add_table_member` RPC function was marked as `SECURITY DEFINER` but lacked the `SET search_path = public` directive, causing it to still be subject to RLS policies when updating the `tables.members` array.

**Fix Applied:**
Updated `/supabase_add_member_function.sql` to include `SET search_path = public`:

```sql
CREATE OR REPLACE FUNCTION add_table_member(
  p_table_id UUID,
  p_member_name TEXT
)
RETURNS VOID AS $$
BEGIN
  UPDATE tables
  SET
    members = CASE
      WHEN p_member_name = ANY(members) THEN members
      ELSE array_append(members, p_member_name)
    END,
    updated_at = NOW()
  WHERE id = p_table_id;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public;  -- ✅ Added this line
```

### 2. "JWT expired" Error

**Root Cause:**
The app had no automatic token refresh mechanism. When JWT tokens expired (typically after 1 hour), all API requests would fail until the user signed out and signed back in.

**Fix Applied:**
Added automatic JWT token refresh to `SupabaseManager.swift`:

1. **New `refreshSession()` function** - Retrieves a fresh JWT token from Supabase
2. **New `executeWithTokenRefresh()` wrapper** - Automatically catches JWT expiration errors, refreshes the token, and retries the operation
3. **Updated all API functions** to use the wrapper:
   - Tables: `fetchTables`, `createTable`, `updateTable`, `deleteTable`, `archiveTable`, `unarchiveTable`
   - Cards: `fetchCards`, `createCard`, `updateCard`, `deleteCard`
   - Comments: `fetchComments`, `createComment`, `deleteComment`
   - Nudges: `fetchNudges`, `createNudge`
   - Sharing: `shareTable`, `removeShare`, `fetchShares`
   - Profile: `fetchProfile`, `createProfile`, `updateProfile`

### 3. Real-time Updates for Shared Tables

**Root Cause:**
The app only subscribed to changes on the `tables` table, not the `table_shares` table. When someone shared a table with you, you wouldn't see it until signing out and back in.

**Fix Applied:**
Added real-time subscription to `table_shares` in `SupabaseManager.swift`:

1. **New `sharesRealtimeChannel` property** - Dedicated channel for share notifications
2. **Updated `setupRealtimeSubscription()`** - Now subscribes to both `tables` and `table_shares` changes
3. **Updated `removeRealtimeSubscription()`** - Cleans up both subscriptions on sign out
4. **Automatic table refresh** - When a share is created/deleted, the app automatically refetches all accessible tables

## How to Apply the Database Fixes

### Step 1: Update the add_table_member Function

1. Go to your Supabase Dashboard: https://supabase.com/dashboard
2. Navigate to your project: **wfhnsoretclgrvsagbyj**
3. Click on **SQL Editor** in the left sidebar
4. Click **New Query**
5. Copy and paste this SQL:

```sql
-- Function to add a member to a table's members array
-- This function provides atomic, idempotent member addition to the tables.members array
-- Usage: SELECT add_table_member('table-uuid-here', 'User Name');

CREATE OR REPLACE FUNCTION add_table_member(
  p_table_id UUID,
  p_member_name TEXT
)
RETURNS VOID AS $$
BEGIN
  -- Only add if not already present (idempotent operation)
  UPDATE tables
  SET
    members = CASE
      WHEN p_member_name = ANY(members) THEN members
      ELSE array_append(members, p_member_name)
    END,
    updated_at = NOW()
  WHERE id = p_table_id;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION add_table_member(UUID, TEXT) TO authenticated;
```

6. Click **Run** to execute the query

### Step 2: Enable Realtime for table_shares

1. In the same **SQL Editor**, create another **New Query**
2. Copy and paste this SQL:

```sql
-- Enable Realtime for table_shares
-- This allows the app to receive real-time notifications when tables are shared

ALTER TABLE table_shares REPLICA IDENTITY FULL;
```

3. Click **Run** to execute

4. Then go to **Database** > **Replication** in your Supabase Dashboard
5. Find **table_shares** in the tables list
6. Toggle the switch to **ON** to enable realtime subscriptions

### Option 2: Via Command Line

If you have the Supabase CLI installed:

```bash
cd /Users/sherryxie/Desktop/tables
supabase db push
```

## Testing the Fixes

### Test 1: RLS Policy Fix
1. Sign in with a new account
2. Create a table
3. Share the table with an old account's email
4. ✅ Should succeed without RLS errors

### Test 2: JWT Token Refresh
1. Sign in with an old account
2. Wait for 1+ hour (or manually set a short JWT expiration in Supabase settings for testing)
3. Try to share a table with a new account
4. ✅ Should automatically refresh the token and succeed instead of showing "JWT expired"

### Test 3: Real-time Shared Tables
1. Open the app on **Device A** and sign in with **Account A**
2. Open the app on **Device B** (or another simulator) and sign in with **Account B**
3. On **Device A**, create a table and share it with **Account B**
4. ✅ On **Device B**, the shared table should appear **immediately** without needing to sign out/in
5. On **Device A**, unshare the table
6. ✅ On **Device B**, the table should disappear **immediately** from the shared tables list

## What Changed in the Code

### Database Function (`supabase_add_member_function.sql`)
- Added `SET search_path = public` to ensure proper RLS bypass

### Swift Code (`SupabaseManager.swift`)
- Added `refreshSession()` method (lines ~80-85)
- Added `executeWithTokenRefresh()` wrapper (lines ~87-115)
- Wrapped all database operations with token refresh logic
- Operations now automatically retry once on JWT expiration after refreshing the token
- Added `sharesRealtimeChannel` property to track share subscription
- Updated `setupRealtimeSubscription()` to subscribe to both `tables` and `table_shares` changes
- Updated `removeRealtimeSubscription()` to clean up both channels

## Benefits

1. **More reliable sharing** - No more RLS policy violations when adding members
2. **Better user experience** - Users don't need to sign out/in when their session expires
3. **Automatic recovery** - Failed requests due to expired tokens automatically retry with fresh tokens
4. **Consistent behavior** - All API operations now have the same token refresh protection
5. **Real-time collaboration** - Shared tables appear instantly when someone shares with you
6. **Live updates** - No more manual refreshing or signing out/in to see shared tables

## Important Notes

- The Swift code changes are already applied locally
- **You MUST apply both database updates** (Steps 1 & 2) by running the SQL in your Supabase dashboard
- Without Step 1 (add_table_member update), new→old account sharing will still fail with RLS errors
- Without Step 2 (realtime enablement), shared tables won't appear in real-time
- The token refresh mechanism works for all operations, not just sharing
- If token refresh fails (e.g., refresh token also expired), the app will set `isAuthenticated = false` and prompt the user to sign in again
- Realtime subscriptions are automatically set up on sign-in and cleaned up on sign-out
