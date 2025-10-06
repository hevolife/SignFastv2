import React from 'react';
import { Card, CardContent } from '../ui/Card';
import { Button } from '../ui/Button';
import { Download, Trash2, FileText, Calendar, HardDrive } from 'lucide-react';
import { formatDateFR } from '../../utils/dateFormatter';

interface StoredPDF {
  id: string;
  file_name: string;
  form_title: string;
  template_name: string;
  file_size: number;
  created_at: string;
  pdf_content: string;
}

interface PDFCardProps {
  pdf: StoredPDF;
  isSelected: boolean;
  onToggleSelect: (id: string) => void;
  onDownload: (pdf: StoredPDF) => void;
  onDelete: (id: string, fileName: string) => void;
}

export const PDFCard: React.FC<PDFCardProps> = React.memo(({
  pdf,
  isSelected,
  onToggleSelect,
  onDownload,
  onDelete,
}) => {
  const formatFileSize = (bytes: number): string => {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  return (
    <Card className="group relative bg-white/80 backdrop-blur-sm border-0 shadow-xl hover:shadow-2xl transition-all duration-300 hover:-translate-y-1">
      <CardContent className="p-6">
        {/* Checkbox de sélection */}
        <div className="absolute top-4 right-4 z-10">
          <input
            type="checkbox"
            checked={isSelected}
            onChange={() => onToggleSelect(pdf.id)}
            className="w-5 h-5 text-blue-600 rounded focus:ring-2 focus:ring-blue-500 cursor-pointer"
          />
        </div>

        {/* Icône et titre */}
        <div className="flex items-start space-x-4 mb-4">
          <div className="w-12 h-12 bg-gradient-to-br from-red-500 to-pink-600 rounded-2xl flex items-center justify-center shadow-lg flex-shrink-0">
            <FileText className="h-6 w-6 text-white" />
          </div>
          <div className="flex-1 min-w-0">
            <h3 className="text-lg font-bold text-gray-900 dark:text-white truncate mb-1">
              {pdf.file_name}
            </h3>
            <p className="text-sm text-gray-600 dark:text-gray-400 truncate">
              {pdf.form_title}
            </p>
          </div>
        </div>

        {/* Informations */}
        <div className="space-y-2 mb-4">
          <div className="flex items-center text-xs text-gray-500 dark:text-gray-400">
            <Calendar className="h-3 w-3 mr-1" />
            <span>{formatDateFR(pdf.created_at)}</span>
          </div>
          <div className="flex items-center text-xs text-gray-500 dark:text-gray-400">
            <HardDrive className="h-3 w-3 mr-1" />
            <span>{formatFileSize(pdf.file_size)}</span>
          </div>
          {pdf.template_name && (
            <div className="text-xs bg-gradient-to-r from-purple-100 to-pink-100 text-purple-800 px-2 py-1 rounded-full inline-block">
              {pdf.template_name}
            </div>
          )}
        </div>

        {/* Actions */}
        <div className="flex items-center gap-2">
          <Button
            variant="ghost"
            size="sm"
            onClick={() => onDownload(pdf)}
            className="flex-1 bg-gradient-to-r from-green-500 to-emerald-500 text-white hover:from-green-600 hover:to-emerald-600 shadow-lg hover:shadow-xl transition-all duration-300 font-semibold rounded-xl"
          >
            <Download className="h-4 w-4 mr-1" />
            Télécharger
          </Button>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => onDelete(pdf.id, pdf.file_name)}
            className="bg-gradient-to-r from-red-500 to-pink-500 text-white hover:from-red-600 hover:to-pink-600 shadow-lg hover:shadow-xl transition-all duration-300 font-semibold rounded-xl"
          >
            <Trash2 className="h-4 w-4" />
          </Button>
        </div>
      </CardContent>
    </Card>
  );
});

PDFCard.displayName = 'PDFCard';
