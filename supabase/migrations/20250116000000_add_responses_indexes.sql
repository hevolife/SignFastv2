/*
  # Optimisation des performances - Index sur la table responses

  1. Nouveaux Index
    - Index sur form_id pour les requêtes filtrées par formulaire
    - Index sur created_at pour le tri par date
    - Index composite (form_id, created_at) pour les requêtes combinées
    
  2. Performance
    - Réduit drastiquement le temps de requête
    - Optimise les COUNT et SELECT
    - Améliore la pagination
*/

-- Index sur form_id (pour les filtres par formulaire)
CREATE INDEX IF NOT EXISTS idx_responses_form_id 
ON responses(form_id);

-- Index sur created_at (pour le tri par date)
CREATE INDEX IF NOT EXISTS idx_responses_created_at 
ON responses(created_at DESC);

-- Index composite (form_id + created_at) pour les requêtes combinées
CREATE INDEX IF NOT EXISTS idx_responses_form_id_created_at 
ON responses(form_id, created_at DESC);

-- Analyse de la table pour mettre à jour les statistiques
ANALYZE responses;
