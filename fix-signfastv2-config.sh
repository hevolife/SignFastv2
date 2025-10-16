#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🔧 CORRECTION MIME TYPES - SignFastv2${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

CONFIG_FILE="/etc/nginx/sites-available/SignFastv2"

# 1. Vérifier que le fichier existe
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ Fichier $CONFIG_FILE introuvable !${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Fichier trouvé : $CONFIG_FILE${NC}"
echo ""

# 2. Backup
echo -e "${YELLOW}💾 Backup configuration...${NC}"
sudo cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
echo -e "${GREEN}✅ Backup créé${NC}"
echo ""

# 3. Afficher la config actuelle
echo -e "${YELLOW}📄 Configuration actuelle :${NC}"
echo "---"
sudo cat "$CONFIG_FILE"
echo "---"
echo ""

# 4. Créer la nouvelle config avec MIME types corrects
echo -e "${YELLOW}📝 Création nouvelle configuration...${NC}"
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

    # 🔥 CRITIQUE : MIME types explicites pour JavaScript
    types {
        text/html                             html htm shtml;
        text/css                              css;
        text/javascript                       js mjs;
        application/json                      json;
        image/gif                             gif;
        image/jpeg                            jpeg jpg;
        image/png                             png;
        image/svg+xml                         svg svgz;
        image/webp                            webp;
        font/woff                             woff;
        font/woff2                            woff2;
        application/pdf                       pdf;
    }

    # Gzip
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/json;

    # Headers de sécurité
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # 🔥 PRIORITÉ ABSOLUE : Modules JavaScript (.mjs et .js)
    location ~* \.(mjs|js)$ {
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
    location ~* \.(css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
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

echo -e "${GREEN}✅ Configuration créée${NC}"
echo ""

# 5. Vérifier le symlink
echo -e "${YELLOW}🔗 Vérification symlink...${NC}"
if [ -L /etc/nginx/sites-enabled/SignFastv2 ]; then
    echo -e "${GREEN}✅ Symlink existe${NC}"
else
    echo -e "${YELLOW}⚠️ Création du symlink...${NC}"
    sudo ln -sf /etc/nginx/sites-available/SignFastv2 /etc/nginx/sites-enabled/SignFastv2
    echo -e "${GREEN}✅ Symlink créé${NC}"
fi
echo ""

# 6. Supprimer les anciens symlinks
echo -e "${YELLOW}🧹 Nettoyage anciens symlinks...${NC}"
sudo rm -f /etc/nginx/sites-enabled/signfast 2>/dev/null || true
sudo rm -f /etc/nginx/sites-enabled/signfast.pro 2>/dev/null || true
echo -e "${GREEN}✅ Nettoyage terminé${NC}"
echo ""

# 7. Test configuration
echo -e "${YELLOW}🧪 Test configuration Nginx...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}✅ Configuration valide${NC}"
else
    echo -e "${RED}❌ Configuration invalide${NC}"
    echo "Restauration du backup..."
    sudo cp "${CONFIG_FILE}.backup."* "$CONFIG_FILE"
    exit 1
fi
echo ""

# 8. Reload Nginx
echo -e "${YELLOW}🔄 Rechargement Nginx...${NC}"
sudo systemctl reload nginx
echo -e "${GREEN}✅ Nginx rechargé${NC}"
echo ""

# 9. Attendre 2 secondes
sleep 2

# 10. Test MIME type
echo -e "${YELLOW}🌐 Test MIME type...${NC}"
WORKER_MJS=$(find /var/www/SignFastv2/dist/assets -name "*pdf.worker*.mjs" -type f | head -1)
if [ -n "$WORKER_MJS" ]; then
    WORKER_NAME=$(basename "$WORKER_MJS")
    echo "Test : https://signfast.pro/assets/$WORKER_NAME"
    
    RESPONSE=$(curl -sI "https://signfast.pro/assets/$WORKER_NAME")
    MIME_TYPE=$(echo "$RESPONSE" | grep -i "content-type" | cut -d: -f2 | tr -d ' \r')
    
    echo "MIME type reçu : $MIME_TYPE"
    
    if echo "$MIME_TYPE" | grep -q "javascript"; then
        echo -e "${GREEN}✅ MIME type correct !${NC}"
    else
        echo -e "${RED}❌ MIME type incorrect : $MIME_TYPE${NC}"
        echo -e "${RED}Attendu : text/javascript${NC}"
    fi
fi
echo ""

# 11. Test fichier .js
echo -e "${YELLOW}🌐 Test fichier .js...${NC}"
PDF_JS=$(find /var/www/SignFastv2/dist/assets -name "pdf-*.js" -type f | head -1)
if [ -n "$PDF_JS" ]; then
    PDF_NAME=$(basename "$PDF_JS")
    echo "Test : https://signfast.pro/assets/$PDF_NAME"
    
    RESPONSE=$(curl -sI "https://signfast.pro/assets/$PDF_NAME")
    MIME_TYPE=$(echo "$RESPONSE" | grep -i "content-type" | cut -d: -f2 | tr -d ' \r')
    
    echo "MIME type reçu : $MIME_TYPE"
    
    if echo "$MIME_TYPE" | grep -q "javascript"; then
        echo -e "${GREEN}✅ MIME type correct !${NC}"
    else
        echo -e "${RED}❌ MIME type incorrect : $MIME_TYPE${NC}"
        echo -e "${RED}Attendu : text/javascript${NC}"
    fi
fi
echo ""

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              ✅ CORRECTION TERMINÉE ! ✅                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}📝 ACTIONS SUIVANTES :${NC}"
echo "1. Vider COMPLÈTEMENT le cache navigateur"
echo "2. Fermer TOUS les onglets signfast.pro"
echo "3. Redémarrer le navigateur"
echo "4. Ouvrir en navigation privée : Ctrl+Shift+N"
echo "5. Aller sur https://signfast.pro"
echo ""
echo -e "${BLUE}Si le problème persiste :${NC}"
echo "- Envoyer screenshot console (F12 → Console)"
echo "- Envoyer screenshot network (F12 → Network → pdf)"
