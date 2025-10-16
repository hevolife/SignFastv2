#!/bin/bash

#############################################
# 🔧 CORRECTION NGINX POUR /var/www/SignFastv2
#############################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🔧 CORRECTION NGINX POUR SignFastv2${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# 1. Sauvegarder la config Nginx
echo -e "${YELLOW}1️⃣ Sauvegarde configuration Nginx...${NC}"
sudo cp /etc/nginx/sites-available/signfast /etc/nginx/sites-available/signfast.backup.$(date +%Y%m%d_%H%M%S)
echo -e "${GREEN}✅ Sauvegarde créée${NC}"
echo ""

# 2. Corriger la configuration Nginx
echo -e "${YELLOW}2️⃣ Correction configuration Nginx...${NC}"
sudo tee /etc/nginx/sites-available/signfast > /dev/null << 'EOF'
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

    # Certificats SSL
    ssl_certificate /etc/letsencrypt/live/signfast.pro/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/signfast.pro/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # CHEMIN CORRECT VERS SignFastv2
    root /var/www/SignFastv2/dist;
    index index.html;

    # Logs
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

    # PWA files - retourner 204 si manquants
    location ~ ^/(manifest\.json|sw\.js|service-worker\.js)$ {
        try_files $uri =204;
        add_header Cache-Control "no-cache";
    }

    # Assets statiques avec cache
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    # Route principale - SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOF

echo -e "${GREEN}✅ Configuration Nginx corrigée pour /var/www/SignFastv2/dist${NC}"
echo ""

# 3. Tester la configuration
echo -e "${YELLOW}3️⃣ Test configuration Nginx...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}✅ Configuration valide${NC}"
else
    echo -e "${RED}❌ Configuration invalide${NC}"
    echo "Restauration de la sauvegarde..."
    sudo cp /etc/nginx/sites-available/signfast.backup.* /etc/nginx/sites-available/signfast
    exit 1
fi
echo ""

# 4. Vérifier si dist/ existe
echo -e "${YELLOW}4️⃣ Vérification du dossier dist...${NC}"
cd /var/www/SignFastv2

if [ -d "dist" ] && [ -f "dist/index.html" ]; then
    echo -e "${GREEN}✅ dist/index.html existe déjà${NC}"
    ls -lh dist/index.html
    echo ""
    read -p "Voulez-vous rebuilder quand même ? (o/N) : " REBUILD
    if [ "$REBUILD" = "o" ] || [ "$REBUILD" = "O" ]; then
        NEED_BUILD=true
    else
        NEED_BUILD=false
    fi
else
    echo -e "${YELLOW}⚠️  dist/ manquant ou incomplet${NC}"
    NEED_BUILD=true
fi
echo ""

# 5. Builder si nécessaire
if [ "$NEED_BUILD" = true ]; then
    echo -e "${YELLOW}5️⃣ Vérification .env...${NC}"
    if [ ! -f ".env" ]; then
        echo -e "${YELLOW}⚠️  Fichier .env manquant${NC}"
        echo "Création du fichier .env..."
        cat > .env << 'ENVEOF'
NODE_ENV=production
PORT=3000
VITE_SUPABASE_URL=https://signfast.hevolife.fr
VITE_SUPABASE_ANON_KEY=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsImlhdCI6MTc1OTA5MTIyMCwiZXhwIjo0OTE0NzY0ODIwLCJyb2xlIjoiYW5vbiJ9.4BQ0CUqu4P-4rkgEsI9TtH2Oby81Ry81qh0a6353drY
ENVEOF
        echo -e "${GREEN}✅ .env créé${NC}"
    else
        echo -e "${GREEN}✅ .env existe${NC}"
    fi
    echo ""

    echo -e "${YELLOW}6️⃣ Installation des dépendances...${NC}"
    if [ -f "package.json" ]; then
        npm install
        echo -e "${GREEN}✅ Dépendances installées${NC}"
    else
        echo -e "${RED}❌ package.json manquant${NC}"
        exit 1
    fi
    echo ""

    echo -e "${YELLOW}7️⃣ Build de l'application...${NC}"
    if npm run build; then
        echo -e "${GREEN}✅ Build réussi${NC}"
    else
        echo -e "${RED}❌ Build échoué${NC}"
        exit 1
    fi
    echo ""

    echo -e "${YELLOW}8️⃣ Vérification du build...${NC}"
    if [ -f "dist/index.html" ]; then
        echo -e "${GREEN}✅ dist/index.html créé${NC}"
        ls -lh dist/index.html
    else
        echo -e "${RED}❌ dist/index.html manquant après build${NC}"
        exit 1
    fi
    echo ""
fi

# 9. Corriger les permissions
echo -e "${YELLOW}9️⃣ Correction des permissions...${NC}"
sudo chown -R www-data:www-data dist/
sudo chmod -R 755 dist/
sudo chmod 644 dist/index.html
echo -e "${GREEN}✅ Permissions corrigées${NC}"
echo ""

# 10. Recharger Nginx
echo -e "${YELLOW}🔟 Rechargement Nginx...${NC}"
sudo systemctl reload nginx
echo -e "${GREEN}✅ Nginx rechargé${NC}"
echo ""

# 11. Redémarrer PM2
echo -e "${YELLOW}1️⃣1️⃣ Redémarrage PM2...${NC}"
pm2 restart signfast || pm2 start npm --name signfast -- start
sleep 3
echo -e "${GREEN}✅ PM2 redémarré${NC}"
echo ""

# 12. Tests finaux
echo -e "${YELLOW}1️⃣2️⃣ Tests finaux...${NC}"

echo "Test 1: Fichier index.html accessible"
if [ -f "/var/www/SignFastv2/dist/index.html" ]; then
    echo -e "${GREEN}✅ index.html existe${NC}"
else
    echo -e "${RED}❌ index.html manquant${NC}"
fi

echo "Test 2: Nginx pointe vers le bon dossier"
if sudo nginx -T 2>/dev/null | grep -q "root /var/www/SignFastv2/dist"; then
    echo -e "${GREEN}✅ Nginx pointe vers /var/www/SignFastv2/dist${NC}"
else
    echo -e "${RED}❌ Nginx ne pointe pas vers le bon dossier${NC}"
fi

echo "Test 3: Application accessible localement"
if curl -f http://localhost:3000 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Application accessible sur localhost:3000${NC}"
else
    echo -e "${YELLOW}⚠️  Application non accessible localement${NC}"
fi

echo "Test 4: Site accessible via HTTPS"
sleep 2
if curl -f https://signfast.pro > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Site accessible sur https://signfast.pro${NC}"
else
    echo -e "${YELLOW}⚠️  Vérifiez manuellement https://signfast.pro${NC}"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║        ✅ CORRECTION TERMINÉE ! ✅                        ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}📊 Résumé :${NC}"
echo "  - Configuration Nginx : /etc/nginx/sites-available/signfast"
echo "  - Root Nginx : /var/www/SignFastv2/dist"
echo "  - Application : /var/www/SignFastv2"
echo "  - Build : dist/"
echo ""

echo -e "${BLUE}🔍 Vérifications :${NC}"
pm2 status
echo ""
echo "Testez maintenant : https://signfast.pro"
