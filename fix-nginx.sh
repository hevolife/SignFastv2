#!/bin/bash

echo "🔧 === FIX NGINX POUR SIGNFAST ==="

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Vérifier PM2
echo -e "\n${YELLOW}1. Vérification PM2...${NC}"
if sudo -u signfast pm2 list | grep -q "signfast"; then
    echo -e "${GREEN}✓ PM2 process trouvé${NC}"
    sudo -u signfast pm2 status
else
    echo -e "${RED}✗ PM2 process non trouvé${NC}"
    echo "Démarrage de l'application..."
    cd /var/www/signfast
    sudo -u signfast pm2 start ecosystem.config.cjs
fi

# 2. Tester l'application localement
echo -e "\n${YELLOW}2. Test application locale...${NC}"
sleep 3
if curl -f -s http://localhost:3000 > /dev/null; then
    echo -e "${GREEN}✓ Application répond sur localhost:3000${NC}"
else
    echo -e "${RED}✗ Application ne répond pas${NC}"
    echo "Logs PM2:"
    sudo -u signfast pm2 logs signfast --lines 20 --nostream
fi

# 3. Vérifier les fichiers build
echo -e "\n${YELLOW}3. Vérification fichiers build...${NC}"
if [ -d "/var/www/signfast/dist" ] && [ -f "/var/www/signfast/dist/index.html" ]; then
    echo -e "${GREEN}✓ Dossier dist/ existe${NC}"
    ls -lh /var/www/signfast/dist/ | head -10
else
    echo -e "${RED}✗ Dossier dist/ manquant ou incomplet${NC}"
    echo "Lancement du build..."
    cd /var/www/signfast
    sudo -u signfast npm run build
fi

# 4. Supprimer le site par défaut Nginx
echo -e "\n${YELLOW}4. Suppression site par défaut Nginx...${NC}"
if [ -f "/etc/nginx/sites-enabled/default" ]; then
    sudo rm /etc/nginx/sites-enabled/default
    echo -e "${GREEN}✓ Site par défaut supprimé${NC}"
else
    echo -e "${GREEN}✓ Site par défaut déjà supprimé${NC}"
fi

# 5. Créer/Vérifier la config SignFast
echo -e "\n${YELLOW}5. Configuration Nginx pour SignFast...${NC}"

# Créer la config complète
sudo tee /etc/nginx/sites-available/signfast > /dev/null <<'EOF'
# Configuration HTTP (redirection vers HTTPS)
server {
    listen 80;
    listen [::]:80;
    server_name signfast.pro www.signfast.pro;
    
    # Permettre à Certbot de valider le domaine
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    # Redirection vers HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# Configuration HTTPS
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name signfast.pro www.signfast.pro;
    
    # Certificats SSL
    ssl_certificate /etc/letsencrypt/live/signfast.pro/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/signfast.pro/privkey.pem;
    
    # Configuration SSL moderne
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Headers de sécurité
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Compression Gzip
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json application/xml image/svg+xml;
    
    # Cache pour les assets statiques
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|webp)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # Proxy vers l'application PM2
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Gestion des erreurs (SPA)
    error_page 404 /index.html;
    
    # Bloquer les fichiers sensibles
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF

echo -e "${GREEN}✓ Configuration Nginx créée${NC}"

# 6. Activer le site SignFast
echo -e "\n${YELLOW}6. Activation du site SignFast...${NC}"
sudo ln -sf /etc/nginx/sites-available/signfast /etc/nginx/sites-enabled/
echo -e "${GREEN}✓ Site activé${NC}"

# 7. Tester la configuration Nginx
echo -e "\n${YELLOW}7. Test configuration Nginx...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}✓ Configuration Nginx valide${NC}"
else
    echo -e "${RED}✗ Erreur dans la configuration Nginx${NC}"
    exit 1
fi

# 8. Redémarrer Nginx
echo -e "\n${YELLOW}8. Redémarrage Nginx...${NC}"
sudo systemctl restart nginx
echo -e "${GREEN}✓ Nginx redémarré${NC}"

# 9. Vérification finale
echo -e "\n${YELLOW}9. Vérification finale...${NC}"
sleep 3

# Test HTTPS
if curl -f -s https://signfast.pro > /dev/null; then
    echo -e "${GREEN}✓ Site accessible sur https://signfast.pro${NC}"
else
    echo -e "${RED}✗ Site non accessible${NC}"
    echo "Vérification des logs Nginx:"
    sudo tail -20 /var/log/nginx/error.log
fi

echo -e "\n${GREEN}=== FIX TERMINÉ ===${NC}"
echo -e "\n📊 Statut des services:"
echo "  - PM2: $(sudo -u signfast pm2 list | grep signfast | awk '{print $10}')"
echo "  - Nginx: $(sudo systemctl is-active nginx)"
echo ""
echo "🌐 Testez votre site: https://signfast.pro"
echo "📝 Logs PM2: sudo -u signfast pm2 logs signfast"
echo "📝 Logs Nginx: sudo tail -f /var/log/nginx/error.log"
