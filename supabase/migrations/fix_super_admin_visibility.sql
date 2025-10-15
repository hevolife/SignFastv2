/*
  # Fix super admin data visibility
  
  1. Diagnostics
    - Check if data exists in tables
    - Verify RLS policies
    - Check is_super_admin() function
    
  2. Changes
    - Update RLS policies to allow super admin full access
    - Ensure is_super_admin() function works correctly
*/

-- First, let's check if the is_super_admin function exists and works
CREATE OR REPLACE FUNCTION is_super_admin()
RETURNS boolean AS $$
BEGIN
  RETURN (
    SELECT email 
    FROM auth.users 
    WHERE id = auth.uid()
  ) IN ('admin@signfast.com', 'admin@signfast.pro')
  OR (
    SELECT email 
    FROM auth.users 
    WHERE id = auth.uid()
  ) LIKE '%@admin.signfast.com';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update forms RLS policies to allow super admin full access
DROP POLICY IF EXISTS "Users can view their own forms" ON forms;
DROP POLICY IF EXISTS "Super admins can view all forms" ON forms;

CREATE POLICY "Users can view their own forms"
  ON forms
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Super admins can view all forms"
  ON forms
  FOR SELECT
  TO authenticated
  USING (is_super_admin());

-- Update pdf_templates RLS policies
DROP POLICY IF EXISTS "Users can view their own templates" ON pdf_templates;
DROP POLICY IF EXISTS "Super admins can view all templates" ON pdf_templates;

CREATE POLICY "Users can view their own templates"
  ON pdf_templates
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Super admins can view all templates"
  ON pdf_templates
  FOR SELECT
  TO authenticated
  USING (is_super_admin());

-- Update user_profiles RLS policies
DROP POLICY IF EXISTS "Users can view their own profile" ON user_profiles;
DROP POLICY IF EXISTS "Super admins can view all profiles" ON user_profiles;

CREATE POLICY "Users can view their own profile"
  ON user_profiles
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Super admins can view all profiles"
  ON user_profiles
  FOR SELECT
  TO authenticated
  USING (is_super_admin());

-- Grant necessary permissions
GRANT SELECT ON forms TO authenticated;
GRANT SELECT ON pdf_templates TO authenticated;
GRANT SELECT ON user_profiles TO authenticated;
GRANT SELECT ON responses TO authenticated;

-- Add policy for responses
DROP POLICY IF EXISTS "Super admins can view all responses" ON responses;

CREATE POLICY "Super admins can view all responses"
  ON responses
  FOR SELECT
  TO authenticated
  USING (is_super_admin());
