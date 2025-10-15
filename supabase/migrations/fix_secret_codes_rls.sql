/*
  # Fix RLS policies for secret_codes table
  
  1. Changes
    - Drop existing restrictive policies
    - Add policy allowing authenticated users to create codes
    - Keep admin-only policies for management
    
  2. Security
    - Authenticated users can create their own codes
    - Only super admins can view/manage all codes
    - Users can view their own active codes
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Super admins can manage secret codes" ON secret_codes;
DROP POLICY IF EXISTS "Users can view active codes" ON secret_codes;

-- Allow authenticated users to create secret codes
CREATE POLICY "Authenticated users can create secret codes"
  ON secret_codes
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Allow users to view their own codes and active codes
CREATE POLICY "Users can view active secret codes"
  ON secret_codes
  FOR SELECT
  TO authenticated
  USING (
    is_active = true 
    OR is_super_admin()
  );

-- Super admins can update any code
CREATE POLICY "Super admins can update secret codes"
  ON secret_codes
  FOR UPDATE
  TO authenticated
  USING (is_super_admin())
  WITH CHECK (is_super_admin());

-- Super admins can delete any code
CREATE POLICY "Super admins can delete secret codes"
  ON secret_codes
  FOR DELETE
  TO authenticated
  USING (is_super_admin());

-- Grant necessary permissions
GRANT INSERT ON secret_codes TO authenticated;
GRANT SELECT ON secret_codes TO authenticated;
GRANT UPDATE ON secret_codes TO authenticated;
GRANT DELETE ON secret_codes TO authenticated;
