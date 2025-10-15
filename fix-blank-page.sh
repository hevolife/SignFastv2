#!/bin/bash

echo "🔧 === FIX PAGE BLANCHE SIGNFAST ==="

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

APP_DIR="/var/www/signfast"

# 1. Vérifier les logs PM2
echo -e "\n${YELLOW}1. Logs PM2 actuels...${NC}"
sudo -u signfast pm2 logs signfast --lines 30 --nostream

# 2. Vérifier le build actuel
echo -e "\n${YELLOW}2. Contenu du build actuel...${NC}"
if [ -f "$APP_DIR/dist/index.html" ]; then
    echo -e "${GREEN}✓ index.html existe${NC}"
    echo "Premières lignes:"
    head -20 "$APP_DIR/dist/index.html"
else
    echo -e "${RED}✗ index.html manquant${NC}"
fi

# 3. Vérifier les variables d'environnement
echo -e "\n${YELLOW}3. Variables d'environnement...${NC}"
if [ -f "$APP_DIR/.env.production" ]; then
    echo -e "${GREEN}✓ .env.production existe${NC}"
    cat "$APP_DIR/.env.production"
else
    echo -e "${RED}✗ .env.production manquant${NC}"
fi

# 4. Créer/Vérifier .env.production
echo -e "\n${YELLOW}4. Configuration .env.production...${NC}"
sudo -u signfast tee "$APP_DIR/.env.production" > /dev/null <<'EOF'
NODE_ENV=production
VITE_SUPABASE_URL=https://signfast.hevolife.fr
VITE_SUPABASE_ANON_KEY=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsImlhdCI6MTc1OTA5MTIyMCwiZXhwIjo0OTE0NzY0ODIwLCJyb2xlIjoiYW5vbiJ9.4BQ0CUqu4P-4rkgEsI9TtH2Oby81Ry81qh0a6353drY
EOF
echo -e "${GREEN}✓ .env.production créé${NC}"

# 5. Vérifier vite.config.ts
echo -e "\n${YELLOW}5. Vérification vite.config.ts...${NC}"
if [ -f "$APP_DIR/vite.config.ts" ]; then
    echo -e "${GREEN}✓ vite.config.ts existe${NC}"
    grep -A 5 "base:" "$APP_DIR/vite.config.ts" || echo "Pas de base path défini"
else
    echo -e "${RED}✗ vite.config.ts manquant${NC}"
fi

# 6. Nettoyer et rebuild
echo -e "\n${YELLOW}6. Nettoyage et rebuild...${NC}"
cd "$APP_DIR"

# Nettoyer
echo "Nettoyage des anciens builds..."
sudo -u signfast rm -rf dist/
sudo -u signfast rm -rf node_modules/.vite/

# Rebuild avec les variables d'environnement
echo "Build de production..."
sudo -u signfast NODE_ENV=production npm run build

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Build réussi${NC}"
    echo "Contenu du nouveau build:"
    ls -lh dist/ | head -15
else
    echo -e "${RED}✗ Erreur de build${NC}"
    exit 1
fi

# 7. Vérifier les permissions
echo -e "\n${YELLOW}7. Vérification permissions...${NC}"
sudo chown -R signfast:signfast "$APP_DIR/dist"
sudo chmod -R 755 "$APP_DIR/dist"
echo -e "${GREEN}✓ Permissions OK${NC}"

# 8. Redémarrer PM2
echo -e "\n${YELLOW}8. Redémarrage PM2...${NC}"
sudo -u signfast pm2 restart signfast
sleep 3
sudo -u signfast pm2 status

# 9. Test local
echo -e "\n${YELLOW}9. Test application locale...${NC}"
sleep 2
if curl -f -s http://localhost:3000 | grep -q "<!doctype html>"; then
    echo -e "${GREEN}✓ Application répond correctement${NC}"
else
    echo -e "${RED}✗ Application ne répond pas correctement${NC}"
    echo "Logs PM2:"
    sudo -u signfast pm2 logs signfast --lines 20 --nostream
fi

# 10. Recharger Nginx
echo -e "\n${YELLOW}10. Rechargement Nginx...${NC}"
sudo nginx -t && sudo systemctl reload nginx
echo -e "${GREEN}✓ Nginx rechargé${NC}"

# 11. Test final HTTPS
echo -e "\n${YELLOW}11. Test final HTTPS...${NC}"
sleep 2
if curl -f -s https://signfast.pro | grep -q "<!doctype html>"; then
    echo -e "${GREEN}✓ Site accessible et HTML valide${NC}"
else
    echo -e "${RED}✗ Problème d'accès HTTPS${NC}"
fi

echo -e "\n${GREEN}=== FIX TERMINÉ ===${NC}"
echo -e "\n📊 Vérifications:"
echo "  1. Ouvrez https://signfast.pro dans votre navigateur"
echo "  2. Ouvrez la Console (F12) et vérifiez les erreurs JavaScript"
echo "  3. Vérifiez l'onglet Network pour voir si les fichiers se chargent"
echo ""
echo "📝 Commandes utiles:"
echo "  - Logs PM2: sudo -u signfast pm2 logs signfast"
echo "  - Logs Nginx: sudo tail -f /var/log/nginx/error.log"
echo "  - Rebuild: cd $APP_DIR && sudo -u signfast npm run build"
