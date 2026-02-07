-- Enable REPLICA IDENTITY FULL on tables table for better realtime event data
-- This ensures DELETE events include all column values, not just the primary key

ALTER TABLE tables REPLICA IDENTITY FULL;

-- NOTE: After running this SQL, you must also enable realtime for the 'tables' table
-- in the Supabase Dashboard:
-- 1. Go to Database > Replication
-- 2. Find the 'tables' table in the list
-- 3. Enable it for realtime
