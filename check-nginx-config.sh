#!/bin/bash

echo "🔍 DIAGNOSTIC NGINX COMPLET"
echo "═══════════════════════════════════════"
echo ""

echo "1️⃣ Contenu actuel de la config Nginx :"
echo "─────────────────────────────────────"
sudo cat /etc/nginx/sites-available/signfast
echo ""
echo ""

echo "2️⃣ Vérification du lien symbolique :"
echo "─────────────────────────────────────"
ls -la /etc/nginx/sites-enabled/ | grep signfast
echo ""

echo "3️⃣ Test de la configuration Nginx :"
echo "─────────────────────────────────────"
sudo nginx -t
echo ""

echo "4️⃣ Statut du service Nginx :"
echo "─────────────────────────────────────"
sudo systemctl status nginx --no-pager -l
echo ""

echo "5️⃣ Dernières erreurs Nginx :"
echo "─────────────────────────────────────"
sudo tail -20 /var/log/nginx/error.log
echo ""

echo "6️⃣ Vérification du dossier dist :"
echo "─────────────────────────────────────"
ls -lah /var/www/SignFastv2/dist/ 2>/dev/null || echo "❌ Dossier dist/ n'existe pas"
echo ""

echo "7️⃣ Vérification de index.html :"
echo "─────────────────────────────────────"
if [ -f "/var/www/SignFastv2/dist/index.html" ]; then
    echo "✅ index.html existe"
    ls -lh /var/www/SignFastv2/dist/index.html
else
    echo "❌ index.html n'existe pas"
fi
echo ""

echo "8️⃣ Permissions du dossier :"
echo "─────────────────────────────────────"
ls -ld /var/www/SignFastv2/
ls -ld /var/www/SignFastv2/dist/ 2>/dev/null || echo "dist/ n'existe pas"
echo ""

echo "9️⃣ Processus Nginx actifs :"
echo "─────────────────────────────────────"
ps aux | grep nginx | grep -v grep
echo ""

echo "🔟 Configuration Nginx complète (grep root) :"
echo "─────────────────────────────────────"
sudo nginx -T 2>/dev/null | grep -A 5 "root"
