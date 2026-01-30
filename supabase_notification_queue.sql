-- =====================================================
-- Notification Queue Table and Triggers
-- =====================================================
-- This creates a notification system that bypasses RLS issues
-- by explicitly notifying affected users before/after operations.

-- 1. Create the notification queue table
CREATE TABLE IF NOT EXISTS realtime_notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    event_type TEXT NOT NULL,  -- 'table_deleted', 'share_created', 'member_added'
    payload JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    processed BOOLEAN DEFAULT FALSE
);

-- Index for efficient polling of unprocessed notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user_unprocessed
ON realtime_notifications(user_id, processed) WHERE processed = FALSE;

-- Auto-cleanup old processed notifications (older than 24 hours)
CREATE INDEX IF NOT EXISTS idx_notifications_cleanup
ON realtime_notifications(created_at) WHERE processed = TRUE;

-- Enable RLS
ALTER TABLE realtime_notifications ENABLE ROW LEVEL SECURITY;

-- Users can view their own notifications
CREATE POLICY "Users can view their own notifications"
ON realtime_notifications FOR SELECT TO authenticated
USING (user_id = auth.uid());

-- Users can update their own notifications (mark as processed)
CREATE POLICY "Users can update their own notifications"
ON realtime_notifications FOR UPDATE TO authenticated
USING (user_id = auth.uid());

-- Allow authenticated users to insert notifications (for broadcast to other users)
-- This enables the client-side broadcast notification feature
CREATE POLICY "Authenticated users can insert notifications"
ON realtime_notifications FOR INSERT TO authenticated
WITH CHECK (true);

-- =====================================================
-- 2. Trigger: Notify shared users BEFORE table delete
-- =====================================================
-- Captures shared users BEFORE cascade delete removes their access

CREATE OR REPLACE FUNCTION notify_shared_users_before_delete()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert notification for each user who has access to this table
    INSERT INTO realtime_notifications (user_id, event_type, payload)
    SELECT
        shared_with_user_id,
        'table_deleted',
        jsonb_build_object(
            'table_id', OLD.id,
            'table_title', OLD.title,
            'deleted_by', auth.uid()
        )
    FROM table_shares
    WHERE table_id = OLD.id;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_notify_before_table_delete ON tables;

-- Create the trigger
CREATE TRIGGER trigger_notify_before_table_delete
    BEFORE DELETE ON tables
    FOR EACH ROW
    EXECUTE FUNCTION notify_shared_users_before_delete();

-- =====================================================
-- 3. Trigger: Notify user when table is shared with them
-- =====================================================

CREATE OR REPLACE FUNCTION notify_user_on_share()
RETURNS TRIGGER AS $$
DECLARE
    table_title TEXT;
BEGIN
    -- Get the table title for the notification
    SELECT title INTO table_title FROM tables WHERE id = NEW.table_id;

    -- Insert notification for the user receiving the share
    INSERT INTO realtime_notifications (user_id, event_type, payload)
    VALUES (
        NEW.shared_with_user_id,
        'share_created',
        jsonb_build_object(
            'table_id', NEW.table_id,
            'table_title', table_title,
            'permission', NEW.permission,
            'shared_by', auth.uid()
        )
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_notify_on_share ON table_shares;

-- Create the trigger
CREATE TRIGGER trigger_notify_on_share
    AFTER INSERT ON table_shares
    FOR EACH ROW
    EXECUTE FUNCTION notify_user_on_share();

-- =====================================================
-- 4. Cleanup function for old notifications
-- =====================================================
-- Run this periodically (via pg_cron or scheduled function)

CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM realtime_notifications
    WHERE processed = TRUE AND created_at < NOW() - INTERVAL '24 hours';

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 5. Enable realtime for notifications table
-- =====================================================
-- This allows clients to subscribe to their notifications

ALTER TABLE realtime_notifications REPLICA IDENTITY FULL;

-- NOTE: After running this SQL, enable realtime for 'realtime_notifications' in:
-- Supabase Dashboard > Database > Replication
