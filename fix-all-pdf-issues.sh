#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🔧 CORRECTION COMPLÈTE PDF PRODUCTION${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# 1. Identifier la config active
echo -e "${YELLOW}1️⃣ Identification config Nginx...${NC}"
if [ -f /etc/nginx/sites-enabled/signfast ]; then
    CONFIG_FILE="/etc/nginx/sites-enabled/signfast"
    echo -e "${GREEN}✅ Config trouvée : $CONFIG_FILE${NC}"
elif [ -f /etc/nginx/sites-available/signfast ]; then
    CONFIG_FILE="/etc/nginx/sites-available/signfast"
    echo -e "${GREEN}✅ Config trouvée : $CONFIG_FILE${NC}"
else
    echo -e "${RED}❌ Aucune config trouvée !${NC}"
    exit 1
fi
echo ""

# 2. Backup
echo -e "${YELLOW}2️⃣ Backup configuration...${NC}"
sudo cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
echo -e "${GREEN}✅ Backup créé${NC}"
echo ""

# 3. Créer la config propre
echo -e "${YELLOW}3️⃣ Création config propre...${NC}"
sudo tee "$CONFIG_FILE" > /dev/null << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name signfast.pro www.signfast.pro;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name signfast.pro www.signfast.pro;

    ssl_certificate /etc/letsencrypt/live/signfast.pro/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/signfast.pro/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    root /var/www/SignFastv2/dist;
    index index.html;

    access_log /var/log/nginx/signfast_access.log;
    error_log /var/log/nginx/signfast_error.log;

    # Gzip
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Headers de sécurité
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # 🔥 CRITIQUE : Modules JavaScript (.mjs) avec MIME type correct
    location ~* \.mjs$ {
        add_header Content-Type "text/javascript" always;
        add_header Cache-Control "public, max-age=31536000, immutable" always;
        try_files $uri =404;
    }

    # Fichiers PWA manquants
    location ~ ^/(manifest\.json|sw\.js|service-worker\.js)$ {
        return 204;
        add_header Cache-Control "no-cache";
    }

    # Assets statiques avec cache
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    # SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOF

echo -e "${GREEN}✅ Config créée${NC}"
echo ""

# 4. Vérifier qu'il n'y a pas de doublons
echo -e "${YELLOW}4️⃣ Vérification doublons...${NC}"
SIGNFAST_CONFIGS=$(find /etc/nginx/sites-enabled -name "*signfast*" | wc -l)
if [ "$SIGNFAST_CONFIGS" -gt 1 ]; then
    echo -e "${RED}⚠️ Plusieurs configs trouvées :${NC}"
    find /etc/nginx/sites-enabled -name "*signfast*"
    echo ""
    echo -e "${YELLOW}Suppression des doublons...${NC}"
    sudo rm -f /etc/nginx/sites-enabled/signfast.pro 2>/dev/null || true
    echo -e "${GREEN}✅ Doublons supprimés${NC}"
else
    echo -e "${GREEN}✅ Une seule config${NC}"
fi
echo ""

# 5. Test configuration
echo -e "${YELLOW}5️⃣ Test configuration Nginx...${NC}"
if sudo nginx -t 2>&1 | grep -q "successful"; then
    echo -e "${GREEN}✅ Configuration valide${NC}"
else
    echo -e "${RED}❌ Configuration invalide${NC}"
    sudo nginx -t
    exit 1
fi
echo ""

# 6. Rebuild frontend (pour générer les bons fichiers)
echo -e "${YELLOW}6️⃣ Rebuild frontend...${NC}"
cd /var/www/SignFastv2
npm run build
echo -e "${GREEN}✅ Build terminé${NC}"
echo ""

# 7. Vérifier les nouveaux fichiers
echo -e "${YELLOW}7️⃣ Vérification nouveaux fichiers...${NC}"
echo "Fichiers PDF dans dist/assets :"
ls -lh dist/assets/ | grep -E "pdf.*\.(js|mjs)"
echo ""

# 8. Recharger Nginx
echo -e "${YELLOW}8️⃣ Rechargement Nginx...${NC}"
sudo systemctl reload nginx
echo -e "${GREEN}✅ Nginx rechargé${NC}"
echo ""

# 9. Test final
echo -e "${YELLOW}9️⃣ Test final...${NC}"
sleep 2

# Tester le MIME type
WORKER_MJS=$(find /var/www/SignFastv2/dist/assets -name "*pdf.worker*.mjs" -type f | head -1)
if [ -n "$WORKER_MJS" ]; then
    WORKER_NAME=$(basename "$WORKER_MJS")
    echo "Test MIME type : https://signfast.pro/assets/$WORKER_NAME"
    MIME_TYPE=$(curl -sI "https://signfast.pro/assets/$WORKER_NAME" | grep -i "content-type" | cut -d: -f2 | tr -d ' \r')
    
    if echo "$MIME_TYPE" | grep -q "javascript"; then
        echo -e "${GREEN}✅ MIME type correct : $MIME_TYPE${NC}"
    else
        echo -e "${RED}❌ MIME type incorrect : $MIME_TYPE${NC}"
    fi
fi
echo ""

# 10. Vérifier qu'il n'y a plus d'erreurs
echo -e "${YELLOW}🔟 Vérification logs...${NC}"
echo "Dernières erreurs PDF :"
sudo tail -20 /var/log/nginx/error.log | grep -i "pdf" || echo "Aucune erreur PDF récente"
echo ""

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              ✅ CORRECTION TERMINÉE ! ✅                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}📝 ACTIONS SUIVANTES :${NC}"
echo "1. Vider le cache navigateur (Ctrl+Shift+Delete)"
echo "2. Faire un hard refresh (Ctrl+Shift+R)"
echo "3. Tester le chargement PDF sur https://signfast.pro"
echo ""
echo -e "${BLUE}Si le problème persiste, envoyer :${NC}"
echo "- Screenshot console (F12 → Console)"
echo "- Screenshot network (F12 → Network → filtrer 'pdf')"
