#!/bin/bash

echo "🔍 DIAGNOSTIC ERREUR 500"
echo "========================"
echo ""

# 1. Vérifier les logs Nginx
echo "📋 Dernières erreurs Nginx :"
sudo tail -50 /var/log/nginx/error.log
echo ""

# 2. Vérifier la config Nginx
echo "🧪 Test configuration Nginx :"
sudo nginx -t
echo ""

# 3. Vérifier que index.html existe
echo "📁 Vérification index.html :"
ls -lh /var/www/signfast/dist/index.html
echo ""

# 4. Vérifier les permissions
echo "🔐 Permissions du dossier dist :"
ls -la /var/www/signfast/dist/ | head -20
echo ""

# 5. Vérifier le propriétaire
echo "👤 Propriétaire des fichiers :"
stat /var/www/signfast/dist/index.html
echo ""

# 6. Tester l'accès direct au fichier
echo "🧪 Test accès direct index.html :"
curl -I https://signfast.pro/index.html
echo ""

# 7. Afficher la config actuelle
echo "📄 Configuration Nginx actuelle :"
sudo cat /etc/nginx/sites-available/signfast | grep -A 5 "location /"
echo ""

# 8. Vérifier le statut Nginx
echo "⚙️ Statut Nginx :"
sudo systemctl status nginx --no-pager | head -20
