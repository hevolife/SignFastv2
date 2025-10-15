import { supabase } from '../lib/supabase';

export interface StoredPDF {
  id: string;
  file_name: string;
  form_title: string;
  template_name: string;
  file_size: number;
  created_at: string;
  pdf_content: string;
  user_name?: string;
}

export class OptimizedPDFService {
  private static cache = new Map<string, { data: StoredPDF[]; timestamp: number }>();
  private static countCache = new Map<string, { count: number; timestamp: number }>();
  private static CACHE_DURATION = 30000; // 30 secondes

  /**
   * 🆕 Comptage ultra-rapide des PDFs utilisateur avec cache
   */
  static async countUserPDFs(userId: string): Promise<number> {
    try {
      // Vérifier le cache
      const cached = this.countCache.get(userId);
      if (cached && Date.now() - cached.timestamp < this.CACHE_DURATION) {
        return cached.count;
      }

      // ✅ CORRECTION: Utiliser pdf_storage au lieu de saved_pdfs
      const { count, error } = await supabase
        .from('pdf_storage')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', userId);

      if (error) {
        console.error('❌ Erreur comptage PDFs:', error);
        return 0;
      }

      const totalCount = count || 0;

      // Mise en cache
      this.countCache.set(userId, { count: totalCount, timestamp: Date.now() });

      return totalCount;
    } catch (error) {
      console.error('❌ Erreur comptage PDFs:', error);
      return 0;
    }
  }

  /**
   * Récupération paginée optimisée avec cache
   */
  static async getUserPDFsPaginated(
    userId: string,
    page: number = 1,
    limit: number = 12,
    search: string = '',
    sortBy: 'date' | 'name' | 'size' = 'date'
  ): Promise<{ pdfs: StoredPDF[]; total: number }> {
    try {
      const cacheKey = `${userId}-${page}-${limit}-${search}-${sortBy}`;
      const cached = this.cache.get(cacheKey);
      
      // Vérifier le cache
      if (cached && Date.now() - cached.timestamp < this.CACHE_DURATION) {
        const { count } = await supabase
          .from('pdf_storage')
          .select('id', { count: 'exact', head: true })
          .eq('user_id', userId);
        
        return { pdfs: cached.data, total: count || 0 };
      }

      // Requête de comptage
      let countQuery = supabase
        .from('pdf_storage')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', userId);

      if (search) {
        countQuery = countQuery.or(`file_name.ilike.%${search}%,form_title.ilike.%${search}%`);
      }

      const { count } = await countQuery;

      // Requête de données avec sélection minimale
      const offset = (page - 1) * limit;
      let dataQuery = supabase
        .from('pdf_storage')
        .select('id, file_name, form_title, template_name, file_size, created_at, pdf_content')
        .eq('user_id', userId)
        .range(offset, offset + limit - 1);

      if (search) {
        dataQuery = dataQuery.or(`file_name.ilike.%${search}%,form_title.ilike.%${search}%`);
      }

      // Tri optimisé
      switch (sortBy) {
        case 'name':
          dataQuery = dataQuery.order('file_name', { ascending: true });
          break;
        case 'size':
          dataQuery = dataQuery.order('file_size', { ascending: false });
          break;
        default:
          dataQuery = dataQuery.order('created_at', { ascending: false });
      }

      const { data, error } = await dataQuery;

      if (error) throw error;

      const pdfs = (data || []).map(pdf => ({
        ...pdf,
        user_name: this.extractUserName(pdf.file_name)
      }));

      // Mise en cache
      this.cache.set(cacheKey, { data: pdfs, timestamp: Date.now() });

      return { pdfs, total: count || 0 };
    } catch (error) {
      console.error('❌ Erreur chargement PDFs:', error);
      return { pdfs: [], total: 0 };
    }
  }

  /**
   * Suppression optimisée avec invalidation du cache
   */
  static async deletePDF(pdfId: string): Promise<void> {
    try {
      const { error } = await supabase
        .from('pdf_storage')
        .delete()
        .eq('id', pdfId);

      if (error) throw error;

      // Invalider tout le cache (données + comptage)
      this.cache.clear();
      this.countCache.clear();
    } catch (error) {
      console.error('❌ Erreur suppression PDF:', error);
      throw error;
    }
  }

  /**
   * Conversion base64 vers Blob optimisée
   */
  static base64ToBlob(base64: string): Blob {
    const base64Data = base64.includes(',') ? base64.split(',')[1] : base64;
    const byteCharacters = atob(base64Data);
    const byteArrays: Uint8Array[] = [];

    // Traitement par chunks pour les gros fichiers
    const sliceSize = 512;
    for (let offset = 0; offset < byteCharacters.length; offset += sliceSize) {
      const slice = byteCharacters.slice(offset, offset + sliceSize);
      const byteNumbers = new Array(slice.length);
      
      for (let i = 0; i < slice.length; i++) {
        byteNumbers[i] = slice.charCodeAt(i);
      }
      
      byteArrays.push(new Uint8Array(byteNumbers));
    }

    return new Blob(byteArrays, { type: 'application/pdf' });
  }

  /**
   * Extraction du nom d'utilisateur depuis le nom de fichier
   */
  private static extractUserName(fileName: string): string {
    try {
      // Extraire le nom entre le titre du formulaire et la date
      const parts = fileName.split('_');
      if (parts.length >= 3) {
        // Format: FormTitle_UserName_Timestamp.pdf
        return parts[1].replace(/-/g, ' ');
      }
      return '';
    } catch {
      return '';
    }
  }

  /**
   * Invalider le cache manuellement
   */
  static clearCache(): void {
    this.cache.clear();
    this.countCache.clear();
  }

  /**
   * Préchargement des données pour la page suivante
   */
  static async prefetchNextPage(
    userId: string,
    currentPage: number,
    limit: number,
    search: string,
    sortBy: 'date' | 'name' | 'size'
  ): Promise<void> {
    // Précharger en arrière-plan sans bloquer
    setTimeout(() => {
      this.getUserPDFsPaginated(userId, currentPage + 1, limit, search, sortBy);
    }, 100);
  }
}
