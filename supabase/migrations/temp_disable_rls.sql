-- ⚠️ TEMPORAIRE - Désactiver RLS pour tester
-- À RÉACTIVER après avoir trouvé le problème !

-- Désactiver RLS sur form_responses
ALTER TABLE form_responses DISABLE ROW LEVEL SECURITY;

-- Vérifier
DO $$
BEGIN
  RAISE NOTICE '⚠️ RLS DÉSACTIVÉ sur form_responses';
  RAISE NOTICE '🔓 Tous les utilisateurs peuvent maintenant insérer';
  RAISE NOTICE '⚠️ NE PAS LAISSER EN PRODUCTION !';
END $$;
