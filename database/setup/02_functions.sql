-- Function to find a user by email (bypasses RLS for this specific use case)
-- This allows users to share tables with others by searching for their email
CREATE OR REPLACE FUNCTION find_user_by_email(search_email TEXT)
RETURNS TABLE (
  user_id UUID,
  user_email TEXT,
  display_name TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id as user_id,
    p.email as user_email,
    p.display_name
  FROM profiles p
  WHERE LOWER(p.email) = LOWER(search_email)
  LIMIT 1;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION find_user_by_email TO authenticated;
