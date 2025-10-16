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
  const { isSubscribed, hasSecretCode } = useSubscription();
  const [limits, setLimits] = useState<Limits>({
    forms: { current: 0, max: FREE_LIMITS.forms },
    pdfTemplates: { current: 0, max: FREE_LIMITS.pdfTemplates },
    savedPdfs: { current: 0, max: FREE_LIMITS.savedPdfs },
  });
  const [loading, setLoading] = useState(true);

  const fetchLimits = useCallback(async () => {
    if (!user) {
      setLimits({
        forms: { current: 0, max: FREE_LIMITS.forms },
        pdfTemplates: { current: 0, max: FREE_LIMITS.pdfTemplates },
        savedPdfs: { current: 0, max: FREE_LIMITS.savedPdfs },
      });
      setLoading(false);
      return;
    }

    try {
      console.log('📊 Chargement des limites pour user:', user.id);

      // Vérifier si Supabase est configuré
      const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
      const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
      
      if (!supabaseUrl || !supabaseKey || supabaseUrl.includes('placeholder') || supabaseKey.includes('placeholder')) {
        console.warn('📊 Supabase non configuré, limites par défaut');
        setLimits({
          forms: { current: 0, max: FREE_LIMITS.forms },
          pdfTemplates: { current: 0, max: FREE_LIMITS.pdfTemplates },
          savedPdfs: { current: 0, max: FREE_LIMITS.savedPdfs },
        });
        setLoading(false);
        return;
      }

      // 🔥 ÉTAPE 1 : Récupérer les IDs des formulaires de l'utilisateur
      console.log('📊 Étape 1 : Récupération des formulaires...');
      const { data: userForms, error: formsError } = await supabase
        .from('forms')
        .select('id')
        .eq('user_id', user.id);

      if (formsError) {
        console.error('❌ Erreur récupération formulaires:', formsError);
        throw formsError;
      }

      const formIds = (userForms || []).map(f => f.id);
      console.log('📊 Formulaires trouvés:', formIds.length, 'IDs:', formIds);

      // 🔥 ÉTAPE 2 : Compter les réponses pour ces formulaires
      let pdfCount = 0;
      
      if (formIds.length > 0) {
        console.log('📊 Étape 2 : Comptage des réponses...');
        const { count, error: countError } = await supabase
          .from('form_responses')
          .select('id', { count: 'exact', head: true })
          .in('form_id', formIds);

        if (countError) {
          console.error('❌ Erreur comptage réponses:', countError);
        } else {
          pdfCount = count || 0;
          console.log('✅ Réponses comptées:', pdfCount);
        }
      } else {
        console.log('📊 Aucun formulaire, donc 0 réponse');
      }

      // 🔥 ÉTAPE 3 : Compter les templates
      console.log('📊 Étape 3 : Comptage des templates...');
      const { count: templatesCount, error: templatesError } = await supabase
        .from('pdf_templates')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', user.id);

      if (templatesError) {
        console.error('❌ Erreur comptage templates:', templatesError);
      }

      const isPremium = isSubscribed || hasSecretCode;

      const newLimits = {
        forms: {
          current: formIds.length,
          max: isPremium ? Infinity : FREE_LIMITS.forms,
        },
        pdfTemplates: {
          current: templatesCount || 0,
          max: isPremium ? Infinity : FREE_LIMITS.pdfTemplates,
        },
        savedPdfs: {
          current: pdfCount,
          max: isPremium ? Infinity : FREE_LIMITS.savedPdfs,
        },
      };

      console.log('✅ Limites finales:', {
        forms: `${newLimits.forms.current}/${isPremium ? '∞' : FREE_LIMITS.forms}`,
        templates: `${newLimits.pdfTemplates.current}/${isPremium ? '∞' : FREE_LIMITS.pdfTemplates}`,
        pdfs: `${newLimits.savedPdfs.current}/${isPremium ? '∞' : FREE_LIMITS.savedPdfs}`
      });

      setLimits(newLimits);

    } catch (error) {
      console.error('❌ Erreur chargement limites:', error);
      setLimits({
        forms: { current: 0, max: FREE_LIMITS.forms },
        pdfTemplates: { current: 0, max: FREE_LIMITS.pdfTemplates },
        savedPdfs: { current: 0, max: FREE_LIMITS.savedPdfs },
      });
    } finally {
      setLoading(false);
    }
  }, [user, isSubscribed, hasSecretCode]);

  useEffect(() => {
    fetchLimits();
  }, [fetchLimits]);

  const canCreate = useCallback((type: 'forms' | 'pdfTemplates' | 'savedPdfs'): boolean => {
    const limit = limits[type];
    return limit.max === Infinity || limit.current < limit.max;
  }, [limits]);

  const refreshLimits = useCallback(() => {
    return fetchLimits();
  }, [fetchLimits]);

  return {
    ...limits,
    loading,
    canCreate,
    refreshLimits,
  };
};
