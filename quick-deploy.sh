#!/bin/bash

#############################################
# ⚡ Déploiement rapide (sans vérifications)
#############################################

cd /var/www/signfast

echo "⚡ Déploiement rapide..."

# Récupérer les modifications
git pull origin main

# Installer dépendances si nécessaire
npm install

# Builder
npm run build

# Corriger permissions
sudo chown -R www-data:www-data dist/
sudo chmod -R 755 dist/

# Redémarrer
pm2 restart signfast

echo "✅ Terminé !"
pm2 status
