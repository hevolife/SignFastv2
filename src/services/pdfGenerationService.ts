import { supabase } from '../lib/supabase';
import { PDFDocument, rgb, StandardFonts } from 'pdf-lib';

interface GeneratePDFOptions {
  templateId: string;
  formTitle: string;
  responseId: string;
  formData: Record<string, any>;
  saveToServer?: boolean;
}

export class PDFGenerationService {
  /**
   * Génère un PDF à partir d'un template et des données du formulaire
   */
  static async generatePDF(options: GeneratePDFOptions): Promise<Uint8Array> {
    const { templateId, formTitle, responseId, formData, saveToServer = false } = options;

    try {
      console.log('📄 Début génération PDF');
      console.log('📄 Template ID:', templateId);
      console.log('📄 Response ID:', responseId);

      // 1. Récupérer le template avec .maybeSingle() pour éviter l'erreur multiple rows
      const { data: template, error: templateError } = await supabase
        .from('pdf_templates')
        .select('*')
        .eq('id', templateId)
        .maybeSingle(); // ✅ Utiliser maybeSingle() au lieu de single()

      if (templateError) {
        console.error('❌ Erreur récupération template:', templateError);
        throw new Error(`Erreur récupération template: ${templateError.message}`);
      }

      if (!template) {
        console.error('❌ Template non trouvé:', templateId);
        throw new Error(`Template non trouvé avec l'ID: ${templateId}`);
      }

      console.log('✅ Template récupéré:', template.name);

      // 2. Créer le PDF
      let pdfBytes: Uint8Array;

      if (template.template_file) {
        // Utiliser le template existant
        console.log('📄 Utilisation du template existant');
        pdfBytes = await this.fillPDFTemplate(template.template_file, formData);
      } else {
        // Créer un nouveau PDF
        console.log('📄 Création d\'un nouveau PDF');
        pdfBytes = await this.createPDFFromScratch(formTitle, formData);
      }

      console.log('✅ PDF généré, taille:', pdfBytes.length, 'bytes');

      // 3. Sauvegarder si demandé
      if (saveToServer) {
        await this.savePDFToServer({
          pdfBytes,
          formTitle,
          templateName: template.name,
          responseId,
          formData
        });
      }

      return pdfBytes;

    } catch (error: any) {
      console.error('❌ Erreur génération PDF:', error);
      throw new Error(`Erreur génération PDF: ${error.message}`);
    }
  }

  /**
   * Remplit un template PDF existant avec les données
   */
  private static async fillPDFTemplate(
    templateBase64: string,
    formData: Record<string, any>
  ): Promise<Uint8Array> {
    try {
      // Convertir base64 en bytes
      const templateBytes = this.base64ToBytes(templateBase64);
      
      // Charger le PDF
      const pdfDoc = await PDFDocument.load(templateBytes);
      
      // Récupérer le formulaire PDF
      const form = pdfDoc.getForm();
      const fields = form.getFields();

      console.log('📄 Champs du template:', fields.length);

      // Remplir les champs
      for (const [key, value] of Object.entries(formData)) {
        try {
          const field = form.getTextField(key);
          if (field) {
            field.setText(String(value || ''));
          }
        } catch (e) {
          // Champ non trouvé, continuer
        }
      }

      // Aplatir le formulaire (rendre les champs non modifiables)
      form.flatten();

      return await pdfDoc.save();

    } catch (error: any) {
      console.error('❌ Erreur remplissage template:', error);
      throw new Error(`Erreur remplissage template: ${error.message}`);
    }
  }

  /**
   * Crée un PDF from scratch avec les données
   */
  private static async createPDFFromScratch(
    formTitle: string,
    formData: Record<string, any>
  ): Promise<Uint8Array> {
    try {
      const pdfDoc = await PDFDocument.create();
      const page = pdfDoc.addPage([595, 842]); // A4
      const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
      const boldFont = await pdfDoc.embedFont(StandardFonts.HelveticaBold);

      const { width, height } = page.getSize();
      let yPosition = height - 50;

      // Titre
      page.drawText(formTitle, {
        x: 50,
        y: yPosition,
        size: 20,
        font: boldFont,
        color: rgb(0, 0, 0),
      });

      yPosition -= 40;

      // Date de génération
      page.drawText(`Date: ${new Date().toLocaleDateString('fr-FR')}`, {
        x: 50,
        y: yPosition,
        size: 10,
        font: font,
        color: rgb(0.5, 0.5, 0.5),
      });

      yPosition -= 30;

      // Ligne de séparation
      page.drawLine({
        start: { x: 50, y: yPosition },
        end: { x: width - 50, y: yPosition },
        thickness: 1,
        color: rgb(0.8, 0.8, 0.8),
      });

      yPosition -= 30;

      // Données du formulaire
      for (const [key, value] of Object.entries(formData)) {
        // Ignorer les métadonnées
        if (key.startsWith('_')) continue;

        // Vérifier si on a assez d'espace
        if (yPosition < 100) {
          // Nouvelle page
          const newPage = pdfDoc.addPage([595, 842]);
          yPosition = height - 50;
        }

        // Label
        page.drawText(`${key}:`, {
          x: 50,
          y: yPosition,
          size: 12,
          font: boldFont,
          color: rgb(0, 0, 0),
        });

        yPosition -= 20;

        // Valeur
        let displayValue = '';
        
        if (typeof value === 'string' && value.startsWith('data:image')) {
          displayValue = '[Image attachée]';
        } else if (Array.isArray(value)) {
          displayValue = value.join(', ');
        } else if (typeof value === 'object') {
          displayValue = JSON.stringify(value);
        } else {
          displayValue = String(value || '');
        }

        // Gérer le texte long
        const maxWidth = width - 100;
        const words = displayValue.split(' ');
        let line = '';

        for (const word of words) {
          const testLine = line + word + ' ';
          const textWidth = font.widthOfTextAtSize(testLine, 11);

          if (textWidth > maxWidth && line !== '') {
            page.drawText(line, {
              x: 70,
              y: yPosition,
              size: 11,
              font: font,
              color: rgb(0.2, 0.2, 0.2),
            });
            line = word + ' ';
            yPosition -= 15;

            if (yPosition < 100) {
              const newPage = pdfDoc.addPage([595, 842]);
              yPosition = height - 50;
            }
          } else {
            line = testLine;
          }
        }

        if (line !== '') {
          page.drawText(line, {
            x: 70,
            y: yPosition,
            size: 11,
            font: font,
            color: rgb(0.2, 0.2, 0.2),
          });
        }

        yPosition -= 30;
      }

      // Footer
      const footerY = 30;
      page.drawText('Généré par SignFast - Signature électronique française', {
        x: 50,
        y: footerY,
        size: 8,
        font: font,
        color: rgb(0.5, 0.5, 0.5),
      });

      return await pdfDoc.save();

    } catch (error: any) {
      console.error('❌ Erreur création PDF:', error);
      throw new Error(`Erreur création PDF: ${error.message}`);
    }
  }

  /**
   * Sauvegarde le PDF sur le serveur
   */
  private static async savePDFToServer(options: {
    pdfBytes: Uint8Array;
    formTitle: string;
    templateName: string;
    responseId: string;
    formData: Record<string, any>;
  }): Promise<void> {
    const { pdfBytes, formTitle, templateName, responseId, formData } = options;

    try {
      console.log('💾 Sauvegarde du PDF sur le serveur');

      // Récupérer l'utilisateur actuel
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        console.log('⚠️ Pas d\'utilisateur connecté, PDF non sauvegardé');
        return;
      }

      // Convertir en base64
      const base64 = this.bytesToBase64(pdfBytes);

      // Extraire le nom d'utilisateur des données du formulaire
      const userName = this.extractUserName(formData);
      const timestamp = Date.now();
      const fileName = `${formTitle}_${userName}_${timestamp}.pdf`;

      // Sauvegarder dans la base de données
      const { error } = await supabase
        .from('saved_pdfs')
        .insert({
          user_id: user.id,
          file_name: fileName,
          form_title: formTitle,
          template_name: templateName,
          file_size: pdfBytes.length,
          pdf_content: base64,
          response_id: responseId
        });

      if (error) {
        throw error;
      }

      console.log('✅ PDF sauvegardé:', fileName);

    } catch (error: any) {
      console.error('❌ Erreur sauvegarde PDF:', error);
      // Ne pas bloquer si la sauvegarde échoue
    }
  }

  /**
   * Extrait le nom d'utilisateur des données du formulaire
   */
  private static extractUserName(formData: Record<string, any>): string {
    const nameFields = ['nom', 'name', 'prenom', 'firstname', 'lastname'];
    
    for (const field of nameFields) {
      const value = formData[field];
      if (value && typeof value === 'string') {
        return value.replace(/\s+/g, '-');
      }
    }

    return 'utilisateur';
  }

  /**
   * Convertit base64 en Uint8Array
   */
  private static base64ToBytes(base64: string): Uint8Array {
    const base64Data = base64.includes(',') ? base64.split(',')[1] : base64;
    const binaryString = atob(base64Data);
    const bytes = new Uint8Array(binaryString.length);
    
    for (let i = 0; i < binaryString.length; i++) {
      bytes[i] = binaryString.charCodeAt(i);
    }
    
    return bytes;
  }

  /**
   * Convertit Uint8Array en base64
   */
  private static bytesToBase64(bytes: Uint8Array): string {
    let binary = '';
    for (let i = 0; i < bytes.length; i++) {
      binary += String.fromCharCode(bytes[i]);
    }
    return btoa(binary);
  }
}
