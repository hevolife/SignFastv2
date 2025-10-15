/*
  # Fix responses table issue
  
  1. Check if form_responses exists (from schema)
  2. Create responses view or rename table
  3. Update RLS policies
*/

-- Check if form_responses exists and create responses view
DO $$ 
BEGIN
  -- If form_responses exists, create a view named responses
  IF EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'form_responses'
  ) THEN
    -- Drop view if exists
    DROP VIEW IF EXISTS responses;
    
    -- Create view
    CREATE VIEW responses AS 
    SELECT * FROM form_responses;
    
    -- Grant permissions on view
    GRANT SELECT ON responses TO authenticated;
    
    RAISE NOTICE 'Created responses view from form_responses table';
  ELSE
    RAISE NOTICE 'form_responses table does not exist';
  END IF;
END $$;

-- Update is_super_admin function
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

-- Update forms RLS policies
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

-- Update form_responses RLS policies (the actual table)
DROP POLICY IF EXISTS "Super admins can view all responses" ON form_responses;

CREATE POLICY "Super admins can view all responses"
  ON form_responses
  FOR SELECT
  TO authenticated
  USING (is_super_admin());

-- Grant necessary permissions
GRANT SELECT ON forms TO authenticated;
GRANT SELECT ON pdf_templates TO authenticated;
GRANT SELECT ON user_profiles TO authenticated;
GRANT SELECT ON form_responses TO authenticated;
