#!/bin/bash

#############################################
# 🔄 Script de Mise à Jour SignFast
# Mise à jour depuis GitHub avec rollback automatique
#############################################

set -e  # Arrêter en cas d'erreur

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables
APP_DIR="/var/www/signfast"
BACKUP_DIR="/var/backups/signfast"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$APP_DIR/logs/update.log"

# Fonctions
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
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}🔄 MISE À JOUR SIGNFAST${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Vérifier qu'on est dans le bon répertoire
if [ ! -d "$APP_DIR" ]; then
    log_error "Répertoire $APP_DIR non trouvé"
    exit 1
fi

cd "$APP_DIR"

print_header

log "Début de la mise à jour - $DATE"

# 1. Vérifier les modifications GitHub
log_info "Vérification des mises à jour disponibles..."
git fetch origin

CURRENT_COMMIT=$(git rev-parse HEAD)
REMOTE_COMMIT=$(git rev-parse origin/main)

if [ "$CURRENT_COMMIT" = "$REMOTE_COMMIT" ]; then
    log_info "✅ Aucune mise à jour disponible"
    log_info "Version actuelle : $(git log -1 --oneline)"
    exit 0
fi

log_info "📦 Nouvelles mises à jour disponibles :"
git log --oneline HEAD..origin/main

# 2. Créer une sauvegarde
log "💾 Création de la sauvegarde..."
mkdir -p "$BACKUP_DIR"

if [ -d "dist" ]; then
    tar -czf "$BACKUP_DIR/signfast_pre_update_$DATE.tar.gz" dist/ .env 2>/dev/null || true
    log "✅ Sauvegarde créée : signfast_pre_update_$DATE.tar.gz"
else
    log_warning "Dossier dist/ non trouvé, sauvegarde ignorée"
fi

# 3. Arrêter l'application
log "⏹️  Arrêt de l'application..."
pm2 stop signfast || log_warning "Application déjà arrêtée"

# 4. Sauvegarder l'ancien build
if [ -d "dist" ]; then
    log "📦 Sauvegarde de l'ancien build..."
    mv dist "dist.old.$DATE"
fi

# 5. Récupérer les modifications GitHub
log "📥 Récupération des modifications depuis GitHub..."
if git pull origin main; then
    log "✅ Code mis à jour avec succès"
    UPDATED_COMMIT=$(git rev-parse HEAD)
    log_info "Nouveau commit : $(git log -1 --oneline)"
else
    log_error "Échec de la récupération du code"
    
    # Rollback
    log_warning "🔄 Restauration de l'ancien build..."
    if [ -d "dist.old.$DATE" ]; then
        rm -rf dist
        mv "dist.old.$DATE" dist
    fi
    pm2 start signfast
    exit 1
fi

# 6. Installer les dépendances
log "📦 Installation des dépendances..."
if npm ci; then
    log "✅ Dépendances installées"
else
    log_warning "npm ci a échoué, tentative avec npm install..."
    if npm install; then
        log "✅ Dépendances installées avec npm install"
    else
        log_error "Échec de l'installation des dépendances"
        
        # Rollback
        log_warning "🔄 Restauration de l'ancien build..."
        git reset --hard "$CURRENT_COMMIT"
        if [ -d "dist.old.$DATE" ]; then
            rm -rf dist
            mv "dist.old.$DATE" dist
        fi
        pm2 start signfast
        exit 1
    fi
fi

# 7. Builder l'application
log "🔨 Build de l'application..."
if npm run build; then
    log "✅ Build réussi"
else
    log_error "Échec du build"
    
    # Rollback
    log_warning "🔄 Restauration de l'ancien build..."
    git reset --hard "$CURRENT_COMMIT"
    rm -rf dist
    if [ -d "dist.old.$DATE" ]; then
        mv "dist.old.$DATE" dist
    fi
    pm2 start signfast
    exit 1
fi

# 8. Vérifier que le build a réussi
if [ ! -d "dist" ] || [ ! -f "dist/index.html" ]; then
    log_error "Le dossier dist/ ou index.html n'existe pas après le build"
    
    # Rollback
    log_warning "🔄 Restauration de l'ancien build..."
    git reset --hard "$CURRENT_COMMIT"
    rm -rf dist
    if [ -d "dist.old.$DATE" ]; then
        mv "dist.old.$DATE" dist
    fi
    pm2 start signfast
    exit 1
fi

# 9. Redémarrer l'application
log "🚀 Redémarrage de l'application..."
if pm2 start signfast; then
    log "✅ Application redémarrée"
else
    log_error "Échec du redémarrage"
    
    # Rollback
    log_warning "🔄 Restauration de l'ancien build..."
    git reset --hard "$CURRENT_COMMIT"
    rm -rf dist
    if [ -d "dist.old.$DATE" ]; then
        mv "dist.old.$DATE" dist
    fi
    pm2 start signfast
    exit 1
fi

# 10. Attendre que l'application démarre
log "⏳ Attente du démarrage de l'application..."
sleep 5

# 11. Vérifier que l'application fonctionne
if pm2 list | grep -q "online.*signfast"; then
    log "✅ Application en ligne"
    
    # Test de santé
    if curl -f http://localhost:3000 > /dev/null 2>&1; then
        log "✅ Application accessible sur http://localhost:3000"
    else
        log_warning "⚠️  Application non accessible localement"
    fi
    
    # Nettoyer l'ancien build
    log "🗑️  Nettoyage de l'ancien build..."
    if [ -d "dist.old.$DATE" ]; then
        rm -rf "dist.old.$DATE"
    fi
    
    # Nettoyer les anciennes sauvegardes (garder les 7 dernières)
    find "$BACKUP_DIR" -name "signfast_pre_update_*.tar.gz" -mtime +7 -delete 2>/dev/null || true
    
    log "✅ Nettoyage terminé"
    
else
    log_error "❌ Application non démarrée"
    
    # Rollback complet
    log_warning "🔄 Rollback complet..."
    pm2 stop signfast
    git reset --hard "$CURRENT_COMMIT"
    rm -rf dist
    if [ -d "dist.old.$DATE" ]; then
        mv "dist.old.$DATE" dist
    fi
    pm2 start signfast
    
    log_error "Mise à jour annulée, ancienne version restaurée"
    exit 1
fi

# 12. Afficher le résumé
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║        🎉 MISE À JOUR TERMINÉE AVEC SUCCÈS ! 🎉           ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

log_info "📊 Résumé de la mise à jour :"
echo "  - Ancien commit : ${CURRENT_COMMIT:0:7}"
echo "  - Nouveau commit : ${UPDATED_COMMIT:0:7}"
echo "  - Sauvegarde : $BACKUP_DIR/signfast_pre_update_$DATE.tar.gz"
echo ""

log_info "🔍 Vérifications :"
pm2 status
echo ""

log_info "📝 Derniers logs :"
pm2 logs signfast --lines 10 --nostream

echo ""
log "🎉 Mise à jour terminée avec succès - $DATE"
