/*
  # Fix DELETE operation for form_responses
  
  1. Add DELETE policies for form_responses
  2. Allow users to delete responses from their own forms
  3. Allow super admins to delete any response
*/

-- Drop existing DELETE policies if any
DROP POLICY IF EXISTS "Users can delete responses from their forms" ON form_responses;
DROP POLICY IF EXISTS "Super admins can delete any response" ON form_responses;

-- Allow users to delete responses from their own forms
CREATE POLICY "Users can delete responses from their forms"
  ON form_responses
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM forms
      WHERE forms.id = form_responses.form_id
      AND forms.user_id = auth.uid()
    )
  );

-- Allow super admins to delete any response
CREATE POLICY "Super admins can delete any response"
  ON form_responses
  FOR DELETE
  TO authenticated
  USING (is_super_admin());

-- Grant DELETE permission
GRANT DELETE ON form_responses TO authenticated;
