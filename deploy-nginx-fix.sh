#!/bin/bash

# 🔧 Script de déploiement de la configuration Nginx corrigée

echo "🔧 Déploiement de la configuration Nginx avec CSP corrigée..."

# Backup de l'ancienne config
sudo cp /etc/nginx/sites-available/signfast /etc/nginx/sites-available/signfast.backup.$(date +%Y%m%d_%H%M%S)

# Copier la nouvelle config
sudo cp nginx-csp-fix.conf /etc/nginx/sites-available/signfast

# Tester la configuration
echo "🧪 Test de la configuration Nginx..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuration valide, rechargement de Nginx..."
    sudo systemctl reload nginx
    echo "✅ Nginx rechargé avec succès !"
    echo ""
    echo "🎯 Testez maintenant l'authentification sur https://signfast.pro"
else
    echo "❌ Erreur dans la configuration Nginx !"
    echo "🔄 Restauration de l'ancienne configuration..."
    sudo cp /etc/nginx/sites-available/signfast.backup.$(date +%Y%m%d_%H%M%S) /etc/nginx/sites-available/signfast
    exit 1
fi
