#!/bin/bash

echo "⏮️ ROLLBACK vers la dernière config fonctionnelle..."

# 1. Lister les backups
echo "📋 Backups disponibles :"
ls -lht /etc/nginx/sites-available/signfast.backup.* | head -5
echo ""

# 2. Restaurer le dernier backup
LAST_BACKUP=$(ls -t /etc/nginx/sites-available/signfast.backup.* | head -1)
echo "🔄 Restauration de : $LAST_BACKUP"
sudo cp "$LAST_BACKUP" /etc/nginx/sites-available/signfast

# 3. Tester
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuration valide"
    sudo systemctl reload nginx
    echo "✅ Nginx rechargé"
    
    echo ""
    echo "🧪 Test de la route :"
    curl -I https://signfast.pro/login
else
    echo "❌ Erreur dans la configuration"
fi
