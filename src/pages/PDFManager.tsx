import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { Link } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { formatDateTimeFR } from '../utils/dateFormatter';
import { useLimits } from '../hooks/useLimits';
import { useSubscription } from '../hooks/useSubscription';
import { useAuth } from '../contexts/AuthContext';
import { useOptimizedForms } from '../hooks/useOptimizedForms';
import { SubscriptionBanner } from '../components/subscription/SubscriptionBanner';
import { LimitReachedModal } from '../components/subscription/LimitReachedModal';
import { stripeConfig } from '../stripe-config';
import { Button } from '../components/ui/Button';
import { Card, CardContent, CardHeader } from '../components/ui/Card';
import { Input } from '../components/ui/Input';
import { FileText, Download, Trash2, Search, Calendar, HardDrive, RefreshCw, Lock, Crown, ArrowLeft, ArrowRight, Sparkles, Activity, Eye, User, Wifi, WifiOff } from 'lucide-react';
import { X } from 'lucide-react';
import toast from 'react-hot-toast';

interface FormResponsePDF {
  id: string;
  form_id: string;
  form_title: string;
  form_description: string;
  response_data: Record<string, any>;
  created_at: string;
  ip_address?: string;
  user_agent?: string;
  pdf_template_id?: string;
  template_name?: string;
  user_name?: string;
}

// Composant PDFCard optimisé avec key stable
const PDFCard: React.FC<{
  pdf: FormResponsePDF;
  index: number;
  onView: (pdf: FormResponsePDF) => void;
  onDownload: (pdf: FormResponsePDF) => void;
  onDelete: (id: string, formTitle: string) => void;
  isLocked: boolean;
  isGenerating: boolean;
}> = React.memo(({ pdf, index, onView, onDownload, onDelete, isLocked, isGenerating }) => {
  const getUserName = useCallback(() => {
    try {
      const data = typeof pdf.response_data === 'string' ? JSON.parse(pdf.response_data) : pdf.response_data;
      const firstName = data?.['Prénom'] || data?.['prénom'] || data?.['Prenom'] || data?.['prenom'] || 
                      data?.['first_name'] || data?.['firstName'] || data?.['nom_complet']?.split(' ')[0] || '';
      const lastName = data?.['Nom'] || data?.['nom'] || data?.['Nom de famille'] || data?.['nom_de_famille'] || 
                     data?.['last_name'] || data?.['lastName'] || data?.['nom_complet']?.split(' ').slice(1).join(' ') || '';
      
      if (firstName && lastName) {
        return `${firstName} ${lastName}`;
      }
      if (data?.['nom_complet'] || data?.['Nom complet'] || data?.['nomComplet']) {
        return data['nom_complet'] || data['Nom complet'] || data['nomComplet'];
      }
      if (firstName) return firstName;
      if (lastName) return lastName;
      return pdf.user_name || `PDF #${pdf.id.slice(-8)}`;
    } catch {
      return pdf.user_name || `PDF #${pdf.id.slice(-8)}`;
    }
  }, [pdf.response_data, pdf.user_name, pdf.id]);

  return (
    <Card className="group bg-white/80 backdrop-blur-sm border-0 shadow-xl hover:shadow-2xl transition-all duration-300 hover:-translate-y-1 h-full">
      <CardHeader>
        <div className="flex justify-between items-start">
          <div className="flex items-center space-x-4 mb-3">
            <div className="w-12 h-12 bg-gradient-to-br from-green-500 to-emerald-600 rounded-2xl flex items-center justify-center shadow-lg group-hover:scale-110 transition-transform">
              <span className="text-white text-lg">📄</span>
            </div>
            <div>
              <h3 className="text-lg sm:text-xl font-bold text-gray-900 dark:text-white">
                {getUserName()}
              </h3>
              <p className="text-sm text-gray-600 dark:text-gray-400 line-clamp-2 font-medium">
                {pdf.form_title}
              </p>
            </div>
          </div>
          {isLocked && (
            <div className="flex items-center justify-center w-8 h-8 bg-red-100 dark:bg-red-900/30 rounded-full">
              <Lock className="h-4 w-4 text-red-600 dark:text-red-400" />
            </div>
          )}
        </div>
      </CardHeader>
      <CardContent>
        <div className="flex flex-wrap gap-2 mb-4">
          <span className="text-xs bg-gradient-to-r from-green-100 to-emerald-100 text-green-800 px-3 py-1 rounded-full font-semibold shadow-sm dark:from-green-900/30 dark:to-emerald-900/30 dark:text-green-300">
            {pdf.template_name || 'PDF Simple'}
          </span>
          <span className="text-xs text-gray-500 dark:text-gray-400 bg-gray-100 dark:bg-gray-800 px-3 py-1 rounded-full font-semibold">
            {formatDateTimeFR(pdf.created_at)}
          </span>
        </div>
        
        <div className="flex items-center gap-2 flex-wrap">
          <Button 
            variant="ghost" 
            size="sm" 
            onClick={() => onDownload(pdf)}
            className="flex-1 flex items-center justify-center space-x-1 bg-gradient-to-r from-green-500 to-emerald-500 text-white hover:from-green-600 hover:to-emerald-600 shadow-lg hover:shadow-xl transition-all duration-300 font-semibold rounded-xl"
            disabled={isLocked || isGenerating}
          >
            {isGenerating ? (
              <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
            ) : (
              <Download className="h-4 w-4" />
            )}
            <span className="hidden sm:inline">
              {isGenerating ? 'Génération...' : 'Générer PDF'}
            </span>
          </Button>
          
          <Button
            variant="ghost"
            size="sm"
            onClick={() => onView(pdf)}
            className="bg-gradient-to-r from-blue-500 to-indigo-500 text-white hover:from-blue-600 hover:to-indigo-600 shadow-lg hover:shadow-xl transition-all duration-300 font-semibold rounded-xl"
            title="Voir les détails de la réponse"
            disabled={isLocked}
          >
            <Eye className="h-4 w-4" />
          </Button>
          
          <Button
            variant="ghost"
            size="sm"
            onClick={() => onDelete(pdf.id, pdf.form_title)}
            className="bg-gradient-to-r from-red-500 to-pink-500 text-white hover:from-red-600 hover:to-pink-600 shadow-lg hover:shadow-xl transition-all duration-300 font-semibold rounded-xl"
            title="Supprimer la réponse"
            disabled={isLocked}
          >
            <Trash2 className="h-4 w-4" />
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}, (prevProps, nextProps) => {
  // Comparaison personnalisée pour éviter les re-renders inutiles
  return (
    prevProps.pdf.id === nextProps.pdf.id &&
    prevProps.isLocked === nextProps.isLocked &&
    prevProps.isGenerating === nextProps.isGenerating
  );
});

PDFCard.displayName = 'PDFCard';

export const PDFManager: React.FC = () => {
  const { user } = useAuth();
  const { forms } = useOptimizedForms();
  const [responses, setResponses] = useState<FormResponsePDF[]>([]);
  const [loading, setLoading] = useState(false);
  const [totalCount, setTotalCount] = useState(0);
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage] = useState(12);
  const { isSubscribed, hasSecretCode } = useSubscription();
  const { savedPdfs: savedPdfsLimits, refreshLimits } = useLimits();
  const [showLimitModal, setShowLimitModal] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [sortBy, setSortBy] = useState<'date' | 'form' | 'user'>('date');
  const [selectedFormFilter, setSelectedFormFilter] = useState<string>('all');
  const [generatingPdf, setGeneratingPdf] = useState<string | null>(null);
  const [isRealTimeEnabled, setIsRealTimeEnabled] = useState(true);
  const [lastUpdateTime, setLastUpdateTime] = useState<Date>(new Date());
  const [newResponsesCount, setNewResponsesCount] = useState(0);
  const [selectedResponseForDetails, setSelectedResponseForDetails] = useState<FormResponsePDF | null>(null);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const product = stripeConfig.products[0];

  const loadFormResponses = useCallback(async (silent: boolean = false) => {
    if (!user) {
      setResponses([]);
      setTotalCount(0);
      setLoading(false);
      return;
    }

    if (!silent) {
      setLoading(true);
    }
    
    try {
      const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
      const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
      
      if (!supabaseUrl || !supabaseKey || supabaseUrl.includes('placeholder') || supabaseKey.includes('placeholder')) {
        setResponses([]);
        setTotalCount(0);
        if (!silent) {
          setLoading(false);
        }
        return;
      }

      const userFormIds = forms.map(form => form.id);
      
      if (userFormIds.length === 0) {
        if (!silent) {
          setLoading(false);
        }
        return;
      }

      const { count, error: countError } = await supabase
        .from('responses')
        .select('id', { count: 'exact', head: true })
        .in('form_id', userFormIds);

      if (countError) {
        setTotalCount(0);
      } else {
        setTotalCount(count || 0);
      }

      const offset = (currentPage - 1) * itemsPerPage;
      const { data: responsesData, error } = await supabase
        .from('responses')
        .select('*')
        .in('form_id', userFormIds)
        .range(offset, offset + itemsPerPage - 1)
        .order('created_at', { ascending: false });

      if (error) {
        setResponses([]);
        return;
      }

      const enrichedResponses: FormResponsePDF[] = (responsesData || []).map(response => {
        const form = forms.find(f => f.id === response.form_id);
        
        const extractUserName = (data: Record<string, any>): string => {
          if (!data || typeof data !== 'object') return '';

          const nameKeys = Object.keys(data).filter(key => {
            const keyLower = key.toLowerCase();
            return keyLower.includes('nom') || 
                   keyLower.includes('name') || 
                   keyLower.includes('prenom') ||
                   keyLower.includes('prénom') ||
                   keyLower.includes('first') ||
                   keyLower.includes('last');
          });

          let firstName = '';
          let lastName = '';
          let fullName = '';

          for (const key of nameKeys) {
            const value = data[key];
            if (typeof value === 'string' && value.trim()) {
              const keyLower = key.toLowerCase();
              
              if (keyLower.includes('complet') || keyLower.includes('full')) {
                fullName = value.trim();
                break;
              } else if (keyLower.includes('prenom') || keyLower.includes('prénom') || keyLower.includes('first')) {
                firstName = value.trim();
              } else if (keyLower.includes('nom') && !keyLower.includes('prenom') && !keyLower.includes('prénom')) {
                lastName = value.trim();
              }
            }
          }

          if (fullName) return fullName;
          if (firstName && lastName) return `${firstName} ${lastName}`;
          if (firstName) return firstName;
          if (lastName) return lastName;

          const emailKeys = Object.keys(data).filter(key => 
            key.toLowerCase().includes('email') || key.toLowerCase().includes('mail')
          );
          
          for (const key of emailKeys) {
            const email = data[key];
            if (typeof email === 'string' && email.includes('@')) {
              const emailPart = email.split('@')[0];
              if (emailPart.includes('.')) {
                return emailPart.split('.').map(part => 
                  part.charAt(0).toUpperCase() + part.slice(1).toLowerCase()
                ).join(' ');
              }
              return emailPart.charAt(0).toUpperCase() + emailPart.slice(1).toLowerCase();
            }
          }

          return '';
        };

        const userName = extractUserName(response.data);

        return {
          id: response.id,
          form_id: response.form_id,
          form_title: form?.title || 'Formulaire supprimé',
          form_description: form?.description || '',
          response_data: response.data,
          created_at: response.created_at,
          ip_address: response.ip_address,
          user_agent: response.user_agent,
          pdf_template_id: form?.settings?.pdfTemplateId,
          template_name: form?.settings?.pdfTemplateId ? 'Template personnalisé' : 'PDF Simple',
          user_name: userName,
        };
      });

      setResponses(enrichedResponses);
      setLastUpdateTime(new Date());
      
    } catch (error) {
      setResponses([]);
      setTotalCount(0);
    } finally {
      if (!silent) {
        setLoading(false);
      }
    }
  }, [user, forms, currentPage, itemsPerPage]);

  useEffect(() => {
    if (user && forms.length > 0) {
      loadFormResponses();
    }
    
    const autoRefreshInterval = setInterval(() => {
      if (isRealTimeEnabled) {
        loadFormResponses(true);
      }
    }, 30000);
    
    return () => clearInterval(autoRefreshInterval);
  }, [user, forms, loadFormResponses, isRealTimeEnabled]);

  useEffect(() => {
    if (!user || !isRealTimeEnabled) return;

    const userFormIds = forms.map(form => form.id);
    
    if (userFormIds.length === 0) {
      return;
    }

    const channel = supabase
      .channel('pdf_storage_responses')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'responses',
          filter: `form_id=in.(${userFormIds.join(',')})`
        },
        (payload) => {
          setNewResponsesCount(prev => prev + 1);
          setLastUpdateTime(new Date());
          
          setTimeout(() => {
            loadFormResponses(true);
            setNewResponsesCount(0);
          }, 2000);
          
          toast.success('📄 Nouvelle réponse reçue ! Actualisation...', {
            duration: 3000,
            icon: '🆕'
          });
        }
      )
      .on(
        'postgres_changes',
        {
          event: 'DELETE',
          schema: 'public',
          table: 'responses',
          filter: `form_id=in.(${userFormIds.join(',')})`
        },
        (payload) => {
          setLastUpdateTime(new Date());
          
          setTimeout(() => {
            loadFormResponses(true);
          }, 1000);
          
          toast.info('📄 Réponse supprimée, actualisation...', {
            duration: 2000
          });
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [user, forms, isRealTimeEnabled, loadFormResponses]);

  const generateAndDownloadPDF = useCallback(async (response: FormResponsePDF) => {
    if (!response) return;

    setGeneratingPdf(response.id);
    
    try {
      const toastId = toast.loading('📄 Génération du PDF en cours...');

      const { data: fullResponse, error: responseError } = await supabase
        .from('responses')
        .select('data')
        .eq('id', response.id)
        .single();

      if (responseError) {
        throw new Error('Impossible de récupérer les données complètes de la réponse');
      }

      const fullResponseData = fullResponse.data;

      if (response.pdf_template_id) {
        await generatePDFWithTemplate({ ...response, response_data: fullResponseData });
      } else {
        await generateSimplePDF({ ...response, response_data: fullResponseData });
      }

      toast.success('📄 PDF généré et téléchargé avec succès !', { id: toastId });
      
    } catch (error) {
      console.error('❌ Erreur génération PDF:', error);
      toast.error('❌ Erreur lors de la génération du PDF');
    } finally {
      setGeneratingPdf(null);
    }
  }, []);

  const generatePDFWithTemplate = async (response: FormResponsePDF) => {
    try {
      const { data: template, error: templateError } = await supabase
        .from('pdf_templates')
        .select('*')
        .eq('id', response.pdf_template_id)
        .single();

      if (templateError || !template) {
        await generateSimplePDF(response);
        return;
      }

      const { PDFGenerator } = await import('../utils/pdfGenerator');
      
      const pdfTemplate = {
        id: template.id,
        name: template.name,
        fields: template.fields || [],
        originalPdfUrl: template.pdf_content,
      };

      let originalPdfBytes: Uint8Array;
      if (template.pdf_content.startsWith('data:application/pdf')) {
        const base64Data = template.pdf_content.split(',')[1];
        const binaryString = atob(base64Data);
        originalPdfBytes = new Uint8Array(binaryString.length);
        for (let i = 0; i < binaryString.length; i++) {
          originalPdfBytes[i] = binaryString.charCodeAt(i);
        }
      } else {
        throw new Error('Format de template PDF non supporté');
      }

      const pdfBytes = await PDFGenerator.generatePDF(pdfTemplate, response.response_data, originalPdfBytes);
      
      const blob = new Blob([pdfBytes], { type: 'application/pdf' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `${response.form_title}_${response.user_name || 'reponse'}_${Date.now()}.pdf`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      
    } catch (error) {
      console.error('❌ Erreur génération avec template:', error);
      await generateSimplePDF(response);
    }
  };

  const generateSimplePDF = async (response: FormResponsePDF) => {
    try {
      const { jsPDF } = await import('jspdf');
      const doc = new jsPDF();
      
      doc.setFontSize(18);
      doc.text(response.form_title, 20, 20);
      
      doc.setFontSize(10);
      doc.text(`Généré le: ${new Date().toLocaleDateString('fr-FR')}`, 20, 30);
      doc.text(`Réponse du: ${new Date(response.created_at).toLocaleDateString('fr-FR')}`, 20, 35);
      
      if (response.user_name) {
        doc.text(`Utilisateur: ${response.user_name}`, 20, 40);
      }
      
      let yPosition = 55;
      doc.setFontSize(12);
      
      Object.entries(response.response_data).forEach(([key, value]) => {
        if (value && typeof value === 'string' && !value.startsWith('data:image') && !value.startsWith('[')) {
          const text = `${key}: ${value}`;
          
          const splitText = doc.splitTextToSize(text, 170);
          doc.text(splitText, 20, yPosition);
          yPosition += splitText.length * 5;
          
          if (yPosition > 280) {
            doc.addPage();
            yPosition = 20;
          }
        }
      });
      
      const pdfBlob = doc.output('blob');
      const url = URL.createObjectURL(pdfBlob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `${response.form_title}_${response.user_name || 'reponse'}_${Date.now()}.pdf`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      
    } catch (error) {
      console.error('❌ Erreur génération PDF simple:', error);
      throw error;
    }
  };

  const deleteResponse = useCallback(async (responseId: string, formTitle: string) => {
    if (!window.confirm(`Supprimer cette réponse de "${formTitle}" ?`)) {
      return;
    }

    try {
      const { error } = await supabase
        .from('responses')
        .delete()
        .eq('id', responseId);

      if (error) {
        toast.error('Erreur lors de la suppression');
        return;
      }

      await loadFormResponses();
      toast.success('✅ Réponse supprimée avec succès');
      
    } catch (error) {
      console.error('❌ Erreur générale suppression:', error);
      toast.error('Erreur lors de la suppression');
    }
  }, [loadFormResponses]);

  const viewResponseDetails = useCallback((response: FormResponsePDF) => {
    setSelectedResponseForDetails(response);
    setShowDetailsModal(true);
  }, []);

  const handlePageChange = useCallback((page: number) => {
    setCurrentPage(page);
  }, []);

  const totalPages = Math.ceil(totalCount / itemsPerPage);

  const filteredAndSortedResponses = useMemo(() => {
    return responses
      .filter(response => {
        const matchesSearch = !searchTerm || 
          response.form_title.toLowerCase().includes(searchTerm.toLowerCase()) ||
          response.user_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
          Object.values(response.response_data).some(value => 
            typeof value === 'string' && value.toLowerCase().includes(searchTerm.toLowerCase())
          );
        
        const matchesForm = selectedFormFilter === 'all' || response.form_id === selectedFormFilter;
        
        return matchesSearch && matchesForm;
      })
      .sort((a, b) => {
        switch (sortBy) {
          case 'date':
            return new Date(b.created_at).getTime() - new Date(a.created_at).getTime();
          case 'form':
            return a.form_title.localeCompare(b.form_title);
          case 'user':
            return (a.user_name || '').localeCompare(b.user_name || '');
          default:
            return 0;
        }
      });
  }, [responses, searchTerm, selectedFormFilter, sortBy]);

  const isLocked = !isSubscribed && !hasSecretCode;

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-green-50 to-emerald-50 dark:from-gray-900 dark:via-green-900/20 dark:to-emerald-900/20">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="relative overflow-hidden bg-gradient-to-r from-green-600 via-emerald-600 to-teal-700 rounded-3xl shadow-2xl mb-8">
          <div className="absolute inset-0 bg-black/10"></div>
          <div className="absolute top-4 right-4 w-32 h-32 bg-white/10 rounded-full blur-2xl"></div>
          <div className="absolute bottom-4 left-4 w-24 h-24 bg-yellow-400/20 rounded-full blur-xl"></div>
          
          <div className="relative px-6 sm:px-8 py-8 sm:py-12">
            <div className="text-center">
              <div className="inline-flex items-center justify-center w-16 h-16 bg-white/20 backdrop-blur-sm rounded-2xl mb-6 shadow-lg">
                <HardDrive className="h-8 w-8 text-white" />
              </div>
              <h1 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-white mb-4">
                Génération PDF
                {isSubscribed && (
                  <span className="block text-lg sm:text-xl text-white/90 font-medium mt-2">
                    {product.name} • Illimité
                  </span>
                )}
              </h1>
              <p className="text-lg sm:text-xl text-white/90 mb-6 max-w-2xl mx-auto">
                {isSubscribed 
                  ? `Générez des PDFs illimités depuis vos réponses avec ${product.name}`
                  : 'Générez des PDFs depuis les réponses de vos formulaires'
                }
              </p>
              
              <div className="flex flex-col sm:flex-row items-center justify-center gap-4 sm:gap-8">
                <div className="inline-flex items-center space-x-2 bg-white/10 backdrop-blur-sm rounded-full px-4 py-2 text-white/90 text-sm font-medium">
                  <Activity className="h-4 w-4" />
                  <span>{totalCount} réponse{totalCount > 1 ? 's' : ''} disponible{totalCount > 1 ? 's' : ''}</span>
                </div>
                
                <div className={`inline-flex items-center space-x-2 bg-white/10 backdrop-blur-sm rounded-full px-3 py-1 text-white/90 text-xs font-medium ${
                  isRealTimeEnabled ? 'animate-pulse' : ''
                }`}>
                  {isRealTimeEnabled ? (
                    <Wifi className="h-3 w-3 text-green-400" />
                  ) : (
                    <WifiOff className="h-3 w-3 text-red-400" />
                  )}
                  <span>{isRealTimeEnabled ? 'Temps réel actif' : 'Temps réel désactivé'}</span>
                  {newResponsesCount > 0 && (
                    <span className="bg-red-500 text-white rounded-full w-5 h-5 flex items-center justify-center text-xs">
                      {newResponsesCount}
                    </span>
                  )}
                </div>
                
                <div className="flex items-center space-x-3">
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => {
                      setLoading(true);
                      loadFormResponses();
                    }}
                    className="bg-white/20 backdrop-blur-sm text-white border border-white/30 hover:bg-white/30 font-semibold shadow-lg hover:shadow-xl transition-all duration-300"
                    title="Actualiser la liste"
                  >
                    <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
                    <span className="hidden sm:inline ml-2">Actualiser</span>
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => setIsRealTimeEnabled(!isRealTimeEnabled)}
                    className={`font-semibold shadow-lg hover:shadow-xl transition-all duration-300 ${
                      isRealTimeEnabled 
                        ? 'bg-green-500/80 backdrop-blur-sm text-white border border-green-400/30 hover:bg-green-600/80'
                        : 'bg-red-500/80 backdrop-blur-sm text-white border border-red-400/30 hover:bg-red-600/80'
                    }`}
                    title={isRealTimeEnabled ? 'Désactiver le temps réel' : 'Activer le temps réel'}
                  >
                    {isRealTimeEnabled ? (
                      <Wifi className="h-4 w-4" />
                    ) : (
                      <WifiOff className="h-4 w-4" />
                    )}
                    <span className="hidden sm:inline ml-2">
                      {isRealTimeEnabled ? 'Temps réel ON' : 'Temps réel OFF'}
                    </span>
                  </Button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div className="mb-8">
          <SubscriptionBanner />
        </div>
        
        <Card className="mb-6 bg-white/80 backdrop-blur-sm border-0 shadow-xl">
          <CardContent className="p-6">
            <div className="flex items-center justify-between mb-4 pb-3 border-b border-gray-200/50 dark:border-gray-700/50">
              <div className="flex items-center space-x-2 text-sm text-gray-600 dark:text-gray-400">
                <Activity className="h-4 w-4" />
                <span>Dernière mise à jour: {lastUpdateTime.toLocaleTimeString('fr-FR')}</span>
                {newResponsesCount > 0 && (
                  <span className="bg-blue-100 text-blue-800 px-2 py-1 rounded-full text-xs font-medium">
                    +{newResponsesCount} nouvelle{newResponsesCount > 1 ? 's' : ''} réponse{newResponsesCount > 1 ? 's' : ''}
                  </span>
                )}
              </div>
              <div className="flex items-center space-x-2">
                <div className={`w-2 h-2 rounded-full ${
                  isRealTimeEnabled ? 'bg-green-500 animate-pulse' : 'bg-red-500'
                }`}></div>
                <span className="text-xs text-gray-500 font-medium">
                  {isRealTimeEnabled ? 'Synchronisation active' : 'Mode manuel'}
                </span>
              </div>
            </div>
            
            <div className="flex flex-col lg:flex-row gap-4">
              <div className="flex-1">
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-500 h-4 w-4" />
                  <Input
                    placeholder="Rechercher par formulaire, utilisateur ou contenu..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="pl-10 bg-white/70 backdrop-blur-sm border-gray-200/50 focus:border-green-500 rounded-xl font-medium"
                  />
                </div>
              </div>
              <div className="flex items-center justify-center gap-3">
                <span className="text-sm text-gray-600 dark:text-gray-400 hidden sm:inline font-semibold">Filtres:</span>
                <div className="relative">
                  <select
                    value={selectedFormFilter}
                    onChange={(e) => setSelectedFormFilter(e.target.value)}
                    className="appearance-none bg-white/70 dark:bg-gray-800/70 border border-gray-200/50 dark:border-gray-600/50 rounded-xl px-3 py-2 pr-8 text-sm focus:outline-none focus:ring-2 focus:ring-green-500 cursor-pointer hover:bg-white dark:hover:bg-gray-700 transition-all backdrop-blur-sm font-medium shadow-lg"
                  >
                    <option value="all">📋 Tous les formulaires</option>
                    {forms.map(form => (
                      <option key={form.id} value={form.id}>
                        📝 {form.title}
                      </option>
                    ))}
                  </select>
                </div>
                <div className="relative">
                  <select
                    value={sortBy}
                    onChange={(e) => setSortBy(e.target.value as 'date' | 'form' | 'user')}
                    className="appearance-none bg-white/70 dark:bg-gray-800/70 border border-gray-200/50 dark:border-gray-600/50 rounded-xl px-3 py-2 pr-8 text-sm focus:outline-none focus:ring-2 focus:ring-green-500 cursor-pointer hover:bg-white dark:hover:bg-gray-700 transition-all backdrop-blur-sm font-medium shadow-lg"
                  >
                    <option value="date">📅 Plus récent</option>
                    <option value="form">📝 Par formulaire</option>
                    <option value="user">👤 Par utilisateur</option>
                  </select>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {loading ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
            {[1, 2, 3, 4, 5, 6].map((i) => (
              <Card key={`skeleton-${i}`} className="animate-pulse bg-white/60 backdrop-blur-sm border-0 shadow-lg">
                <CardHeader>
                  <div className="flex items-center space-x-3">
                    <div className="w-10 h-10 bg-gray-200 dark:bg-gray-700 rounded-2xl"></div>
                    <div className="flex-1">
                      <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded-lg w-3/4 mb-2"></div>
                      <div className="h-3 bg-gray-200 dark:bg-gray-700 rounded-lg w-1/2"></div>
                    </div>
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    <div className="flex gap-2">
                      <div className="h-6 bg-gray-200 dark:bg-gray-700 rounded-lg w-16"></div>
                      <div className="h-6 bg-gray-200 dark:bg-gray-700 rounded-lg w-20"></div>
                    </div>
                    <div className="flex gap-2">
                      <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded-lg flex-1"></div>
                      <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded-lg w-16"></div>
                      <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded-lg w-16"></div>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        ) : filteredAndSortedResponses.length === 0 ? (
          <Card className="bg-white/80 backdrop-blur-sm border-0 shadow-xl">
            <CardContent className="text-center py-16">
              <div className="w-20 h-20 bg-gradient-to-br from-green-500 to-emerald-500 rounded-3xl flex items-center justify-center mx-auto mb-6 shadow-lg">
                <FileText className="h-10 w-10 text-white" />
              </div>
              <h3 className="text-xl sm:text-2xl font-bold text-gray-900 dark:text-white mb-4">
                Aucune réponse disponible
              </h3>
              <p className="text-gray-600 dark:text-gray-400 mb-8 text-lg">
                Les réponses de vos formulaires apparaîtront ici
              </p>
            </CardContent>
          </Card>
        ) : (
          <>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
              {filteredAndSortedResponses.map((response, index) => (
                <PDFCard
                  key={`pdf-${response.id}`}
                  pdf={response}
                  index={index}
                  onView={viewResponseDetails}
                  onDownload={generateAndDownloadPDF}
                  onDelete={deleteResponse}
                  isLocked={isLocked}
                  isGenerating={generatingPdf === response.id}
                />
              ))}
            </div>

            {totalPages > 1 && (
              <Card className="mt-8 bg-white/80 backdrop-blur-sm border-0 shadow-xl">
                <CardContent className="p-4">
                  <div className="flex items-center justify-between">
                    <div className="text-sm text-gray-600 dark:text-gray-400 font-medium">
                      Affichage de {((currentPage - 1) * itemsPerPage) + 1} à {Math.min(currentPage * itemsPerPage, totalCount)} sur {totalCount} réponses
                    </div>
                    <div className="flex items-center space-x-2">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handlePageChange(currentPage - 1)}
                        disabled={currentPage === 1}
                        className="flex items-center space-x-1 bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 rounded-xl font-semibold"
                      >
                        <ArrowLeft className="h-4 w-4" />
                        <span className="hidden sm:inline">Précédent</span>
                      </Button>
                      
                      <div className="flex items-center space-x-1">
                        {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
                          let pageNum;
                          if (totalPages <= 5) {
                            pageNum = i + 1;
                          } else if (currentPage <= 3) {
                            pageNum = i + 1;
                          } else if (currentPage >= totalPages - 2) {
                            pageNum = totalPages - 4 + i;
                          } else {
                            pageNum = currentPage - 2 + i;
                          }
                          
                          return (
                            <Button
                              key={`page-${pageNum}`}
                              variant={currentPage === pageNum ? "primary" : "secondary"}
                              size="sm"
                              onClick={() => handlePageChange(pageNum)}
                              className={`w-8 h-8 p-0 rounded-xl font-bold ${currentPage === pageNum ? 'shadow-lg' : 'bg-gray-100 dark:bg-gray-800'}`}
                            >
                              {pageNum}
                            </Button>
                          );
                        })}
                      </div>
                      
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handlePageChange(currentPage + 1)}
                        disabled={currentPage === totalPages}
                        className="flex items-center space-x-1 bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 rounded-xl font-semibold"
                      >
                        <span className="hidden sm:inline">Suivant</span>
                        <ArrowRight className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            )}
          </>
        )}

        {newResponsesCount > 0 && (
          <Card className="mb-6 border-blue-200 bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 animate-pulse">
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <div className="w-10 h-10 bg-blue-100 dark:bg-blue-900/30 rounded-full flex items-center justify-center">
                    <Activity className="h-5 w-5 text-blue-600 animate-pulse" />
                  </div>
                  <div>
                    <h3 className="text-sm font-semibold text-blue-900 dark:text-blue-300">
                      {newResponsesCount} nouvelle{newResponsesCount > 1 ? 's' : ''} réponse{newResponsesCount > 1 ? 's' : ''} !
                    </h3>
                    <p className="text-xs text-blue-700 dark:text-blue-400">
                      Actualisation automatique en cours...
                    </p>
                  </div>
                </div>
                <Button
                  size="sm"
                  onClick={() => {
                    loadFormResponses();
                    setNewResponsesCount(0);
                  }}
                  className="bg-blue-600 hover:bg-blue-700 text-white"
                >
                  Actualiser maintenant
                </Button>
              </div>
            </CardContent>
          </Card>
        )}
        
        {showLimitModal && (
          <LimitReachedModal
            isOpen={showLimitModal}
            onClose={() => setShowLimitModal(false)}
            limitType="savedPdfs"
            currentCount={savedPdfsLimits.current}
            maxCount={savedPdfsLimits.max}
          />
        )}

        {showDetailsModal && selectedResponseForDetails && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
            <Card className="max-w-4xl w-full max-h-[90vh] overflow-y-auto bg-white/95 backdrop-blur-sm border-0 shadow-2xl">
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div>
                    <h2 className="text-xl sm:text-2xl font-bold text-gray-900 dark:text-white">
                      Détails de la réponse
                    </h2>
                    <p className="text-sm text-gray-600 dark:text-gray-400 font-medium">
                      {selectedResponseForDetails.form_title} • {formatDateTimeFR(selectedResponseForDetails.created_at)}
                    </p>
                    {selectedResponseForDetails.user_name && (
                      <p className="text-sm text-blue-600 dark:text-blue-400 font-medium">
                        👤 {selectedResponseForDetails.user_name}
                      </p>
                    )}
                  </div>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => {
                      setShowDetailsModal(false);
                      setSelectedResponseForDetails(null);
                    }}
                    className="text-gray-500 hover:text-gray-700 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-xl"
                  >
                    <X className="h-4 w-4" />
                  </Button>
                </div>
              </CardHeader>
              <CardContent className="space-y-6">
                <div className="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 p-4 rounded-xl border border-blue-200 dark:border-blue-800 shadow-lg">
                  <h4 className="text-sm font-bold text-blue-900 dark:text-blue-300 mb-3 flex items-center space-x-2">
                    <Activity className="h-4 w-4" />
                    <span>Informations de soumission</span>
                  </h4>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs text-blue-700 dark:text-blue-400 font-medium">
                    <div>📅 Date : {formatDateTimeFR(selectedResponseForDetails.created_at)}</div>
                    <div>📋 Formulaire : {selectedResponseForDetails.form_title}</div>
                    {selectedResponseForDetails.ip_address && (
                      <div>🌐 Adresse IP : {selectedResponseForDetails.ip_address}</div>
                    )}
                    {selectedResponseForDetails.user_agent && (
                      <div className="md:col-span-2">🖥️ Navigateur : {selectedResponseForDetails.user_agent}</div>
                    )}
                  </div>
                </div>

                <div className="space-y-4">
                  <h4 className="text-lg font-bold text-gray-900 dark:text-white flex items-center space-x-2">
                    <FileText className="h-5 w-5" />
                    <span>Données soumises</span>
                  </h4>
                  
                  {Object.entries(selectedResponseForDetails.response_data || {})
                    .filter(([key, value]) => value !== undefined && value !== null && value !== '')
                    .map(([key, value]) => (
                      <div key={key} className="border border-gray-200 dark:border-gray-700 rounded-xl p-4 bg-white/70 dark:bg-gray-800/70 backdrop-blur-sm shadow-lg">
                        <div className="text-sm font-bold text-gray-700 dark:text-gray-300 mb-3 flex items-center space-x-2">
                          <span className="w-2 h-2 bg-blue-500 rounded-full"></span>
                          <span>{key}</span>
                        </div>
                        
                        {typeof value === 'string' && value.startsWith('data:image') ? (
                          <div>
                            {key.toLowerCase().includes('signature') ? (
                              <div className="bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 p-4 rounded-xl border border-blue-200 dark:border-blue-800 shadow-lg">
                                <div className="flex items-center space-x-2 mb-3">
                                  <div className="w-6 h-6 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-full flex items-center justify-center shadow-md">
                                    <span className="text-white text-xs">✍️</span>
                                  </div>
                                  <span className="text-sm font-bold text-blue-900 dark:text-blue-300">
                                    Signature électronique
                                  </span>
                                </div>
                                <div className="bg-white dark:bg-gray-800 p-3 rounded-lg border border-blue-200 dark:border-blue-700 shadow-inner">
                                  <img
                                    src={value}
                                    alt="Signature électronique"
                                    className="max-w-full max-h-32 object-contain mx-auto"
                                    style={{ imageRendering: 'crisp-edges' }}
                                  />
                                </div>
                                <div className="flex items-center justify-between mt-3">
                                  <span className="text-xs text-blue-700 dark:text-blue-400 font-medium">
                                    ✅ Signature valide et légale
                                  </span>
                                  <span className="text-xs text-gray-500 bg-gray-100 dark:bg-gray-800 px-2 py-1 rounded-lg">
                                    {Math.round(value.length / 1024)} KB
                                  </span>
                                </div>
                              </div>
                            ) : (
                              <div className="bg-gradient-to-br from-green-50 to-emerald-50 dark:from-green-900/20 dark:to-emerald-900/20 p-4 rounded-xl border border-green-200 dark:border-green-800 shadow-lg">
                                <div className="flex items-center space-x-2 mb-3">
                                  <div className="w-6 h-6 bg-gradient-to-br from-green-500 to-emerald-600 rounded-full flex items-center justify-center shadow-md">
                                    <span className="text-white text-xs">📷</span>
                                  </div>
                                  <span className="text-sm font-bold text-green-900 dark:text-green-300">
                                    Image uploadée
                                  </span>
                                </div>
                                <div className="bg-white dark:bg-gray-800 p-3 rounded-lg border border-green-200 dark:border-green-700 shadow-inner">
                                  <img
                                    src={value}
                                    alt={key}
                                    className="max-w-full max-h-48 object-contain mx-auto rounded-lg shadow-md"
                                  />
                                </div>
                                <div className="flex items-center justify-between mt-3">
                                  <span className="text-xs text-green-700 dark:text-green-400 font-medium">
                                    📁 Fichier image
                                  </span>
                                  <span className="text-xs text-gray-500 bg-gray-100 dark:bg-gray-800 px-2 py-1 rounded-lg">
                                    {Math.round(value.length / 1024)} KB
                                  </span>
                                </div>
                              </div>
                            )}
                          </div>
                        ) : Array.isArray(value) ? (
                          <div className="flex flex-wrap gap-2">
                            {value.map((item, idx) => (
                              <span key={`${key}-${idx}`} className="bg-gradient-to-r from-blue-100 to-indigo-100 text-blue-800 px-3 py-2 rounded-full text-sm font-semibold shadow-sm dark:from-blue-900 dark:to-indigo-900 dark:text-blue-300">
                                {item}
                              </span>
                            ))}
                          </div>
                        ) : (
                          <div className="bg-gray-50 dark:bg-gray-800 p-3 rounded-lg border border-gray-200 dark:border-gray-700">
                            <p className="text-gray-900 dark:text-white font-medium whitespace-pre-wrap break-words">
                              {String(value)}
                            </p>
                          </div>
                        )}
                      </div>
                    ))}
                </div>
              </CardContent>
            </Card>
          </div>
        )}
      </div>
    </div>
  );
};
