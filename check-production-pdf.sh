#!/bin/bash

echo "🔍 DIAGNOSTIC ERREUR PDF PRODUCTION"
echo "===================================="
echo ""

# 1. Vérifier les fichiers PDF worker dans dist
echo "📁 Fichiers PDF worker dans dist :"
find /var/www/SignFastv2/dist -name "*pdf.worker*" -type f
echo ""

# 2. Vérifier les permissions
echo "🔐 Permissions des assets :"
ls -la /var/www/SignFastv2/dist/assets/ | grep -E "(pdf|mjs)"
echo ""

# 3. Tester l'accès direct au worker
echo "🌐 Test accès direct au worker :"
WORKER_FILE=$(find /var/www/SignFastv2/dist/assets -name "*pdf.worker*.mjs" -type f | head -1)
if [ -n "$WORKER_FILE" ]; then
    WORKER_NAME=$(basename "$WORKER_FILE")
    echo "Fichier trouvé : $WORKER_NAME"
    curl -I "https://signfast.pro/assets/$WORKER_NAME" 2>&1 | grep -E "(HTTP|Content-Type)"
else
    echo "❌ Aucun fichier worker trouvé !"
fi
echo ""

# 4. Vérifier la configuration Nginx actuelle
echo "⚙️ Configuration Nginx actuelle :"
sudo cat /etc/nginx/sites-available/signfast.pro | grep -A 5 "\.mjs"
echo ""

# 5. Vérifier les logs Nginx récents
echo "📋 Logs Nginx récents (erreurs PDF) :"
sudo tail -50 /var/log/nginx/error.log | grep -i "pdf\|mjs\|worker"
echo ""

# 6. Vérifier le statut Nginx
echo "✅ Statut Nginx :"
sudo systemctl status nginx --no-pager | head -5
echo ""

# 7. Tester la configuration Nginx
echo "🧪 Test configuration Nginx :"
sudo nginx -t
echo ""

echo "✅ Diagnostic terminé"
echo ""
echo "📝 PROCHAINES ÉTAPES :"
echo "1. Ouvrir la console navigateur en production (F12)"
echo "2. Aller dans l'onglet 'Console'"
echo "3. Copier l'erreur exacte qui apparaît"
echo "4. Aller dans l'onglet 'Network'"
echo "5. Filtrer par 'pdf' ou 'worker'"
echo "6. Cliquer sur la requête en erreur"
echo "7. Copier les détails (Status, Headers, Response)"
