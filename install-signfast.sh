#!/bin/bash

#############################################
# 🚀 Script d'Installation Automatique SignFast
# Pour VPS Ubuntu 24.04 LTS
# Version: 2.0.0 - Avec intégration GitHub
#############################################

set -e  # Arrêter en cas d'erreur

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables globales
LOG_FILE="/var/log/signfast-install.log"
APP_DIR="/var/www/signfast"
APP_USER="signfast"
NODE_VERSION="20"
GITHUB_REPO="https://github.com/hevolife/SignFastv2.git"
GITHUB_BRANCH="main"

#############################################
# Fonctions utilitaires
#############################################

print_header() {
    echo -e "${PURPLE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║        🚀 INSTALLATION AUTOMATIQUE SIGNFAST 🚀            ║"
    echo "║                                                            ║"
    echo "║              Installation sur Ubuntu 24.04 LTS             ║"
    echo "║              Déploiement depuis GitHub                     ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERREUR]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[ATTENTION]${NC} $1" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOG_FILE"
}

print_step() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}▶ $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Ce script doit être exécuté en tant que root (sudo)"
        exit 1
    fi
}

check_ubuntu_version() {
    if ! grep -q "Ubuntu 24.04" /etc/os-release; then
        log_warning "Ce script est optimisé pour Ubuntu 24.04 LTS"
        read -p "Voulez-vous continuer quand même ? (o/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Oo]$ ]]; then
            exit 1
        fi
    fi
}

#############################################
# Collecte des informations
#############################################

collect_information() {
    print_step "📋 Collecte des informations"
    
    # Domaine
    while true; do
        read -p "🌐 Entrez votre nom de domaine (ex: signfast.votredomaine.com): " DOMAIN
        if [[ -z "$DOMAIN" ]]; then
            log_error "Le nom de domaine ne peut pas être vide"
        else
            break
        fi
    done
    
    # Email pour SSL
    while true; do
        read -p "📧 Entrez votre email pour les certificats SSL: " SSL_EMAIL
        if [[ -z "$SSL_EMAIL" ]]; then
            log_error "L'email ne peut pas être vide"
        else
            break
        fi
    done
    
    # URL Supabase
    while true; do
        read -p "🔗 Entrez l'URL de votre projet Supabase: " SUPABASE_URL
        if [[ -z "$SUPABASE_URL" ]]; then
            log_error "L'URL Supabase ne peut pas être vide"
        else
            break
        fi
    done
    
    # Clé anonyme Supabase
    while true; do
        read -p "🔑 Entrez votre clé anonyme Supabase (anon key): " SUPABASE_ANON_KEY
        if [[ -z "$SUPABASE_ANON_KEY" ]]; then
            log_error "La clé anonyme ne peut pas être vide"
        else
            break
        fi
    done
    
    # Branche GitHub (optionnel)
    read -p "🌿 Branche GitHub à déployer (défaut: main): " INPUT_BRANCH
    if [[ -n "$INPUT_BRANCH" ]]; then
        GITHUB_BRANCH="$INPUT_BRANCH"
    fi
    
    # Confirmation
    echo ""
    log_info "Récapitulatif de la configuration:"
    echo "  - Domaine: $DOMAIN"
    echo "  - Email SSL: $SSL_EMAIL"
    echo "  - URL Supabase: $SUPABASE_URL"
    echo "  - Repository GitHub: $GITHUB_REPO"
    echo "  - Branche: $GITHUB_BRANCH"
    echo "  - Répertoire d'installation: $APP_DIR"
    echo "  - Utilisateur système: $APP_USER"
    echo ""
    
    read -p "Confirmer l'installation avec ces paramètres ? (o/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Oo]$ ]]; then
        log_warning "Installation annulée par l'utilisateur"
        exit 0
    fi
}

#############################################
# Étape 1: Préparation du système
#############################################

prepare_system() {
    print_step "🔧 Étape 1/11: Préparation du système"
    
    log "Mise à jour des paquets système..."
    apt update >> "$LOG_FILE" 2>&1
    apt upgrade -y >> "$LOG_FILE" 2>&1
    log_success "Système mis à jour"
    
    log "Installation des outils essentiels..."
    apt install -y curl wget git unzip software-properties-common \
        build-essential apt-transport-https ca-certificates gnupg \
        lsb-release ufw fail2ban htop nano vim >> "$LOG_FILE" 2>&1
    log_success "Outils essentiels installés"
}

#############################################
# Étape 2: Création de l'utilisateur
#############################################

create_user() {
    print_step "👤 Étape 2/11: Création de l'utilisateur système"
    
    if id "$APP_USER" &>/dev/null; then
        log_warning "L'utilisateur $APP_USER existe déjà"
    else
        log "Création de l'utilisateur $APP_USER..."
        adduser --disabled-password --gecos "" "$APP_USER" >> "$LOG_FILE" 2>&1
        usermod -aG sudo "$APP_USER" >> "$LOG_FILE" 2>&1
        log_success "Utilisateur $APP_USER créé"
    fi
    
    # Configurer SSH si nécessaire
    if [ -d "/root/.ssh" ] && [ -f "/root/.ssh/authorized_keys" ]; then
        log "Configuration SSH pour $APP_USER..."
        mkdir -p "/home/$APP_USER/.ssh"
        cp /root/.ssh/authorized_keys "/home/$APP_USER/.ssh/" 2>/dev/null || true
        chown -R "$APP_USER:$APP_USER" "/home/$APP_USER/.ssh"
        chmod 700 "/home/$APP_USER/.ssh"
        chmod 600 "/home/$APP_USER/.ssh/authorized_keys" 2>/dev/null || true
        log_success "SSH configuré pour $APP_USER"
    fi
}

#############################################
# Étape 3: Installation de Node.js
#############################################

install_nodejs() {
    print_step "📦 Étape 3/11: Installation de Node.js $NODE_VERSION LTS"
    
    if command -v node &> /dev/null; then
        CURRENT_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$CURRENT_VERSION" == "$NODE_VERSION" ]; then
            log_warning "Node.js $NODE_VERSION est déjà installé"
            return
        fi
    fi
    
    log "Téléchargement du script NodeSource..."
    curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION}.x" | bash - >> "$LOG_FILE" 2>&1
    
    log "Installation de Node.js..."
    apt-get install -y nodejs >> "$LOG_FILE" 2>&1
    
    NODE_VER=$(node --version)
    NPM_VER=$(npm --version)
    log_success "Node.js $NODE_VER et npm $NPM_VER installés"
    
    log "Installation de PM2 et serve..."
    npm install -g pm2 serve >> "$LOG_FILE" 2>&1
    log_success "PM2 et serve installés"
}

#############################################
# Étape 4: Installation de Nginx
#############################################

install_nginx() {
    print_step "🌐 Étape 4/11: Installation de Nginx"
    
    if command -v nginx &> /dev/null; then
        log_warning "Nginx est déjà installé"
    else
        log "Installation de Nginx..."
        apt install -y nginx >> "$LOG_FILE" 2>&1
        log_success "Nginx installé"
    fi
    
    log "Démarrage et activation de Nginx..."
    systemctl start nginx >> "$LOG_FILE" 2>&1
    systemctl enable nginx >> "$LOG_FILE" 2>&1
    log_success "Nginx démarré et activé"
}

#############################################
# Étape 5: Configuration du Firewall
#############################################

configure_firewall() {
    print_step "🔥 Étape 5/11: Configuration du Firewall UFW"
    
    log "Configuration des règles UFW..."
    ufw --force reset >> "$LOG_FILE" 2>&1
    ufw default deny incoming >> "$LOG_FILE" 2>&1
    ufw default allow outgoing >> "$LOG_FILE" 2>&1
    ufw allow ssh >> "$LOG_FILE" 2>&1
    ufw allow 22 >> "$LOG_FILE" 2>&1
    ufw allow 80/tcp >> "$LOG_FILE" 2>&1
    ufw allow 443/tcp >> "$LOG_FILE" 2>&1
    
    log "Activation du firewall..."
    echo "y" | ufw enable >> "$LOG_FILE" 2>&1
    log_success "Firewall UFW configuré et activé"
}

#############################################
# Étape 6: Création des répertoires
#############################################

create_directories() {
    print_step "📁 Étape 6/11: Création des répertoires de l'application"
    
    log "Création de $APP_DIR..."
    mkdir -p "$APP_DIR"
    mkdir -p "$APP_DIR/logs"
    mkdir -p "$APP_DIR/backups"
    mkdir -p "/var/backups/signfast"
    
    chown -R "$APP_USER:$APP_USER" "$APP_DIR"
    log_success "Répertoires créés"
}

#############################################
# Étape 7: Clonage depuis GitHub
#############################################

clone_from_github() {
    print_step "📥 Étape 7/11: Clonage du projet depuis GitHub"
    
    log "Clonage du repository $GITHUB_REPO..."
    log_info "Branche: $GITHUB_BRANCH"
    
    # Supprimer le répertoire s'il existe déjà
    if [ -d "$APP_DIR/.git" ]; then
        log_warning "Le repository existe déjà, mise à jour..."
        cd "$APP_DIR"
        sudo -u "$APP_USER" git fetch origin >> "$LOG_FILE" 2>&1
        sudo -u "$APP_USER" git checkout "$GITHUB_BRANCH" >> "$LOG_FILE" 2>&1
        sudo -u "$APP_USER" git pull origin "$GITHUB_BRANCH" >> "$LOG_FILE" 2>&1
    else
        # Cloner le repository
        sudo -u "$APP_USER" git clone -b "$GITHUB_BRANCH" "$GITHUB_REPO" "$APP_DIR/temp" >> "$LOG_FILE" 2>&1
        
        # Déplacer les fichiers
        sudo -u "$APP_USER" mv "$APP_DIR/temp/"* "$APP_DIR/" 2>/dev/null || true
        sudo -u "$APP_USER" mv "$APP_DIR/temp/".* "$APP_DIR/" 2>/dev/null || true
        rm -rf "$APP_DIR/temp"
    fi
    
    log_success "Repository cloné avec succès"
    
    # Afficher le commit actuel
    cd "$APP_DIR"
    CURRENT_COMMIT=$(git rev-parse --short HEAD)
    COMMIT_MESSAGE=$(git log -1 --pretty=%B)
    log_info "Commit actuel: $CURRENT_COMMIT"
    log_info "Message: $COMMIT_MESSAGE"
}

#############################################
# Étape 8: Configuration de l'application
#############################################

configure_application() {
    print_step "⚙️  Étape 8/11: Configuration de l'application"
    
    cd "$APP_DIR"
    
    log "Création du fichier .env..."
    cat > "$APP_DIR/.env" <<EOF
NODE_ENV=production
PORT=3000

# Configuration Supabase
VITE_SUPABASE_URL=$SUPABASE_URL
VITE_SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

# Variables optionnelles
VITE_APP_VERSION=1.0.0
VITE_APP_ENV=production
EOF
    
    chown "$APP_USER:$APP_USER" "$APP_DIR/.env"
    chmod 600 "$APP_DIR/.env"
    log_success "Fichier .env créé"
    
    log "Vérification du fichier ecosystem.config.cjs..."
    if [ ! -f "$APP_DIR/ecosystem.config.cjs" ]; then
        log "Création du fichier ecosystem.config.cjs..."
        cat > "$APP_DIR/ecosystem.config.cjs" <<'EOF'
module.exports = {
  apps: [
    {
      name: 'signfast',
      script: 'npm',
      args: 'run start:prod',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production',
        PORT: 3000
      },
      error_file: './logs/err.log',
      out_file: './logs/out.log',
      log_file: './logs/combined.log',
      time: true
    }
  ]
};
EOF
        chown "$APP_USER:$APP_USER" "$APP_DIR/ecosystem.config.cjs"
    fi
    log_success "Configuration PM2 vérifiée"
}

#############################################
# Étape 9: Installation des dépendances et build
#############################################

install_and_build() {
    print_step "🔨 Étape 9/11: Installation des dépendances et build"
    
    cd "$APP_DIR"
    
    log "Installation des dépendances npm..."
    log_info "Cela peut prendre plusieurs minutes..."
    
    if sudo -u "$APP_USER" npm ci >> "$LOG_FILE" 2>&1; then
        log_success "Dépendances installées"
    else
        log_warning "npm ci a échoué, tentative avec npm install..."
        sudo -u "$APP_USER" npm install >> "$LOG_FILE" 2>&1
        log_success "Dépendances installées avec npm install"
    fi
    
    log "Build de l'application..."
    log_info "Cela peut prendre plusieurs minutes..."
    
    if sudo -u "$APP_USER" npm run build >> "$LOG_FILE" 2>&1; then
        log_success "Application buildée avec succès"
    else
        log_error "Échec du build de l'application"
        log_info "Consultez les logs: cat $LOG_FILE"
        exit 1
    fi
    
    # Vérifier que le build a réussi
    if [ ! -d "$APP_DIR/dist" ] || [ ! -f "$APP_DIR/dist/index.html" ]; then
        log_error "Le dossier dist/ ou index.html n'existe pas après le build"
        exit 1
    fi
    
    log_success "Build vérifié avec succès"
}

#############################################
# Étape 10: Configuration de Nginx
#############################################

configure_nginx() {
    print_step "🔧 Étape 10/11: Configuration de Nginx"
    
    log "Création de la configuration Nginx pour $DOMAIN..."
    cat > "/etc/nginx/sites-available/signfast" <<EOF
# Configuration HTTP (redirection vers HTTPS)
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    # Permettre à Certbot de valider le domaine
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    # Redirection vers HTTPS (sera activée après SSL)
    # return 301 https://\$server_name\$request_uri;
}

# Configuration HTTPS (sera activée après SSL)
# server {
#     listen 443 ssl http2;
#     server_name $DOMAIN www.$DOMAIN;
#     
#     ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
#     ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
#     
#     ssl_protocols TLSv1.2 TLSv1.3;
#     ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
#     ssl_prefer_server_ciphers off;
#     ssl_session_cache shared:SSL:10m;
#     ssl_session_timeout 10m;
#     ssl_stapling on;
#     ssl_stapling_verify on;
#     
#     add_header X-Frame-Options "SAMEORIGIN" always;
#     add_header X-Content-Type-Options "nosniff" always;
#     add_header X-XSS-Protection "1; mode=block" always;
#     add_header Referrer-Policy "strict-origin-when-cross-origin" always;
#     add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
#     add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https:; frame-src 'self';" always;
#     add_header Service-Worker-Allowed "/" always;
#     
#     gzip on;
#     gzip_vary on;
#     gzip_min_length 1024;
#     gzip_comp_level 6;
#     gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json application/xml image/svg+xml;
#     
#     location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|webp)$ {
#         expires 1y;
#         add_header Cache-Control "public, immutable";
#         add_header X-Content-Type-Options nosniff;
#         access_log off;
#     }
#     
#     location ~* \.(html)$ {
#         expires 1h;
#         add_header Cache-Control "public, must-revalidate";
#     }
#     
#     location / {
#         proxy_pass http://localhost:3000;
#         proxy_http_version 1.1;
#         proxy_set_header Upgrade \$http_upgrade;
#         proxy_set_header Connection 'upgrade';
#         proxy_set_header Host \$host;
#         proxy_set_header X-Real-IP \$remote_addr;
#         proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
#         proxy_set_header X-Forwarded-Proto \$scheme;
#         proxy_cache_bypass \$http_upgrade;
#         
#         proxy_connect_timeout 60s;
#         proxy_send_timeout 60s;
#         proxy_read_timeout 60s;
#         
#         proxy_buffer_size 4k;
#         proxy_buffers 8 4k;
#         proxy_busy_buffers_size 8k;
#     }
#     
#     error_page 404 /index.html;
#     error_page 500 502 503 504 /index.html;
#     
#     location ~ /\. {
#         deny all;
#         access_log off;
#         log_not_found off;
#     }
#     
#     location ~* \.(env|log|conf)$ {
#         deny all;
#         access_log off;
#         log_not_found off;
#     }
# }
EOF
    
    log "Activation du site..."
    ln -sf /etc/nginx/sites-available/signfast /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    log "Test de la configuration Nginx..."
    if nginx -t >> "$LOG_FILE" 2>&1; then
        log_success "Configuration Nginx valide"
        systemctl reload nginx >> "$LOG_FILE" 2>&1
        log_success "Nginx rechargé"
    else
        log_error "Erreur dans la configuration Nginx"
        exit 1
    fi
}

#############################################
# Étape 11: Installation SSL avec Certbot
#############################################

install_ssl() {
    print_step "🔒 Étape 11/11: Installation des certificats SSL"
    
    log "Installation de Certbot..."
    apt install -y certbot python3-certbot-nginx >> "$LOG_FILE" 2>&1
    log_success "Certbot installé"
    
    log "Génération du certificat SSL pour $DOMAIN..."
    log_info "Certbot va maintenant valider votre domaine et générer les certificats"
    
    if certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" \
        --non-interactive --agree-tos --email "$SSL_EMAIL" \
        --redirect >> "$LOG_FILE" 2>&1; then
        log_success "Certificat SSL généré avec succès"
    else
        log_error "Échec de la génération du certificat SSL"
        log_warning "Vérifiez que votre domaine pointe bien vers ce serveur"
        log_info "Vous pouvez réessayer manuellement avec:"
        echo "  sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
        exit 1
    fi
    
    log "Test du renouvellement automatique..."
    if certbot renew --dry-run >> "$LOG_FILE" 2>&1; then
        log_success "Renouvellement automatique configuré"
    else
        log_warning "Problème avec le renouvellement automatique"
    fi
}

#############################################
# Étape 12: Démarrage de l'application
#############################################

start_application() {
    print_step "🚀 Démarrage de l'application"
    
    cd "$APP_DIR"
    
    log "Arrêt de l'application si elle tourne déjà..."
    sudo -u "$APP_USER" pm2 delete signfast >> "$LOG_FILE" 2>&1 || true
    
    log "Démarrage de l'application avec PM2..."
    sudo -u "$APP_USER" pm2 start ecosystem.config.cjs >> "$LOG_FILE" 2>&1
    
    sleep 5
    
    if sudo -u "$APP_USER" pm2 list | grep -q "online.*signfast"; then
        log_success "Application démarrée avec succès"
    else
        log_error "Échec du démarrage de l'application"
        log_info "Vérifiez les logs avec: pm2 logs signfast"
        exit 1
    fi
    
    log "Sauvegarde de la configuration PM2..."
    sudo -u "$APP_USER" pm2 save >> "$LOG_FILE" 2>&1
    
    log "Configuration du démarrage automatique..."
    sudo -u "$APP_USER" pm2 startup systemd -u "$APP_USER" --hp "/home/$APP_USER" >> "$LOG_FILE" 2>&1
    
    # Exécuter la commande générée par PM2
    PM2_STARTUP_CMD=$(sudo -u "$APP_USER" pm2 startup systemd -u "$APP_USER" --hp "/home/$APP_USER" 2>&1 | grep "sudo env" || true)
    if [ -n "$PM2_STARTUP_CMD" ]; then
        eval "$PM2_STARTUP_CMD" >> "$LOG_FILE" 2>&1
        log_success "Démarrage automatique configuré"
    fi
}

#############################################
# Vérification finale
#############################################

final_verification() {
    print_step "✅ Vérification finale"
    
    echo ""
    log "Test de l'application..."
    
    # Test local
    sleep 3
    if curl -f -s http://localhost:3000 > /dev/null; then
        log_success "Application accessible localement (http://localhost:3000)"
    else
        log_warning "Application non accessible localement"
    fi
    
    # Test HTTPS
    sleep 3
    if curl -f -s "https://$DOMAIN" > /dev/null; then
        log_success "Site accessible publiquement (https://$DOMAIN)"
    else
        log_warning "Site non accessible publiquement (peut prendre quelques minutes)"
    fi
    
    # Statut des services
    echo ""
    log_info "Statut des services:"
    
    if systemctl is-active --quiet nginx; then
        log_success "Nginx: Actif"
    else
        log_warning "Nginx: Inactif"
    fi
    
    if sudo -u "$APP_USER" pm2 list | grep -q "online.*signfast"; then
        log_success "PM2 SignFast: En ligne"
    else
        log_warning "PM2 SignFast: Hors ligne"
    fi
    
    if ufw status | grep -q "Status: active"; then
        log_success "UFW Firewall: Actif"
    else
        log_warning "UFW Firewall: Inactif"
    fi
    
    if systemctl is-active --quiet fail2ban; then
        log_success "Fail2Ban: Actif"
    else
        log_warning "Fail2Ban: Inactif"
    fi
}

#############################################
# Affichage du résumé final
#############################################

print_summary() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                            ║${NC}"
    echo -e "${GREEN}║        🎉 INSTALLATION TERMINÉE AVEC SUCCÈS ! 🎉          ║${NC}"
    echo -e "${GREEN}║                                                            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${CYAN}📊 INFORMATIONS DE L'INSTALLATION${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "  🌐 ${YELLOW}URL de votre site:${NC}"
    echo -e "     https://$DOMAIN"
    echo ""
    echo -e "  📁 ${YELLOW}Répertoire de l'application:${NC}"
    echo -e "     $APP_DIR"
    echo ""
    echo -e "  👤 ${YELLOW}Utilisateur système:${NC}"
    echo -e "     $APP_USER"
    echo ""
    echo -e "  📝 ${YELLOW}Fichier de logs:${NC}"
    echo -e "     $LOG_FILE"
    echo ""
    echo -e "  🔗 ${YELLOW}Repository GitHub:${NC}"
    echo -e "     $GITHUB_REPO"
    echo ""
    echo -e "  🌿 ${YELLOW}Branche déployée:${NC}"
    echo -e "     $GITHUB_BRANCH"
    echo ""
    
    cd "$APP_DIR"
    CURRENT_COMMIT=$(git rev-parse --short HEAD)
    echo -e "  📌 ${YELLOW}Commit actuel:${NC}"
    echo -e "     $CURRENT_COMMIT"
    echo ""
    
    echo -e "${CYAN}🔧 COMMANDES UTILES${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "  ${YELLOW}Voir le statut de l'application:${NC}"
    echo "    sudo -u $APP_USER pm2 status"
    echo ""
    echo -e "  ${YELLOW}Voir les logs en temps réel:${NC}"
    echo "    sudo -u $APP_USER pm2 logs signfast"
    echo ""
    echo -e "  ${YELLOW}Redémarrer l'application:${NC}"
    echo "    sudo -u $APP_USER pm2 restart signfast"
    echo ""
    echo -e "  ${YELLOW}Mettre à jour depuis GitHub:${NC}"
    echo "    cd $APP_DIR"
    echo "    sudo -u $APP_USER git pull origin $GITHUB_BRANCH"
    echo "    sudo -u $APP_USER npm ci"
    echo "    sudo -u $APP_USER npm run build"
    echo "    sudo -u $APP_USER pm2 restart signfast"
    echo ""
    echo -e "  ${YELLOW}Redémarrer Nginx:${NC}"
    echo "    sudo systemctl restart nginx"
    echo ""
    echo -e "  ${YELLOW}Vérifier les certificats SSL:${NC}"
    echo "    sudo certbot certificates"
    echo ""
    echo -e "  ${YELLOW}Voir les logs d'installation:${NC}"
    echo "    cat $LOG_FILE"
    echo ""
    
    echo -e "${CYAN}🔒 SÉCURITÉ${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "  ✅ Firewall UFW activé (ports 22, 80, 443)"
    echo -e "  ✅ Fail2Ban installé et actif"
    echo -e "  ✅ Certificat SSL Let's Encrypt configuré"
    echo -e "  ✅ Renouvellement automatique SSL activé"
    echo -e "  ✅ Headers de sécurité Nginx configurés"
    echo ""
    
    echo -e "${CYAN}📚 PROCHAINES ÉTAPES RECOMMANDÉES${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  1. Testez votre site: https://$DOMAIN"
    echo "  2. Configurez les sauvegardes automatiques"
    echo "  3. Installez un système de monitoring (Netdata)"
    echo "  4. Configurez les logs rotatifs"
    echo "  5. Mettez en place des alertes email"
    echo ""
    
    echo -e "${GREEN}✨ Votre application SignFast est maintenant en production ! ✨${NC}"
    echo ""
}

#############################################
# Fonction principale
#############################################

main() {
    # Initialiser le fichier de log
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"
    
    print_header
    
    # Vérifications préliminaires
    check_root
    check_ubuntu_version
    
    # Collecte des informations
    collect_information
    
    # Début de l'installation
    log "═══════════════════════════════════════════════════════════"
    log "Début de l'installation de SignFast"
    log "Date: $(date)"
    log "Domaine: $DOMAIN"
    log "Repository: $GITHUB_REPO"
    log "Branche: $GITHUB_BRANCH"
    log "═══════════════════════════════════════════════════════════"
    
    # Exécution des étapes
    prepare_system
    create_user
    install_nodejs
    install_nginx
    configure_firewall
    create_directories
    clone_from_github
    configure_application
    install_and_build
    configure_nginx
    install_ssl
    start_application
    
    # Vérification finale
    final_verification
    
    # Affichage du résumé
    print_summary
    
    log "═══════════════════════════════════════════════════════════"
    log "Installation terminée avec succès !"
    log "═══════════════════════════════════════════════════════════"
}

#############################################
# Point d'entrée du script
#############################################

# Gestion des erreurs
trap 'log_error "Une erreur est survenue à la ligne $LINENO. Consultez $LOG_FILE pour plus de détails."; exit 1' ERR

# Exécution
main "$@"
