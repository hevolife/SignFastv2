#!/bin/bash

echo "🔧 Correction des MIME types pour modules JavaScript..."

# 1. Backup de l'ancienne config
sudo cp /etc/nginx/sites-available/signfast /etc/nginx/sites-available/signfast.backup.$(date +%Y%m%d_%H%M%S)

# 2. Copier la nouvelle config
sudo cp nginx-mime-types-fix.conf /etc/nginx/sites-available/signfast

# 3. Tester la configuration
echo "🧪 Test de la configuration Nginx..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuration valide"
    
    # 4. Recharger Nginx
    sudo systemctl reload nginx
    echo "✅ Nginx rechargé"
    
    # 5. Vérifier les fichiers .mjs
    echo ""
    echo "📁 Vérification des fichiers .mjs..."
    find /var/www/SignFastv2/dist -name "*.mjs" -type f
    
    # 6. Tester le MIME type
    echo ""
    echo "🧪 Test du MIME type pour .mjs..."
    echo "Exécutez cette commande pour vérifier :"
    echo "curl -I https://signfast.pro/assets/pdf.worker.min-yatZIOMy.mjs"
    
    echo ""
    echo "✅ Déploiement terminé !"
    echo "🎯 Rechargez la page avec Ctrl+Shift+R (cache vidé)"
else
    echo "❌ Erreur dans la configuration Nginx"
    exit 1
fi
