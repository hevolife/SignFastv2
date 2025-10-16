#!/bin/bash

echo "🔧 Correction du SPA routing..."

# 1. Backup de l'ancienne config
sudo cp /etc/nginx/sites-available/signfast /etc/nginx/sites-available/signfast.backup.$(date +%Y%m%d_%H%M%S)

# 2. Copier la nouvelle config
sudo cp nginx-spa-fixed.conf /etc/nginx/sites-available/signfast

# 3. Tester la configuration
echo "🧪 Test de la configuration Nginx..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuration valide"
    
    # 4. Recharger Nginx
    sudo systemctl reload nginx
    echo "✅ Nginx rechargé"
    
    # 5. Vérifier que index.html existe
    echo ""
    echo "📁 Vérification de index.html..."
    ls -lh /var/www/signfast/dist/index.html
    
    # 6. Tester les routes
    echo ""
    echo "🧪 Test des routes..."
    echo "- Accueil : curl -I https://signfast.pro/"
    echo "- Login : curl -I https://signfast.pro/login"
    
    echo ""
    echo "✅ Déploiement terminé !"
    echo "🎯 Testez : https://signfast.pro/login"
else
    echo "❌ Erreur dans la configuration Nginx"
    exit 1
fi
