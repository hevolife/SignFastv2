#!/bin/bash

#############################################
# 🔧 MISE À JOUR FORCÉE DE NGINX
#############################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🔧 MISE À JOUR FORCÉE NGINX${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# 1. Arrêter Nginx
echo -e "${YELLOW}1️⃣ Arrêt de Nginx...${NC}"
sudo systemctl stop nginx
echo -e "${GREEN}✅ Nginx arrêté${NC}"
echo ""

# 2. Backup
echo -e "${YELLOW}2️⃣ Sauvegarde...${NC}"
sudo cp /etc/nginx/sites-available/signfast /etc/nginx/sites-available/signfast.backup.force.$(date +%Y%m%d_%H%M%S)
echo -e "${GREEN}✅ Sauvegarde créée${NC}"
echo ""

# 3. Supprimer l'ancienne config
echo -e "${YELLOW}3️⃣ Suppression ancienne config...${NC}"
sudo rm -f /etc/nginx/sites-available/signfast
sudo rm -f /etc/nginx/sites-enabled/signfast
echo -e "${GREEN}✅ Ancienne config supprimée${NC}"
echo ""

# 4. Créer la nouvelle config
echo -e "${YELLOW}4️⃣ Création nouvelle config...${NC}"
sudo bash -c 'cat > /etc/nginx/sites-available/signfast << '\''EOF'\''
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

    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    location ~ ^/(manifest\.json|sw\.js|service-worker\.js)$ {
        try_files $uri =204;
        add_header Cache-Control "no-cache";
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOF'

echo -e "${GREEN}✅ Nouvelle config créée${NC}"
echo ""

# 5. Recréer le lien symbolique
echo -e "${YELLOW}5️⃣ Création lien symbolique...${NC}"
sudo ln -sf /etc/nginx/sites-available/signfast /etc/nginx/sites-enabled/signfast
echo -e "${GREEN}✅ Lien symbolique créé${NC}"
echo ""

# 6. Vérifier la config
echo -e "${YELLOW}6️⃣ Test configuration...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}✅ Configuration valide${NC}"
else
    echo -e "${RED}❌ Configuration invalide${NC}"
    exit 1
fi
echo ""

# 7. Afficher la config
echo -e "${YELLOW}7️⃣ Vérification du contenu...${NC}"
echo "─────────────────────────────────────"
sudo cat /etc/nginx/sites-available/signfast | grep "root"
echo "─────────────────────────────────────"
echo ""

# 8. Redémarrer Nginx
echo -e "${YELLOW}8️⃣ Redémarrage Nginx...${NC}"
sudo systemctl start nginx
sudo systemctl status nginx --no-pager -l
echo -e "${GREEN}✅ Nginx redémarré${NC}"
echo ""

# 9. Test final
echo -e "${YELLOW}9️⃣ Test final...${NC}"
if sudo nginx -T 2>/dev/null | grep -q "root /var/www/SignFastv2/dist"; then
    echo -e "${GREEN}✅ Nginx pointe maintenant vers /var/www/SignFastv2/dist${NC}"
else
    echo -e "${RED}❌ Échec - Nginx ne pointe toujours pas vers le bon dossier${NC}"
fi
echo ""

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        ✅ MISE À JOUR FORCÉE TERMINÉE ! ✅                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
