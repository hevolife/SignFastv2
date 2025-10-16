#!/bin/bash

#############################################
# 🚀 Déploiement depuis GitHub
# Récupère les dernières modifications et déploie
#############################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

APP_DIR="/var/www/signfast"
BACKUP_DIR="/var/backups/signfast"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$APP_DIR/logs/deploy.log"

# Créer le dossier de logs
mkdir -p "$APP_DIR/logs"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERREUR]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[ATTENTION]${NC} $1" | tee -a "$LOG_FILE"
}

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}🚀 DÉPLOIEMENT DEPUIS GITHUB${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

cd "$APP_DIR"
print_header

log "Début du déploiement - $DATE"

# 1. Vérifier les modifications disponibles
log "🔍 Vérification des mises à jour sur GitHub..."
git fetch origin

CURRENT_COMMIT=$(git rev-parse HEAD)
REMOTE_COMMIT=$(git rev-parse origin/main)

if [ "$CURRENT_COMMIT" = "$REMOTE_COMMIT" ]; then
    log "✅ Aucune mise à jour disponible"
    log "Version actuelle : $(git log -1 --oneline)"
    exit 0
fi

log "📦 Nouvelles modifications disponibles :"
git log --oneline HEAD..origin/main | tee -a "$LOG_FILE"
echo ""

# 2. Créer une sauvegarde
log "💾 Création de la sauvegarde..."
mkdir -p "$BACKUP_DIR"

if [ -d "dist" ]; then
    tar -czf "$BACKUP_DIR/signfast_pre_deploy_$DATE.tar.gz" dist/ .env 2>/dev/null || true
    log "✅ Sauvegarde créée"
fi

# 3. Arrêter l'application
log "⏹️  Arrêt de l'application..."
pm2 stop signfast || log_warning "Application déjà arrêtée"

# 4. Sauvegarder l'ancien build
if [ -d "dist" ]; then
    mv dist "dist.old.$DATE"
    log "📦 Ancien build sauvegardé"
fi

# 5. Récupérer les modifications
log "📥 Récupération des modifications depuis GitHub..."
if git pull origin main; then
    log "✅ Code mis à jour"
    UPDATED_COMMIT=$(git rev-parse HEAD)
    log "Nouveau commit : $(git log -1 --oneline)"
else
    log_error "Échec de la récupération du code"
    
    # Rollback
    log_warning "🔄 Restauration..."
    if [ -d "dist.old.$DATE" ]; then
        rm -rf dist
        mv "dist.old.$DATE" dist
    fi
    pm2 start signfast
    exit 1
fi

# 6. Vérifier si package.json a changé
log "📦 Vérification des dépendances..."
if git diff --name-only "$CURRENT_COMMIT" "$UPDATED_COMMIT" | grep -q "package.json"; then
    log "📦 Installation des nouvelles dépendances..."
    if npm ci; then
        log "✅ Dépendances installées"
    else
        log_warning "npm ci a échoué, tentative avec npm install..."
        npm install
    fi
else
    log "✅ Aucune nouvelle dépendance"
fi

# 7. Builder l'application
log "🔨 Build de l'application..."
if npm run build; then
    log "✅ Build réussi"
else
    log_error "Échec du build"
    
    # Rollback
    log_warning "🔄 Restauration..."
    git reset --hard "$CURRENT_COMMIT"
    rm -rf dist
    if [ -d "dist.old.$DATE" ]; then
        mv "dist.old.$DATE" dist
    fi
    pm2 start signfast
    exit 1
fi

# 8. Vérifier le build
if [ ! -d "dist" ] || [ ! -f "dist/index.html" ]; then
    log_error "Build invalide"
    
    # Rollback
    git reset --hard "$CURRENT_COMMIT"
    rm -rf dist
    if [ -d "dist.old.$DATE" ]; then
        mv "dist.old.$DATE" dist
    fi
    pm2 start signfast
    exit 1
fi

# 9. Corriger les permissions
log "🔐 Correction des permissions..."
sudo chown -R www-data:www-data dist/
sudo chmod -R 755 dist/

# 10. Redémarrer l'application
log "🚀 Redémarrage de l'application..."
pm2 start signfast
sleep 5

# 11. Vérifier que ça fonctionne
if pm2 list | grep -q "online.*signfast"; then
    log "✅ Application en ligne"
    
    # Test de santé
    if curl -f http://localhost:3000 > /dev/null 2>&1; then
        log "✅ Application accessible"
    else
        log_warning "⚠️  Application non accessible localement"
    fi
    
    # Nettoyer
    if [ -d "dist.old.$DATE" ]; then
        rm -rf "dist.old.$DATE"
    fi
    
    # Nettoyer anciennes sauvegardes (garder 7 dernières)
    find "$BACKUP_DIR" -name "signfast_pre_deploy_*.tar.gz" -mtime +7 -delete 2>/dev/null || true
    
else
    log_error "Application non démarrée"
    
    # Rollback complet
    pm2 stop signfast
    git reset --hard "$CURRENT_COMMIT"
    rm -rf dist
    if [ -d "dist.old.$DATE" ]; then
        mv "dist.old.$DATE" dist
    fi
    pm2 start signfast
    
    log_error "Déploiement annulé"
    exit 1
fi

# 12. Résumé
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║        🎉 DÉPLOIEMENT RÉUSSI ! 🎉                         ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

log "📊 Résumé :"
echo "  - Ancien commit : ${CURRENT_COMMIT:0:7}"
echo "  - Nouveau commit : ${UPDATED_COMMIT:0:7}"
echo "  - Sauvegarde : $BACKUP_DIR/signfast_pre_deploy_$DATE.tar.gz"
echo ""

log "🔍 Statut :"
pm2 status

log "✅ Déploiement terminé - $DATE"
