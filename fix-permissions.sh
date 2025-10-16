#!/bin/bash

echo "🔧 Correction des permissions..."

# 1. Corriger le propriétaire
sudo chown -R www-data:www-data /var/www/signfast/dist

# 2. Corriger les permissions
sudo chmod -R 755 /var/www/signfast/dist
sudo chmod 644 /var/www/signfast/dist/index.html

# 3. Vérifier
echo "✅ Permissions corrigées :"
ls -lh /var/www/signfast/dist/index.html

# 4. Recharger Nginx
sudo systemctl reload nginx

echo "✅ Terminé !"
