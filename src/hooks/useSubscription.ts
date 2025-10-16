import { useState, useEffect } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { useDemo } from '../contexts/DemoContext';
import { supabase } from '../lib/supabase';

export interface SubscriptionData {
  isSubscribed: boolean;
  subscriptionStatus: string | null;
  priceId: string | null;
  currentPeriodEnd: number | null;
  cancelAtPeriodEnd: boolean;
  hasSecretCode: boolean;
  secretCodeType: string | null;
  secretCodeExpiresAt: string | null;
  loading: boolean;
}

export const useSubscription = () => {
  const { user } = useAuth();
  const { isDemoMode } = useDemo();
  const [subscription, setSubscription] = useState<SubscriptionData>({
    isSubscribed: false,
    subscriptionStatus: null,
    priceId: null,
    currentPeriodEnd: null,
    cancelAtPeriodEnd: false,
    hasSecretCode: false,
    secretCodeType: null,
    secretCodeExpiresAt: null,
    loading: true,
  });

  useEffect(() => {
    if (user) {
      fetchSubscription();
    } else {
      setSubscription({
        isSubscribed: false,
        subscriptionStatus: null,
        priceId: null,
        currentPeriodEnd: null,
        cancelAtPeriodEnd: false,
        hasSecretCode: false,
        secretCodeType: null,
        secretCodeExpiresAt: null,
        loading: false,
      });
    }
  }, [user, isDemoMode]);

  const fetchSubscription = async () => {
    try {
      console.log('🔍 [useSubscription] ========== DÉBUT VÉRIFICATION ==========');
      console.log('🔍 [useSubscription] User ID:', user?.id);

      // En mode démo, simuler un abonnement à vie
      if (isDemoMode) {
        console.log('🎭 [useSubscription] Mode démo activé');
        setSubscription({
          isSubscribed: true,
          subscriptionStatus: 'active',
          priceId: null,
          currentPeriodEnd: null,
          cancelAtPeriodEnd: false,
          hasSecretCode: true,
          secretCodeType: 'lifetime',
          secretCodeExpiresAt: null,
          loading: false,
        });
        return;
      }

      // Vérifier si Supabase est configuré
      const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
      const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
      
      if (!supabaseUrl || !supabaseKey || supabaseUrl.includes('placeholder') || supabaseKey.includes('placeholder')) {
        console.warn('⚠️ [useSubscription] Supabase non configuré');
        setSubscription({
          isSubscribed: false,
          subscriptionStatus: null,
          priceId: null,
          currentPeriodEnd: null,
          cancelAtPeriodEnd: false,
          hasSecretCode: false,
          secretCodeType: null,
          secretCodeExpiresAt: null,
          loading: false,
        });
        return;
      }

      // Déterminer l'utilisateur cible (gestion impersonation)
      let targetUserId = user.id;
      const impersonationData = localStorage.getItem('admin_impersonation');
      if (impersonationData) {
        try {
          const data = JSON.parse(impersonationData);
          targetUserId = data.target_user_id;
          console.log('👤 [useSubscription] Impersonation:', targetUserId);
        } catch (error) {
          console.error('❌ [useSubscription] Erreur parsing impersonation:', error);
        }
      }

      // 🔥 ÉTAPE 1 : Vérifier les codes secrets en PREMIER
      console.log('🔑 [useSubscription] ========== ÉTAPE 1 : CODES SECRETS ==========');
      let hasActiveSecretCode = false;
      let secretCodeType = null;
      let secretCodeExpiresAt = null;
      
      try {
        // Récupérer les codes secrets actifs de l'utilisateur
        const { data: userSecretCodes, error: secretCodesError } = await supabase
          .from('user_secret_codes')
          .select(`
            expires_at,
            activated_at,
            secret_codes!inner (
              id,
              type,
              is_active
            )
          `)
          .eq('user_id', targetUserId)
          .eq('secret_codes.is_active', true)
          .order('activated_at', { ascending: false });

        console.log('🔑 [useSubscription] Requête codes terminée');
        console.log('🔑 [useSubscription] Erreur?', secretCodesError);
        console.log('🔑 [useSubscription] Données brutes:', JSON.stringify(userSecretCodes, null, 2));

        if (secretCodesError) {
          console.error('❌ [useSubscription] Erreur récupération codes:', secretCodesError);
        } else if (userSecretCodes && userSecretCodes.length > 0) {
          console.log('🔑 [useSubscription] Codes trouvés:', userSecretCodes.length);
          
          // Vérifier chaque code actif
          for (const codeData of userSecretCodes) {
            const secretCode = codeData.secret_codes;
            
            console.log('🔑 [useSubscription] Analyse code:', {
              codeData: JSON.stringify(codeData, null, 2),
              secretCode: JSON.stringify(secretCode, null, 2)
            });
            
            if (!secretCode) {
              console.log('⚠️ [useSubscription] Code sans détails, skip');
              continue;
            }
            
            const codeType = secretCode.type;
            const userExpiresAt = codeData.expires_at;
            
            console.log('🔑 [useSubscription] Type de code:', codeType);
            console.log('🔑 [useSubscription] Expire le:', userExpiresAt);
            console.log('🔑 [useSubscription] Est actif:', secretCode.is_active);
            
            // 🔥 CORRECTION : Accepter 'lifetime' ET 'unlimited'
            if (codeType === 'lifetime' || codeType === 'unlimited') {
              hasActiveSecretCode = true;
              secretCodeType = codeType;
              secretCodeExpiresAt = null;
              console.log('✅ [useSubscription] ========== CODE À VIE/ILLIMITÉ TROUVÉ ! ==========');
              console.log('✅ [useSubscription] Type:', codeType);
              break;
            } else if (codeType === 'monthly') {
              if (!userExpiresAt || new Date(userExpiresAt) > new Date()) {
                hasActiveSecretCode = true;
                secretCodeType = codeType;
                secretCodeExpiresAt = userExpiresAt;
                console.log('✅ [useSubscription] Code mensuel valide trouvé !');
                break;
              } else {
                console.log('⏰ [useSubscription] Code mensuel expiré');
              }
            }
          }
        } else {
          console.log('📭 [useSubscription] Aucun code secret trouvé');
        }
      } catch (secretCodeError) {
        console.error('❌ [useSubscription] Erreur vérification codes:', secretCodeError);
      }

      console.log('🔑 [useSubscription] ========== RÉSULTAT CODES ==========');
      console.log('🔑 [useSubscription] hasActiveSecretCode:', hasActiveSecretCode);
      console.log('🔑 [useSubscription] secretCodeType:', secretCodeType);

      // 🔥 ÉTAPE 2 : Vérifier l'abonnement Stripe seulement si pas de code secret
      let stripeSubscription = null;
      if (!hasActiveSecretCode) {
        console.log('💳 [useSubscription] ========== ÉTAPE 2 : STRIPE ==========');
        try {
          const { data: customerData, error: customerError } = await supabase
            .from('stripe_customers')
            .select('customer_id')
            .eq('user_id', targetUserId)
            .maybeSingle();

          if (customerError) {
            console.error('❌ [useSubscription] Erreur customer:', customerError);
          } else if (customerData) {
            const { data: stripeData, error: stripeError } = await supabase
              .from('stripe_subscriptions')
              .select('*')
              .eq('customer_id', customerData.customer_id)
              .maybeSingle();

            if (stripeError) {
              console.error('❌ [useSubscription] Erreur subscription:', stripeError);
            } else {
              stripeSubscription = stripeData;
              console.log('💳 [useSubscription] Stripe subscription:', stripeSubscription?.status);
            }
          }
        } catch (stripeError) {
          console.error('❌ [useSubscription] Erreur Stripe:', stripeError);
        }
      } else {
        console.log('⏭️ [useSubscription] Code secret actif, skip Stripe');
      }

      // 🔥 ÉTAPE 3 : Déterminer le statut final
      const hasStripeAccess = stripeSubscription && 
        (stripeSubscription.status === 'active' || 
         stripeSubscription.status === 'trialing');
      
      const isSubscribed = hasStripeAccess || hasActiveSecretCode;

      const finalState = {
        isSubscribed,
        subscriptionStatus: stripeSubscription?.status || null,
        priceId: stripeSubscription?.price_id || null,
        currentPeriodEnd: stripeSubscription?.current_period_end || null,
        cancelAtPeriodEnd: stripeSubscription?.cancel_at_period_end || false,
        hasSecretCode: hasActiveSecretCode,
        secretCodeType,
        secretCodeExpiresAt,
        loading: false,
      };
      
      console.log('✅ [useSubscription] ========== ÉTAT FINAL ==========');
      console.log('✅ [useSubscription] isSubscribed:', finalState.isSubscribed);
      console.log('✅ [useSubscription] hasSecretCode:', finalState.hasSecretCode);
      console.log('✅ [useSubscription] secretCodeType:', finalState.secretCodeType);
      console.log('✅ [useSubscription] stripeStatus:', finalState.subscriptionStatus);
      console.log('✅ [useSubscription] ========================================');
      
      setSubscription(finalState);

    } catch (error) {
      console.error('❌ [useSubscription] Erreur globale:', error);
      setSubscription({
        isSubscribed: false,
        subscriptionStatus: null,
        priceId: null,
        currentPeriodEnd: null,
        cancelAtPeriodEnd: false,
        hasSecretCode: false,
        secretCodeType: null,
        secretCodeExpiresAt: null,
        loading: false,
      });
    }
  };

  const refreshSubscription = () => {
    if (user) {
      fetchSubscription();
    }
  };

  return {
    ...subscription,
    refreshSubscription,
  };
};
