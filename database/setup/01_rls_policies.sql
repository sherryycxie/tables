-- ============================================
-- FIXED Row-Level Security Policies (No Circular Dependencies)
-- ============================================

-- Drop all existing policies first
DROP POLICY IF EXISTS "Users can view their own tables" ON tables;
DROP POLICY IF EXISTS "Users can view shared tables" ON tables;
DROP POLICY IF EXISTS "Users can create tables" ON tables;
DROP POLICY IF EXISTS "Users can update their own tables" ON tables;
DROP POLICY IF EXISTS "Users can delete their own tables" ON tables;

DROP POLICY IF EXISTS "Users can view cards from accessible tables" ON cards;
DROP POLICY IF EXISTS "Users can create cards in accessible tables" ON cards;
DROP POLICY IF EXISTS "Users can update cards in accessible tables" ON cards;
DROP POLICY IF EXISTS "Users can delete cards in accessible tables" ON cards;

DROP POLICY IF EXISTS "Users can view comments on accessible cards" ON comments;
DROP POLICY IF EXISTS "Users can create comments on accessible cards" ON comments;
DROP POLICY IF EXISTS "Users can delete their own comments" ON comments;

DROP POLICY IF EXISTS "Users can view nudges on accessible tables" ON nudges;
DROP POLICY IF EXISTS "Users can create nudges on accessible tables" ON nudges;

DROP POLICY IF EXISTS "Users can view shares for their tables" ON table_shares;
DROP POLICY IF EXISTS "Users can create shares for their tables" ON table_shares;
DROP POLICY IF EXISTS "Users can delete shares for their tables" ON table_shares;

-- Enable RLS on all tables
ALTER TABLE tables ENABLE ROW LEVEL SECURITY;
ALTER TABLE cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE nudges ENABLE ROW LEVEL SECURITY;
ALTER TABLE table_shares ENABLE ROW LEVEL SECURITY;

-- ============================================
-- TABLES POLICIES (Simplified - No Circular Dependencies)
-- ============================================

-- Users can view tables they own OR tables shared with them
-- Combined into one policy to avoid circular dependency
CREATE POLICY "Users can view accessible tables"
ON tables FOR SELECT
TO authenticated
USING (
  owner_id = auth.uid()
  OR id IN (
    SELECT table_id FROM table_shares
    WHERE shared_with_user_id = auth.uid()
  )
);

CREATE POLICY "Users can create tables"
ON tables FOR INSERT
TO authenticated
WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Users can update their own tables"
ON tables FOR UPDATE
TO authenticated
USING (owner_id = auth.uid());

CREATE POLICY "Users can delete their own tables"
ON tables FOR DELETE
TO authenticated
USING (owner_id = auth.uid());

-- ============================================
-- TABLE_SHARES POLICIES (Simplified - No Table Reference)
-- ============================================

-- Users can view shares for their own tables OR shares that involve them
CREATE POLICY "Users can view relevant shares"
ON table_shares FOR SELECT
TO authenticated
USING (
  -- Can see shares for tables they own (using direct owner lookup in subquery)
  table_id IN (SELECT id FROM tables WHERE owner_id = auth.uid())
  OR
  -- Can see shares where they are the recipient
  shared_with_user_id = auth.uid()
);

CREATE POLICY "Users can create shares for their tables"
ON table_shares FOR INSERT
TO authenticated
WITH CHECK (
  table_id IN (SELECT id FROM tables WHERE owner_id = auth.uid())
);

CREATE POLICY "Users can delete shares for their tables"
ON table_shares FOR DELETE
TO authenticated
USING (
  table_id IN (SELECT id FROM tables WHERE owner_id = auth.uid())
);

-- ============================================
-- CARDS POLICIES
-- ============================================

CREATE POLICY "Users can view cards from accessible tables"
ON cards FOR SELECT
TO authenticated
USING (
  table_id IN (
    SELECT id FROM tables
    WHERE owner_id = auth.uid()
    OR id IN (
      SELECT table_id FROM table_shares
      WHERE shared_with_user_id = auth.uid()
    )
  )
);

CREATE POLICY "Users can create cards in accessible tables"
ON cards FOR INSERT
TO authenticated
WITH CHECK (
  table_id IN (
    SELECT id FROM tables
    WHERE owner_id = auth.uid()
    OR id IN (
      SELECT table_id FROM table_shares
      WHERE shared_with_user_id = auth.uid()
      AND permission = 'write'
    )
  )
);

CREATE POLICY "Users can update cards in accessible tables"
ON cards FOR UPDATE
TO authenticated
USING (
  table_id IN (
    SELECT id FROM tables
    WHERE owner_id = auth.uid()
    OR id IN (
      SELECT table_id FROM table_shares
      WHERE shared_with_user_id = auth.uid()
      AND permission = 'write'
    )
  )
);

CREATE POLICY "Users can delete cards in accessible tables"
ON cards FOR DELETE
TO authenticated
USING (
  table_id IN (
    SELECT id FROM tables
    WHERE owner_id = auth.uid()
    OR id IN (
      SELECT table_id FROM table_shares
      WHERE shared_with_user_id = auth.uid()
      AND permission = 'write'
    )
  )
);

-- ============================================
-- COMMENTS POLICIES
-- ============================================

CREATE POLICY "Users can view comments on accessible cards"
ON comments FOR SELECT
TO authenticated
USING (
  card_id IN (
    SELECT c.id FROM cards c
    WHERE c.table_id IN (
      SELECT id FROM tables
      WHERE owner_id = auth.uid()
      OR id IN (
        SELECT table_id FROM table_shares
        WHERE shared_with_user_id = auth.uid()
      )
    )
  )
);

CREATE POLICY "Users can create comments on accessible cards"
ON comments FOR INSERT
TO authenticated
WITH CHECK (
  card_id IN (
    SELECT c.id FROM cards c
    WHERE c.table_id IN (
      SELECT id FROM tables
      WHERE owner_id = auth.uid()
      OR id IN (
        SELECT table_id FROM table_shares
        WHERE shared_with_user_id = auth.uid()
        AND permission = 'write'
      )
    )
  )
);

CREATE POLICY "Users can delete their own comments"
ON comments FOR DELETE
TO authenticated
USING (
  author_name = (SELECT COALESCE(display_name, email) FROM profiles WHERE id = auth.uid())
);

-- ============================================
-- NUDGES POLICIES
-- ============================================

CREATE POLICY "Users can view nudges on accessible tables"
ON nudges FOR SELECT
TO authenticated
USING (
  table_id IN (
    SELECT id FROM tables
    WHERE owner_id = auth.uid()
    OR id IN (
      SELECT table_id FROM table_shares
      WHERE shared_with_user_id = auth.uid()
    )
  )
);

CREATE POLICY "Users can create nudges on accessible tables"
ON nudges FOR INSERT
TO authenticated
WITH CHECK (
  table_id IN (
    SELECT id FROM tables
    WHERE owner_id = auth.uid()
    OR id IN (
      SELECT table_id FROM table_shares
      WHERE shared_with_user_id = auth.uid()
    )
  )
);
