import { useState, useEffect } from 'react';
import { PDFTemplate } from '../types/pdf';
import { PDFTemplateService } from '../services/pdfTemplateService';
import { useAuth } from '../contexts/AuthContext';
import { useDemo } from '../contexts/DemoContext';
import { useDemoTemplates } from './useDemoForms';

export const usePDFTemplates = () => {
  const [templates, setTemplates] = useState<PDFTemplate[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [loading, setLoading] = useState(true);
  const { user } = useAuth();
  const { isDemoMode, demoTemplates } = useDemo();
  const demoTemplatesHook = useDemoTemplates();

  // Si on est en mode démo, utiliser les données de démo
  if (isDemoMode) {
    return demoTemplatesHook;
  }

  const fetchTemplates = async (page: number = 1, limit: number = 10) => {
    try {
      console.log('📄 [usePDFTemplates] ========== DÉBUT RÉCUPÉRATION ==========');
      console.log('📄 [usePDFTemplates] User:', user?.id);
      console.log('📄 [usePDFTemplates] Page:', page, 'Limit:', limit);
      
      if (user) {
        // L'utilisateur effectif est déjà géré par le contexte Auth
        const targetUserId = user.id;

        try {
          // Utilisateur connecté : récupérer ses templates depuis Supabase
          console.log('📄 [usePDFTemplates] Récupération templates pour:', targetUserId);
          const result = await PDFTemplateService.getUserTemplates(targetUserId, page, limit);
          
          console.log('📄 [usePDFTemplates] ========== RÉSULTAT ==========');
          console.log('📄 [usePDFTemplates] Templates trouvés:', result.templates.length);
          console.log('📄 [usePDFTemplates] Total count:', result.totalCount);
          console.log('📄 [usePDFTemplates] Templates:', JSON.stringify(result.templates, null, 2));
          
          setTemplates(result.templates);
          setTotalCount(result.totalCount);
          setTotalPages(result.totalPages);
        } catch (supabaseError) {
          console.warn('📄 [usePDFTemplates] Erreur Supabase templates:', supabaseError);
          // Vérifier si c'est une erreur de réseau
          if (supabaseError instanceof TypeError && supabaseError.message === 'Failed to fetch') {
            // Vous pouvez ajouter une notification toast ici si nécessaire
          }
          
          // Pas de fallback cache - données vides en cas d'erreur
          setTemplates([]);
          setTotalCount(0);
          setTotalPages(0);
        }
      } else {
        // Utilisateur non connecté : données vides
        console.log('📄 [usePDFTemplates] Pas d\'utilisateur connecté');
        setTemplates([]);
        setTotalCount(0);
        setTotalPages(0);
      }
    } catch (error) {
      console.error('📄 [usePDFTemplates] Erreur globale:', error);
      setTemplates([]);
      setTotalCount(0);
      setTotalPages(0);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (user) {
      fetchTemplates(1, 10);
    } else {
      setLoading(false);
    }
  }, [user]);

  return {
    templates,
    totalCount,
    totalPages,
    loading,
    refetch: fetchTemplates,
    fetchPage: fetchTemplates,
  };
};
