#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🔧 SUPPRESSION CONFIGS NGINX EN DOUBLE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# 1. Lister toutes les configs
echo -e "${YELLOW}1️⃣ Configs actuelles :${NC}"
echo "─────────────────────────────────────"
ls -la /etc/nginx/sites-available/ | grep -i sign || echo "Aucune config signfast"
ls -la /etc/nginx/sites-enabled/ | grep -i sign || echo "Aucun lien signfast"
echo ""

# 2. Arrêter Nginx
echo -e "${YELLOW}2️⃣ Arrêt de Nginx...${NC}"
sudo systemctl stop nginx
echo -e "${GREEN}✅ Nginx arrêté${NC}"
echo ""

# 3. Backup de TOUTES les configs
echo -e "${YELLOW}3️⃣ Sauvegarde de toutes les configs...${NC}"
BACKUP_DIR="/etc/nginx/backup_$(date +%Y%m%d_%H%M%S)"
sudo mkdir -p "$BACKUP_DIR"
sudo cp -r /etc/nginx/sites-available/* "$BACKUP_DIR/" 2>/dev/null || true
sudo cp -r /etc/nginx/sites-enabled/* "$BACKUP_DIR/" 2>/dev/null || true
echo -e "${GREEN}✅ Backup créé dans $BACKUP_DIR${NC}"
echo ""

# 4. Supprimer TOUTES les configs signfast
echo -e "${YELLOW}4️⃣ Suppression de TOUTES les configs signfast...${NC}"
sudo rm -f /etc/nginx/sites-available/signfast*
sudo rm -f /etc/nginx/sites-enabled/signfast*
echo -e "${GREEN}✅ Toutes les configs supprimées${NC}"
echo ""

# 5. Créer LA SEULE ET UNIQUE config
echo -e "${YELLOW}5️⃣ Création de la config unique...${NC}"
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

echo -e "${GREEN}✅ Config unique créée${NC}"
echo ""

# 6. Créer le lien symbolique
echo -e "${YELLOW}6️⃣ Création du lien symbolique...${NC}"
sudo ln -sf /etc/nginx/sites-available/signfast /etc/nginx/sites-enabled/signfast
echo -e "${GREEN}✅ Lien créé${NC}"
echo ""

# 7. Vérifier qu'il n'y a qu'UNE SEULE config
echo -e "${YELLOW}7️⃣ Vérification unicité...${NC}"
SIGNFAST_CONFIGS=$(ls /etc/nginx/sites-available/ | grep -i sign | wc -l)
if [ "$SIGNFAST_CONFIGS" -eq 1 ]; then
    echo -e "${GREEN}✅ Une seule config signfast trouvée${NC}"
else
    echo -e "${RED}❌ Plusieurs configs trouvées : $SIGNFAST_CONFIGS${NC}"
    ls -la /etc/nginx/sites-available/ | grep -i sign
fi
echo ""

# 8. Test de la config
echo -e "${YELLOW}8️⃣ Test de la configuration...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}✅ Configuration valide${NC}"
else
    echo -e "${RED}❌ Configuration invalide${NC}"
    exit 1
fi
echo ""

# 9. Afficher le contenu
echo -e "${YELLOW}9️⃣ Contenu de la config :${NC}"
echo "─────────────────────────────────────"
sudo cat /etc/nginx/sites-available/signfast | grep "root"
echo "─────────────────────────────────────"
echo ""

# 10. Redémarrer Nginx
echo -e "${YELLOW}🔟 Redémarrage de Nginx...${NC}"
sudo systemctl start nginx
sudo systemctl status nginx --no-pager -l
echo -e "${GREEN}✅ Nginx redémarré${NC}"
echo ""

# 11. Vérification finale
echo -e "${YELLOW}1️⃣1️⃣ Vérification finale...${NC}"
sleep 2
ACTIVE_ROOT=$(sudo nginx -T 2>/dev/null | grep "root" | grep -v "#" | head -1)
echo "Config active : $ACTIVE_ROOT"

if echo "$ACTIVE_ROOT" | grep -q "/var/www/SignFastv2/dist"; then
    echo -e "${GREEN}✅✅✅ SUCCÈS ! Nginx pointe vers SignFastv2 !${NC}"
else
    echo -e "${RED}❌ Échec - Nginx ne pointe toujours pas vers SignFastv2${NC}"
    echo "Contenu complet :"
    sudo nginx -T 2>/dev/null | grep -A 3 "root"
fi
echo ""

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              ✅ NETTOYAGE TERMINÉ ! ✅                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
