#!/bin/bash

#############################################
# 🔧 Configuration initiale GitHub sur VPS
#############################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🔧 CONFIGURATION GITHUB POUR SIGNFAST${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# 1. Vérifier Git
echo -e "${YELLOW}1️⃣ Vérification de Git...${NC}"
if ! command -v git &> /dev/null; then
    echo "📦 Installation de Git..."
    sudo apt update
    sudo apt install -y git
fi
git --version
echo ""

# 2. Configurer Git
echo -e "${YELLOW}2️⃣ Configuration Git...${NC}"
read -p "Votre nom (pour Git) : " GIT_NAME
read -p "Votre email (pour Git) : " GIT_EMAIL

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
echo -e "${GREEN}✅ Git configuré${NC}"
echo ""

# 3. Générer clé SSH pour GitHub
echo -e "${YELLOW}3️⃣ Génération clé SSH pour GitHub...${NC}"
if [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f ~/.ssh/id_ed25519 -N ""
    echo -e "${GREEN}✅ Clé SSH générée${NC}"
else
    echo -e "${GREEN}✅ Clé SSH existe déjà${NC}"
fi
echo ""

# 4. Afficher la clé publique
echo -e "${YELLOW}4️⃣ Votre clé SSH publique (à ajouter sur GitHub) :${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
cat ~/.ssh/id_ed25519.pub
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}📋 ÉTAPES À SUIVRE :${NC}"
echo "1. Copiez la clé SSH ci-dessus"
echo "2. Allez sur GitHub → Settings → SSH and GPG keys"
echo "3. Cliquez sur 'New SSH key'"
echo "4. Collez la clé et donnez-lui un nom (ex: VPS SignFast)"
echo "5. Cliquez sur 'Add SSH key'"
echo ""

read -p "Appuyez sur Entrée quand vous avez ajouté la clé sur GitHub..."

# 5. Tester la connexion GitHub
echo -e "${YELLOW}5️⃣ Test de connexion à GitHub...${NC}"
ssh -T git@github.com || true
echo ""

# 6. Demander l'URL du repo
echo -e "${YELLOW}6️⃣ Configuration du repository...${NC}"
read -p "URL SSH de votre repo GitHub (ex: git@github.com:username/signfast.git) : " REPO_URL

# 7. Sauvegarder l'ancien dossier
if [ -d "/var/www/signfast" ]; then
    echo -e "${YELLOW}💾 Sauvegarde de l'ancien dossier...${NC}"
    sudo mv /var/www/signfast /var/www/signfast.backup.$(date +%Y%m%d_%H%M%S)
fi

# 8. Cloner le repo
echo -e "${YELLOW}7️⃣ Clonage du repository...${NC}"
sudo mkdir -p /var/www
cd /var/www
sudo git clone "$REPO_URL" signfast
sudo chown -R signfast:signfast /var/www/signfast
cd /var/www/signfast

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║        ✅ CONFIGURATION GITHUB TERMINÉE ! ✅              ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}📝 Prochaines étapes :${NC}"
echo "1. Créer le fichier .env avec vos variables"
echo "2. Lancer ./deploy-from-github.sh pour déployer"
echo ""
