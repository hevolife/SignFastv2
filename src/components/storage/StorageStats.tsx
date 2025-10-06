import React from 'react';
import { FileText, HardDrive, TrendingUp } from 'lucide-react';

interface StorageStatsProps {
  totalPdfs: number;
  totalSize: number;
  limit: number;
}

export const StorageStats: React.FC<StorageStatsProps> = React.memo(({ 
  totalPdfs, 
  totalSize, 
  limit 
}) => {
  const formatSize = (bytes: number): string => {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  const percentage = limit === Infinity ? 0 : (totalPdfs / limit) * 100;

  return (
    <div className="flex flex-wrap items-center justify-center gap-4 sm:gap-6">
      <div className="flex items-center space-x-2 bg-white/10 backdrop-blur-sm rounded-full px-4 py-2 text-white/90 text-sm font-medium">
        <FileText className="h-4 w-4" />
        <span>{totalPdfs} PDF{totalPdfs > 1 ? 's' : ''}</span>
      </div>
      
      <div className="flex items-center space-x-2 bg-white/10 backdrop-blur-sm rounded-full px-4 py-2 text-white/90 text-sm font-medium">
        <HardDrive className="h-4 w-4" />
        <span>{formatSize(totalSize)}</span>
      </div>
      
      {limit !== Infinity && (
        <div className="flex items-center space-x-2 bg-white/10 backdrop-blur-sm rounded-full px-4 py-2 text-white/90 text-sm font-medium">
          <TrendingUp className="h-4 w-4" />
          <span>{totalPdfs}/{limit} ({percentage.toFixed(0)}%)</span>
        </div>
      )}
    </div>
  );
});

StorageStats.displayName = 'StorageStats';
