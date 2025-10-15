/*
  # Ajout de la table system_settings
  
  1. Nouvelle table
    - `system_settings` - Paramètres système de l'application
      - `id` (uuid, primary key)
      - `key` (text, unique) - Clé du paramètre
      - `value` (text) - Valeur du paramètre
      - `description` (text) - Description du paramètre
      - `updated_by` (uuid) - Utilisateur ayant modifié
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
  
  2. Sécurité
    - Enable RLS sur `system_settings`
    - Seuls les super admins peuvent modifier
    - Tous les utilisateurs authentifiés peuvent lire
  
  3. Données initiales
    - Paramètre `maintenance_mode` avec valeur par défaut `false`
*/

-- Créer la table system_settings
CREATE TABLE IF NOT EXISTS system_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key text NOT NULL UNIQUE,
  value text NOT NULL,
  description text DEFAULT '',
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Activer RLS
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- Politique de lecture pour tous les utilisateurs authentifiés
CREATE POLICY "Authenticated users can read system settings"
  ON system_settings FOR SELECT
  TO authenticated
  USING (true);

-- Politique d'écriture pour les super admins uniquement
CREATE POLICY "Super admins can manage system settings"
  ON system_settings FOR ALL
  TO authenticated
  USING (is_super_admin())
  WITH CHECK (is_super_admin());

-- Index sur la clé pour recherche rapide
CREATE INDEX IF NOT EXISTS idx_system_settings_key ON system_settings(key);

-- Trigger pour mettre à jour updated_at
CREATE TRIGGER update_system_settings_updated_at
  BEFORE UPDATE ON system_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Insérer le paramètre maintenance_mode par défaut
INSERT INTO system_settings (key, value, description)
VALUES ('maintenance_mode', 'false', 'Active ou désactive le mode maintenance de l''application')
ON CONFLICT (key) DO NOTHING;