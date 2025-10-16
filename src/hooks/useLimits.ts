import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';
import { useAuth } from '../contexts/AuthContext';
import { useSubscription } from './useSubscription';

interface Limits {
  forms: { current: number; max: number };
  pdfTemplates: { current: number; max: number };
  savedPdfs: { current: number; max: number };
}

const FREE_LIMITS = {
  forms: 3,
  pdfTemplates: 1,
  savedPdfs: 10,
};

export const useLimits = () => {
  const { user } = useAuth();
  const { isSubscribed, hasSecretCode, secretCodeType, loading: subscriptionLoading } = useSubscription();
  const [limits, setLimits] = useState<Limits>({
    forms: { current: 0, max: FREE_LIMITS.forms },
    pdfTemplates: { current: 0, max: FREE_LIMITS.pdfTemplates },
    savedPdfs: { current: 0, max: FREE_LIMITS.savedPdfs },
  });
  const [loading, setLoading] = useState(true);

  const fetchLimits = useCallback(async () => {
    console.log('📊 [useLimits] ========== DÉBUT fetchLimits ==========');
    console.log('📊 [useLimits] subscriptionLoading:', subscriptionLoading);
    console.log('📊 [useLimits] isSubscribed:', isSubscribed);
    console.log('📊 [useLimits] hasSecretCode:', hasSecretCode);
    console.log('📊 [useLimits] secretCodeType:', secretCodeType);

    // 🔥 ATTENDRE que useSubscription termine son chargement
    if (subscriptionLoading) {
      console.log('⏳ [useLimits] En attente de useSubscription...');
      return;
    }

    if (!user) {
      console.log('📊 [useLimits] Pas d\'utilisateur');
      setLimits({
        forms: { current: 0, max: FREE_LIMITS.forms },
        pdfTemplates: { current: 0, max: FREE_LIMITS.pdfTemplates },
        savedPdfs: { current: 0, max: FREE_LIMITS.savedPdfs },
      });
      setLoading(false);
      return;
    }

    try {
      // Vérifier si Supabase est configuré
      const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
      const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
      
      if (!supabaseUrl || !supabaseKey || supabaseUrl.includes('placeholder') || supabaseKey.includes('placeholder')) {
        console.warn('📊 [useLimits] Supabase non configuré');
        setLimits({
          forms: { current: 0, max: FREE_LIMITS.forms },
          pdfTemplates: { current: 0, max: FREE_LIMITS.pdfTemplates },
          savedPdfs: { current: 0, max: FREE_LIMITS.savedPdfs },
        });
        setLoading(false);
        return;
      }

      // 🔥 VÉRIFIER l'accès premium avec les valeurs ACTUELLES
      const isPremium = isSubscribed || 
                       hasSecretCode || 
                       secretCodeType === 'lifetime' || 
                       secretCodeType === 'unlimited';

      console.log('📊 [useLimits] ========== VÉRIFICATION PREMIUM ==========');
      console.log('📊 [useLimits] isPremium:', isPremium);
      console.log('📊 [useLimits] Détails:', {
        isSubscribed,
        hasSecretCode,
        secretCodeType
      });

      // 🔥 Si premium, retourner des limites infinies SANS compter
      if (isPremium) {
        console.log('✅ [useLimits] ========== UTILISATEUR PREMIUM ==========');
        console.log('✅ [useLimits] Limites infinies appliquées');
        setLimits({
          forms: { current: 0, max: Infinity },
          pdfTemplates: { current: 0, max: Infinity },
          savedPdfs: { current: 0, max: Infinity },
        });
        setLoading(false);
        return;
      }

      // 🔥 Sinon, compter les ressources pour utilisateurs gratuits
      console.log('📊 [useLimits] Utilisateur gratuit, comptage ressources...');

      // Récupérer les IDs des formulaires
      const { data: userForms, error: formsError } = await supabase
        .from('forms')
        .select('id')
        .eq('user_id', user.id);

      if (formsError) {
        console.error('❌ [useLimits] Erreur formulaires:', formsError);
        throw formsError;
      }

      const formIds = (userForms || []).map(f => f.id);
      console.log('📊 [useLimits] Formulaires:', formIds.length);

      // Compter les réponses
      let pdfCount = 0;
      if (formIds.length > 0) {
        const { count, error: countError } = await supabase
          .from('form_responses')
          .select('id', { count: 'exact', head: true })
          .in('form_id', formIds);

        if (countError) {
          console.error('❌ [useLimits] Erreur réponses:', countError);
        } else {
          pdfCount = count || 0;
          console.log('📊 [useLimits] Réponses:', pdfCount);
        }
      }

      // Compter les templates
      const { count: templatesCount, error: templatesError } = await supabase
        .from('pdf_templates')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', user.id);

      if (templatesError) {
        console.error('❌ [useLimits] Erreur templates:', templatesError);
      }

      const newLimits = {
        forms: {
          current: formIds.length,
          max: FREE_LIMITS.forms,
        },
        pdfTemplates: {
          current: templatesCount || 0,
          max: FREE_LIMITS.pdfTemplates,
        },
        savedPdfs: {
          current: pdfCount,
          max: FREE_LIMITS.savedPdfs,
        },
      };

      console.log('✅ [useLimits] Limites finales (gratuit):', newLimits);
      setLimits(newLimits);

    } catch (error) {
      console.error('❌ [useLimits] Erreur:', error);
      setLimits({
        forms: { current: 0, max: FREE_LIMITS.forms },
        pdfTemplates: { current: 0, max: FREE_LIMITS.pdfTemplates },
        savedPdfs: { current: 0, max: FREE_LIMITS.savedPdfs },
      });
    } finally {
      setLoading(false);
    }
  }, [user, isSubscribed, hasSecretCode, secretCodeType, subscriptionLoading]);

  useEffect(() => {
    fetchLimits();
  }, [fetchLimits]);

  const canCreate = useCallback((type: 'forms' | 'pdfTemplates' | 'savedPdfs'): boolean => {
    const limit = limits[type];
    const canCreateResource = limit.max === Infinity || limit.current < limit.max;
    console.log(`📊 [useLimits] canCreate(${type}):`, {
      current: limit.current,
      max: limit.max,
      canCreate: canCreateResource
    });
    return canCreateResource;
  }, [limits]);

  const refreshLimits = useCallback(() => {
    return fetchLimits();
  }, [fetchLimits]);

  return {
    ...limits,
    loading: loading || subscriptionLoading,
    canCreate,
    refreshLimits,
  };
};
