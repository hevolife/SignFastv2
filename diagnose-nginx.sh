#!/bin/bash

echo "🔍 DIAGNOSTIC CONFIGURATION NGINX"
echo "=================================="
echo ""

# 1. Vérifier le fichier de configuration actuel
echo "📄 Configuration actuelle :"
echo "---"
sudo cat /etc/nginx/sites-available/signfast
echo ""
echo "---"
echo ""

# 2. Vérifier le lien symbolique
echo "🔗 Lien symbolique sites-enabled :"
ls -la /etc/nginx/sites-enabled/ | grep signfast
echo ""

# 3. Tester la configuration
echo "🧪 Test configuration Nginx :"
sudo nginx -t
echo ""

# 4. Vérifier le processus Nginx
echo "⚙️ Statut Nginx :"
sudo systemctl status nginx --no-pager
echo ""

# 5. Tester le MIME type actuel
echo "🌐 MIME type actuel pour .mjs :"
curl -I https://signfast.pro/assets/pdf.worker.min-yatZIOMy.mjs 2>&1 | grep -i "content-type"
echo ""

# 6. Vérifier les fichiers .mjs dans dist
echo "📁 Fichiers .mjs dans dist :"
find /var/www/SignFastv2/dist -name "*.mjs" -type f
echo ""

# 7. Vérifier les logs d'erreur récents
echo "📋 Dernières erreurs Nginx :"
sudo tail -20 /var/log/nginx/error.log
echo ""

echo "✅ Diagnostic terminé"
