import React, { useState, useCallback, useMemo } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { useDemo } from '../contexts/DemoContext';
import { OptimizedPDFService } from '../services/optimizedPDFService';
import { PDFCard } from '../components/storage/PDFCard';
import { StorageStats } from '../components/storage/StorageStats';
import { StorageFilters } from '../components/storage/StorageFilters';
import { Button } from '../components/ui/Button';
import { Card, CardContent } from '../components/ui/Card';
import { FileText, ArrowLeft, ArrowRight } from 'lucide-react';
import toast from 'react-hot-toast';
import { useLimits } from '../hooks/useLimits';
import { useSubscription } from '../hooks/useSubscription';
import { SubscriptionBanner } from '../components/subscription/SubscriptionBanner';
import { LimitReachedModal } from '../components/subscription/LimitReachedModal';
import { DemoWarningBanner } from '../components/demo/DemoWarningBanner';

interface StoredPDF {
  id: string;
  file_name: string;
  form_title: string;
  template_name: string;
  file_size: number;
  created_at: string;
  pdf_content: string;
}

export const Storage: React.FC = () => {
  const { user } = useAuth();
  const { isDemoMode } = useDemo();
  const { savedPdfs } = useLimits();
  const { isSubscribed } = useSubscription();
  
  // États optimisés
  const [pdfs, setPdfs] = React.useState<StoredPDF[]>([]);
  const [loading, setLoading] = React.useState(true);
  const [totalCount, setTotalCount] = React.useState(0);
  const [currentPage, setCurrentPage] = React.useState(1);
  const [searchTerm, setSearchTerm] = React.useState('');
  const [sortBy, setSortBy] = React.useState<'date' | 'name' | 'size'>('date');
  const [showLimitModal, setShowLimitModal] = React.useState(false);
  const [selectedPdfs, setSelectedPdfs] = React.useState<Set<string>>(new Set());
  
  const itemsPerPage = 12;

  // Fonction de chargement optimisée avec cache
  const loadPDFs = useCallback(async (page: number, search: string = '', sort: string = 'date') => {
    if (!user?.id) {
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      
      // Utiliser le service optimisé avec pagination
      const { pdfs: loadedPdfs, total } = await OptimizedPDFService.getUserPDFsPaginated(
        user.id,
        page,
        itemsPerPage,
        search,
        sort as 'date' | 'name' | 'size'
      );

      setPdfs(loadedPdfs);
      setTotalCount(total);

      // Précharger la page suivante en arrière-plan
      if (page * itemsPerPage < total) {
        OptimizedPDFService.prefetchNextPage(user.id, page, itemsPerPage, search, sort as 'date' | 'name' | 'size');
      }
    } catch (error) {
      console.error('Erreur chargement PDFs:', error);
      toast.error('Erreur lors du chargement des PDFs');
      setPdfs([]);
      setTotalCount(0);
    } finally {
      setLoading(false);
    }
  }, [user?.id]);

  // Chargement initial optimisé
  React.useEffect(() => {
    loadPDFs(currentPage, searchTerm, sortBy);
  }, [currentPage, loadPDFs]);

  // Recherche avec debounce
  React.useEffect(() => {
    const timer = setTimeout(() => {
      if (currentPage === 1) {
        loadPDFs(1, searchTerm, sortBy);
      } else {
        setCurrentPage(1);
      }
    }, 300);

    return () => clearTimeout(timer);
  }, [searchTerm, sortBy]);

  // Gestion du changement de page
  const handlePageChange = useCallback((page: number) => {
    setCurrentPage(page);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }, []);

  // Téléchargement optimisé
  const handleDownload = useCallback(async (pdf: StoredPDF) => {
    try {
      const blob = OptimizedPDFService.base64ToBlob(pdf.pdf_content);
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = pdf.file_name;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(url);
      toast.success('PDF téléchargé avec succès');
    } catch (error) {
      console.error('Erreur téléchargement:', error);
      toast.error('Erreur lors du téléchargement');
    }
  }, []);

  // Suppression optimisée
  const handleDelete = useCallback(async (id: string, fileName: string) => {
    if (!window.confirm(`Supprimer "${fileName}" ?`)) return;

    try {
      await OptimizedPDFService.deletePDF(id);
      
      // Mise à jour optimiste de l'UI
      setPdfs(prev => prev.filter(p => p.id !== id));
      setTotalCount(prev => prev - 1);
      
      toast.success('PDF supprimé');
      
      // Recharger si la page devient vide
      if (pdfs.length === 1 && currentPage > 1) {
        setCurrentPage(prev => prev - 1);
      }
    } catch (error) {
      console.error('Erreur suppression:', error);
      toast.error('Erreur lors de la suppression');
      // Recharger en cas d'erreur
      loadPDFs(currentPage, searchTerm, sortBy);
    }
  }, [pdfs.length, currentPage, searchTerm, sortBy, loadPDFs]);

  // Suppression multiple optimisée
  const handleBulkDelete = useCallback(async () => {
    if (selectedPdfs.size === 0) return;
    
    if (!window.confirm(`Supprimer ${selectedPdfs.size} PDF(s) ?`)) return;

    try {
      const deletePromises = Array.from(selectedPdfs).map(id => 
        OptimizedPDFService.deletePDF(id)
      );
      
      await Promise.all(deletePromises);
      
      // Mise à jour optimiste
      setPdfs(prev => prev.filter(p => !selectedPdfs.has(p.id)));
      setTotalCount(prev => prev - selectedPdfs.size);
      setSelectedPdfs(new Set());
      
      toast.success(`${selectedPdfs.size} PDF(s) supprimé(s)`);
      
      // Recharger si nécessaire
      if (pdfs.length === selectedPdfs.size && currentPage > 1) {
        setCurrentPage(prev => prev - 1);
      }
    } catch (error) {
      console.error('Erreur suppression multiple:', error);
      toast.error('Erreur lors de la suppression');
      loadPDFs(currentPage, searchTerm, sortBy);
    }
  }, [selectedPdfs, pdfs.length, currentPage, searchTerm, sortBy, loadPDFs]);

  // Sélection/désélection
  const toggleSelection = useCallback((id: string) => {
    setSelectedPdfs(prev => {
      const newSet = new Set(prev);
      if (newSet.has(id)) {
        newSet.delete(id);
      } else {
        newSet.add(id);
      }
      return newSet;
    });
  }, []);

  const toggleSelectAll = useCallback(() => {
    if (selectedPdfs.size === pdfs.length) {
      setSelectedPdfs(new Set());
    } else {
      setSelectedPdfs(new Set(pdfs.map(p => p.id)));
    }
  }, [pdfs, selectedPdfs.size]);

  // Calcul des pages
  const totalPages = Math.ceil(totalCount / itemsPerPage);

  // Statistiques mémorisées
  const stats = useMemo(() => ({
    total: totalCount,
    totalSize: pdfs.reduce((sum, pdf) => sum + pdf.file_size, 0),
  }), [totalCount, pdfs]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-50 dark:from-gray-900 dark:via-blue-900/20 dark:to-indigo-900/20">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="relative overflow-hidden bg-gradient-to-r from-blue-600 via-purple-600 to-indigo-700 rounded-3xl shadow-2xl mb-8">
          <div className="absolute inset-0 bg-black/10"></div>
          <div className="absolute top-4 right-4 w-32 h-32 bg-white/10 rounded-full blur-2xl"></div>
          <div className="absolute bottom-4 left-4 w-24 h-24 bg-yellow-400/20 rounded-full blur-xl"></div>
          
          <div className="relative px-6 sm:px-8 py-8 sm:py-12">
            <div className="text-center">
              <div className="inline-flex items-center justify-center w-16 h-16 bg-white/20 backdrop-blur-sm rounded-2xl mb-6 shadow-lg">
                <FileText className="h-8 w-8 text-white" />
              </div>
              <h1 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-white mb-4">
                Mes PDFs Sauvegardés
              </h1>
              <p className="text-lg sm:text-xl text-white/90 mb-6 max-w-2xl mx-auto">
                Gérez et téléchargez vos documents PDF générés
              </p>
              
              <StorageStats 
                totalPdfs={stats.total}
                totalSize={stats.totalSize}
                limit={savedPdfs.max}
              />
            </div>
          </div>
        </div>

        {/* Banners */}
        <div className="mb-8">
          {isDemoMode && <DemoWarningBanner />}
          <SubscriptionBanner />
        </div>

        {/* Filtres et recherche */}
        <Card className="mb-6 bg-white/80 backdrop-blur-sm border-0 shadow-xl">
          <CardContent className="p-4">
            <StorageFilters
              searchTerm={searchTerm}
              onSearchChange={setSearchTerm}
              sortBy={sortBy}
              onSortChange={setSortBy}
            />

            {/* Actions groupées */}
            {selectedPdfs.size > 0 && (
              <div className="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700 flex items-center justify-between">
                <span className="text-sm text-gray-600 dark:text-gray-400 font-medium">
                  {selectedPdfs.size} sélectionné(s)
                </span>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={handleBulkDelete}
                  className="bg-red-500 text-white hover:bg-red-600"
                >
                  Supprimer la sélection
                </Button>
              </div>
            )}

            {/* Sélectionner tout */}
            {pdfs.length > 0 && (
              <div className="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700">
                <label className="flex items-center space-x-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={selectedPdfs.size === pdfs.length && pdfs.length > 0}
                    onChange={toggleSelectAll}
                    className="w-4 h-4 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
                  />
                  <span className="text-sm text-gray-700 dark:text-gray-300 font-medium">
                    Tout sélectionner
                  </span>
                </label>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Liste des PDFs */}
        {loading ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
            {[1, 2, 3, 4, 5, 6].map((i) => (
              <Card key={`skeleton-${i}`} className="animate-pulse bg-white/60 backdrop-blur-sm border-0 shadow-lg">
                <CardContent className="p-6">
                  <div className="space-y-3">
                    <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-3/4"></div>
                    <div className="h-3 bg-gray-200 dark:bg-gray-700 rounded w-1/2"></div>
                    <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded"></div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        ) : pdfs.length === 0 ? (
          <Card className="bg-white/80 backdrop-blur-sm border-0 shadow-xl">
            <CardContent className="text-center py-16">
              <div className="inline-flex items-center justify-center w-20 h-20 bg-gradient-to-br from-blue-500 to-indigo-500 text-white rounded-3xl mb-6 shadow-xl">
                <FileText className="h-8 w-8" />
              </div>
              <h3 className="text-xl sm:text-2xl font-bold text-gray-900 dark:text-white mb-4">
                {searchTerm ? 'Aucun résultat' : 'Aucun PDF sauvegardé'}
              </h3>
              <p className="text-gray-600 dark:text-gray-400 mb-8 text-lg">
                {searchTerm 
                  ? 'Essayez avec d\'autres termes de recherche'
                  : 'Vos PDFs générés apparaîtront ici'
                }
              </p>
            </CardContent>
          </Card>
        ) : (
          <>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
              {pdfs.map((pdf) => (
                <PDFCard
                  key={`pdf-${pdf.id}`}
                  pdf={pdf}
                  isSelected={selectedPdfs.has(pdf.id)}
                  onToggleSelect={toggleSelection}
                  onDownload={handleDownload}
                  onDelete={handleDelete}
                />
              ))}
            </div>

            {/* Pagination */}
            {totalPages > 1 && (
              <Card className="mt-8 bg-white/80 backdrop-blur-sm border-0 shadow-xl">
                <CardContent className="p-4">
                  <div className="flex items-center justify-between">
                    <div className="text-sm text-gray-600 dark:text-gray-400 font-medium">
                      Affichage de {((currentPage - 1) * itemsPerPage) + 1} à {Math.min(currentPage * itemsPerPage, totalCount)} sur {totalCount} PDFs
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

        <LimitReachedModal
          isOpen={showLimitModal}
          onClose={() => setShowLimitModal(false)}
          limitType="savedPdfs"
          currentCount={savedPdfs.current}
          maxCount={savedPdfs.max}
        />
      </div>
    </div>
  );
};
