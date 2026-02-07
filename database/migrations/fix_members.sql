-- One-time migration to fix existing shared tables
-- This script adds missing members to tables that have been shared but don't have
-- the shared user in the members array
-- Run this ONCE after deploying the add_table_member function

DO $$
DECLARE
  share_record RECORD;
  user_name TEXT;
BEGIN
  FOR share_record IN
    SELECT ts.table_id, ts.shared_with_user_id, p.display_name, p.email
    FROM table_shares ts
    JOIN profiles p ON p.id = ts.shared_with_user_id
  LOOP
    -- Get display name or email as fallback
    user_name := COALESCE(share_record.display_name, share_record.email);

    -- Add to members array if not present (using the function we created)
    IF user_name IS NOT NULL THEN
      PERFORM add_table_member(share_record.table_id, user_name);
      RAISE NOTICE 'Added % to table %', user_name, share_record.table_id;
    END IF;
  END LOOP;

  RAISE NOTICE 'Migration complete!';
END $$;

-- Verify the migration worked
SELECT
  t.id,
  t.title,
  t.members,
  array_length(t.members, 1) as member_count,
  COUNT(ts.shared_with_user_id) as share_count
FROM tables t
LEFT JOIN table_shares ts ON ts.table_id = t.id
GROUP BY t.id, t.title, t.members
ORDER BY t.updated_at DESC;
