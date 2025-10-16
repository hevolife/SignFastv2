#!/bin/bash

echo "🔧 Correction complète de SignFast..."

# 1. Rebuild avec les nouveaux fichiers PWA
echo "📦 Rebuild de l'application..."
npm run build

# 2. Backup de l'ancienne config Nginx
sudo cp /etc/nginx/sites-available/signfast /etc/nginx/sites-available/signfast.backup.$(date +%Y%m%d_%H%M%S)

# 3. Copier la nouvelle config Nginx
sudo cp nginx-fixed.conf /etc/nginx/sites-available/signfast

# 4. Tester la configuration
echo "🧪 Test de la configuration Nginx..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuration valide"
    
    # 5. Recharger Nginx
    sudo systemctl reload nginx
    echo "✅ Nginx rechargé"
    
    # 6. Vérifier les fichiers
    echo ""
    echo "📁 Vérification des fichiers dans dist/..."
    ls -lh /var/www/signfast/dist/ | grep -E "(manifest|sw\.js|favicon|icon-)"
    
    echo ""
    echo "✅ Déploiement terminé !"
    echo "🎯 Testez : https://signfast.pro"
else
    echo "❌ Erreur dans la configuration Nginx"
    exit 1
fi
