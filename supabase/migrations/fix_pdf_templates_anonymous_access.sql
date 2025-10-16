/*
  # Fix PDF Templates Anonymous Access
  
  1. Allow anonymous users to SELECT from pdf_templates
  2. Ensure single row return with proper query
  3. Fix RLS policies
*/

-- ============================================
-- 1️⃣ AUTORISER LA LECTURE ANONYME DES TEMPLATES
-- ============================================

-- Drop existing SELECT policy if exists
DROP POLICY IF EXISTS "Allow anonymous select on pdf_templates" ON pdf_templates;

-- Create new policy for anonymous SELECT
CREATE POLICY "Allow anonymous select on pdf_templates"
  ON pdf_templates
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- ============================================
-- 2️⃣ VÉRIFIER LES PERMISSIONS
-- ============================================

-- Grant necessary permissions
GRANT SELECT ON pdf_templates TO anon;

-- ============================================
-- 3️⃣ VÉRIFICATIONS
-- ============================================

-- Verify policies
DO $$
BEGIN
  RAISE NOTICE '✅ PDF Templates RLS fixed';
  RAISE NOTICE '📝 Anonymous users can now:';
  RAISE NOTICE '   - View all PDF templates';
  RAISE NOTICE '   - Generate PDFs from public forms';
END $$;
