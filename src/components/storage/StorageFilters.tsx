import React from 'react';
import { Search, Filter } from 'lucide-react';

interface StorageFiltersProps {
  searchTerm: string;
  onSearchChange: (value: string) => void;
  sortBy: 'date' | 'name' | 'size';
  onSortChange: (value: 'date' | 'name' | 'size') => void;
}

export const StorageFilters: React.FC<StorageFiltersProps> = React.memo(({
  searchTerm,
  onSearchChange,
  sortBy,
  onSortChange,
}) => {
  return (
    <div className="flex flex-col sm:flex-row gap-4">
      {/* Recherche */}
      <div className="flex-1 relative">
        <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
        <input
          type="text"
          placeholder="Rechercher un PDF..."
          value={searchTerm}
          onChange={(e) => onSearchChange(e.target.value)}
          className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
        />
      </div>

      {/* Tri */}
      <div className="flex items-center gap-2">
        <Filter className="h-5 w-5 text-gray-400" />
        <select
          value={sortBy}
          onChange={(e) => onSortChange(e.target.value as 'date' | 'name' | 'size')}
          className="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
        >
          <option value="date">Plus récent</option>
          <option value="name">Nom A-Z</option>
          <option value="size">Taille</option>
        </select>
      </div>
    </div>
  );
});

StorageFilters.displayName = 'StorageFilters';
