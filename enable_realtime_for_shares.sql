-- Enable Realtime for table_shares
-- This allows the app to receive real-time notifications when tables are shared with users

-- Set REPLICA IDENTITY to FULL to enable realtime subscriptions
ALTER TABLE table_shares REPLICA IDENTITY FULL;

-- Note: You also need to enable realtime in the Supabase Dashboard:
-- 1. Go to Database > Replication in your Supabase Dashboard
-- 2. Find "table_shares" in the list
-- 3. Toggle it ON to enable realtime subscriptions
