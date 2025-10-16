#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
echo -e "${RED}🚨 ÉDITION MANUELLE REQUISE${NC}"
echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}Le fichier contient DEUX blocs server avec des root différents.${NC}"
echo -e "${YELLOW}Nous devons éditer manuellement le fichier.${NC}"
echo ""

# 1. Afficher le contenu actuel
echo -e "${BLUE}1️⃣ Contenu actuel du fichier :${NC}"
echo "─────────────────────────────────────"
sudo cat /etc/nginx/sites-available/signfast
echo "─────────────────────────────────────"
echo ""

# 2. Backup
echo -e "${YELLOW}2️⃣ Création d'un backup...${NC}"
sudo cp /etc/nginx/sites-available/signfast /etc/nginx/sites-available/signfast.backup.$(date +%Y%m%d_%H%M%S)
echo -e "${GREEN}✅ Backup créé${NC}"
echo ""

# 3. Créer le fichier CORRECT
echo -e "${YELLOW}3️⃣ Création du fichier CORRECT...${NC}"
sudo bash -c 'cat > /etc/nginx/sites-available/signfast.new << '\''EOF'\''
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

echo -e "${GREEN}✅ Nouveau fichier créé : /etc/nginx/sites-available/signfast.new${NC}"
echo ""

# 4. Comparer les deux
echo -e "${YELLOW}4️⃣ Comparaison ancien vs nouveau :${NC}"
echo ""
echo -e "${RED}ANCIEN (root) :${NC}"
sudo grep "root" /etc/nginx/sites-available/signfast | head -1
echo ""
echo -e "${GREEN}NOUVEAU (root) :${NC}"
sudo grep "root" /etc/nginx/sites-available/signfast.new
echo ""

# 5. Instructions pour remplacer
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}📝 INSTRUCTIONS POUR REMPLACER :${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Exécute ces commandes :${NC}"
echo ""
echo -e "${GREEN}sudo mv /etc/nginx/sites-available/signfast.new /etc/nginx/sites-available/signfast${NC}"
echo -e "${GREEN}sudo nginx -t${NC}"
echo -e "${GREEN}sudo systemctl reload nginx${NC}"
echo ""
echo -e "${YELLOW}Puis vérifie :${NC}"
echo ""
echo -e "${GREEN}sudo nginx -T 2>/dev/null | grep 'root' | grep -v '#'${NC}"
echo ""

# 6. Proposer le remplacement automatique
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🤖 OU REMPLACEMENT AUTOMATIQUE :${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
read -p "Veux-tu que je remplace automatiquement ? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Remplacement en cours...${NC}"
    
    sudo mv /etc/nginx/sites-available/signfast.new /etc/nginx/sites-available/signfast
    
    echo -e "${YELLOW}Test de la config...${NC}"
    if sudo nginx -t; then
        echo -e "${GREEN}✅ Config valide${NC}"
        
        echo -e "${YELLOW}Rechargement de Nginx...${NC}"
        sudo systemctl reload nginx
        
        echo -e "${YELLOW}Vérification finale...${NC}"
        sleep 2
        ACTIVE_ROOT=$(sudo nginx -T 2>/dev/null | grep "root" | grep -v "#" | head -1)
        echo "Config active : $ACTIVE_ROOT"
        
        if echo "$ACTIVE_ROOT" | grep -q "/var/www/SignFastv2/dist"; then
            echo ""
            echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${GREEN}║           ✅✅✅ SUCCÈS ! ✅✅✅                        ║${NC}"
            echo -e "${GREEN}║     Nginx pointe maintenant vers SignFastv2 !            ║${NC}"
            echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
            echo ""
            echo -e "${BLUE}🌐 Teste maintenant : https://signfast.pro${NC}"
        else
            echo -e "${RED}❌ Échec - Vérification manuelle requise${NC}"
        fi
    else
        echo -e "${RED}❌ Erreur dans la config - Restauration du backup${NC}"
        sudo cp /etc/nginx/sites-available/signfast.backup.* /etc/nginx/sites-available/signfast
    fi
else
    echo -e "${YELLOW}OK, remplace manuellement avec les commandes ci-dessus.${NC}"
fi
