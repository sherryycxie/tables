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

-- Example usage:
-- SELECT add_table_member('00000000-0000-0000-0000-000000000000'::uuid, 'Alice Smith');
