-- ============================================
-- Row-Level Security Policies for Tables App
-- ============================================

-- Enable RLS on all tables (if not already enabled)
ALTER TABLE tables ENABLE ROW LEVEL SECURITY;
ALTER TABLE cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE nudges ENABLE ROW LEVEL SECURITY;
ALTER TABLE table_shares ENABLE ROW LEVEL SECURITY;

-- ============================================
-- TABLES POLICIES
-- ============================================

-- Users can view tables they own or have been shared with
CREATE POLICY "Users can view their own tables"
ON tables FOR SELECT
TO authenticated
USING (owner_id = auth.uid());

CREATE POLICY "Users can view shared tables"
ON tables FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM table_shares
    WHERE table_shares.table_id = tables.id
    AND table_shares.shared_with_user_id = auth.uid()
  )
);

-- Users can insert their own tables
CREATE POLICY "Users can create tables"
ON tables FOR INSERT
TO authenticated
WITH CHECK (owner_id = auth.uid());

-- Users can update tables they own
CREATE POLICY "Users can update their own tables"
ON tables FOR UPDATE
TO authenticated
USING (owner_id = auth.uid());

-- Users can delete tables they own
CREATE POLICY "Users can delete their own tables"
ON tables FOR DELETE
TO authenticated
USING (owner_id = auth.uid());

-- ============================================
-- CARDS POLICIES
-- ============================================

-- Users can view cards from tables they have access to
CREATE POLICY "Users can view cards from accessible tables"
ON cards FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM tables
    WHERE tables.id = cards.table_id
    AND (
      tables.owner_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM table_shares
        WHERE table_shares.table_id = tables.id
        AND table_shares.shared_with_user_id = auth.uid()
      )
    )
  )
);

-- Users can insert cards into tables they have access to
CREATE POLICY "Users can create cards in accessible tables"
ON cards FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM tables
    WHERE tables.id = cards.table_id
    AND (
      tables.owner_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM table_shares
        WHERE table_shares.table_id = tables.id
        AND table_shares.shared_with_user_id = auth.uid()
        AND table_shares.permission = 'write'
      )
    )
  )
);

-- Users can update cards in tables they have access to
CREATE POLICY "Users can update cards in accessible tables"
ON cards FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM tables
    WHERE tables.id = cards.table_id
    AND (
      tables.owner_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM table_shares
        WHERE table_shares.table_id = tables.id
        AND table_shares.shared_with_user_id = auth.uid()
        AND table_shares.permission = 'write'
      )
    )
  )
);

-- Users can delete cards in tables they have access to
CREATE POLICY "Users can delete cards in accessible tables"
ON cards FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM tables
    WHERE tables.id = cards.table_id
    AND (
      tables.owner_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM table_shares
        WHERE table_shares.table_id = tables.id
        AND table_shares.shared_with_user_id = auth.uid()
        AND table_shares.permission = 'write'
      )
    )
  )
);

-- ============================================
-- COMMENTS POLICIES
-- ============================================

-- Users can view comments on cards from accessible tables
CREATE POLICY "Users can view comments on accessible cards"
ON comments FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM cards
    JOIN tables ON tables.id = cards.table_id
    WHERE cards.id = comments.card_id
    AND (
      tables.owner_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM table_shares
        WHERE table_shares.table_id = tables.id
        AND table_shares.shared_with_user_id = auth.uid()
      )
    )
  )
);

-- Users can create comments on accessible cards
CREATE POLICY "Users can create comments on accessible cards"
ON comments FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM cards
    JOIN tables ON tables.id = cards.table_id
    WHERE cards.id = comments.card_id
    AND (
      tables.owner_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM table_shares
        WHERE table_shares.table_id = tables.id
        AND table_shares.shared_with_user_id = auth.uid()
        AND table_shares.permission = 'write'
      )
    )
  )
);

-- Users can delete their own comments
CREATE POLICY "Users can delete their own comments"
ON comments FOR DELETE
TO authenticated
USING (author_name = (SELECT COALESCE(display_name, email) FROM profiles WHERE id = auth.uid()));

-- ============================================
-- NUDGES POLICIES
-- ============================================

-- Users can view nudges on accessible tables
CREATE POLICY "Users can view nudges on accessible tables"
ON nudges FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM tables
    WHERE tables.id = nudges.table_id
    AND (
      tables.owner_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM table_shares
        WHERE table_shares.table_id = tables.id
        AND table_shares.shared_with_user_id = auth.uid()
      )
    )
  )
);

-- Users can create nudges on accessible tables
CREATE POLICY "Users can create nudges on accessible tables"
ON nudges FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM tables
    WHERE tables.id = nudges.table_id
    AND (
      tables.owner_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM table_shares
        WHERE table_shares.table_id = tables.id
        AND table_shares.shared_with_user_id = auth.uid()
      )
    )
  )
);

-- ============================================
-- TABLE_SHARES POLICIES
-- ============================================

-- Users can view shares for tables they own
CREATE POLICY "Users can view shares for their tables"
ON table_shares FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM tables
    WHERE tables.id = table_shares.table_id
    AND tables.owner_id = auth.uid()
  )
);

-- Users can create shares for tables they own
CREATE POLICY "Users can create shares for their tables"
ON table_shares FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM tables
    WHERE tables.id = table_shares.table_id
    AND tables.owner_id = auth.uid()
  )
);

-- Users can delete shares for tables they own
CREATE POLICY "Users can delete shares for their tables"
ON table_shares FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM tables
    WHERE tables.id = table_shares.table_id
    AND tables.owner_id = auth.uid()
  )
);
