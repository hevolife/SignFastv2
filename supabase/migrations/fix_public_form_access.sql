/*
  # Fix Public Form Access
  
  1. Allow anonymous users to INSERT into form_responses
  2. Only allow if the form is published (is_published = true)
  3. Fix logo display for public forms
*/

-- ============================================
-- 1️⃣ AUTORISER LES SOUMISSIONS ANONYMES
-- ============================================

-- Drop existing INSERT policy if exists
DROP POLICY IF EXISTS "Anyone can submit responses to published forms" ON form_responses;

-- Create new policy for anonymous submissions
CREATE POLICY "Anyone can submit responses to published forms"
  ON form_responses
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM forms
      WHERE forms.id = form_responses.form_id
      AND forms.is_published = true
    )
  );

-- ============================================
-- 2️⃣ AUTORISER LA LECTURE DES PROFILS PUBLICS
-- ============================================

-- Drop existing SELECT policy if exists
DROP POLICY IF EXISTS "Anyone can view profiles for public forms" ON user_profiles;

-- Allow anonymous users to read user_profiles (for logo display)
CREATE POLICY "Anyone can view profiles for public forms"
  ON user_profiles
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- ============================================
-- 3️⃣ AUTORISER LA LECTURE DES FORMULAIRES PUBLICS
-- ============================================

-- Drop existing SELECT policy if exists
DROP POLICY IF EXISTS "Anyone can view published forms" ON forms;

-- Allow anonymous users to read published forms
CREATE POLICY "Anyone can view published forms"
  ON forms
  FOR SELECT
  TO anon, authenticated
  USING (is_published = true);

-- ============================================
-- 4️⃣ VÉRIFICATIONS
-- ============================================

-- Grant necessary permissions
GRANT SELECT ON forms TO anon;
GRANT SELECT ON user_profiles TO anon;
GRANT INSERT ON form_responses TO anon;

-- Verify policies
DO $$
BEGIN
  RAISE NOTICE '✅ Policies created successfully';
  RAISE NOTICE '📝 Anonymous users can now:';
  RAISE NOTICE '   - View published forms';
  RAISE NOTICE '   - View user profiles (for logos)';
  RAISE NOTICE '   - Submit form responses';
END $$;
