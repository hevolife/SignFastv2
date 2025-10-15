# 🚀 Guide d'Installation Complet - SignFast

## 📋 Table des Matières

1. [Prérequis](#prérequis)
2. [Installation Automatique](#installation-automatique)
3. [Installation Manuelle](#installation-manuelle)
4. [Configuration Supabase](#configuration-supabase)
5. [Système de Mise à Jour GitHub](#système-de-mise-à-jour-github)
6. [Maintenance et Monitoring](#maintenance-et-monitoring)
7. [Dépannage](#dépannage)

---

## 📋 Prérequis

### Serveur VPS
- **OS** : Ubuntu 24.04 LTS (recommandé) ou Ubuntu 22.04 LTS
- **RAM** : Minimum 2GB (4GB recommandé)
- **CPU** : 2 vCPU minimum
- **Stockage** : 20GB SSD minimum
- **Bande passante** : Illimitée

### Domaine et DNS
- Nom de domaine (ex: signfast.votredomaine.com)
- Accès aux paramètres DNS de votre domaine
- Enregistrement A pointant vers l'IP de votre VPS

### Compte Supabase
- Projet Supabase créé sur [supabase.com](https://supabase.com)
- URL du projet (ex: https://xxxxx.supabase.co)
- Clé anonyme (anon key)

### Accès SSH
- Accès root ou sudo au serveur
- Clé SSH configurée (recommandé)

---

## 🤖 Installation Automatique (Recommandé)

### Étape 1 : Télécharger le script d'installation

```bash
# Se connecter au serveur
ssh root@VOTRE_IP_VPS

# Télécharger le script
wget https://raw.githubusercontent.com/hevolife/SignFastv2/main/install-signfast.sh

# Rendre le script exécutable
chmod +x install-signfast.sh
```

### Étape 2 : Lancer l'installation

```bash
sudo ./install-signfast.sh
```

### Étape 3 : Suivre les instructions interactives

Le script vous demandera :

1. **Nom de domaine** : `signfast.votredomaine.com`
2. **Email SSL** : `votre@email.com` (pour Let's Encrypt)
3. **URL Supabase** : `https://xxxxx.supabase.co`
4. **Clé Supabase** : `eyJhbGc...` (votre anon key)
5. **Branche GitHub** : `main` (par défaut)

### Étape 4 : Attendre la fin de l'installation

Le script va automatiquement :
- ✅ Mettre à jour le système
- ✅ Installer Node.js 20 LTS
- ✅ Installer PM2 et serve
- ✅ Installer Nginx
- ✅ Configurer le firewall UFW
- ✅ Cloner le projet depuis GitHub
- ✅ Installer les dépendances
- ✅ Builder l'application
- ✅ Configurer Nginx
- ✅ Générer les certificats SSL
- ✅ Démarrer l'application

**Durée estimée** : 10-15 minutes

### Étape 5 : Vérification

Une fois terminé, vous verrez :

```
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║        🎉 INSTALLATION TERMINÉE AVEC SUCCÈS ! 🎉          ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝

🌐 URL de votre site:
   https://signfast.votredomaine.com
```

Testez votre site en ouvrant l'URL dans votre navigateur !

---

## 🔧 Installation Manuelle

Si vous préférez installer manuellement ou si le script automatique échoue :

### Étape 1 : Préparation du serveur

```bash
# Connexion SSH
ssh root@VOTRE_IP_VPS

# Mise à jour du système
sudo apt update && sudo apt upgrade -y

# Installation des outils essentiels
sudo apt install -y curl wget git unzip software-properties-common \
    build-essential apt-transport-https ca-certificates gnupg \
    lsb-release ufw fail2ban htop nano vim
```

### Étape 2 : Création de l'utilisateur

```bash
# Créer l'utilisateur signfast
sudo adduser signfast
sudo usermod -aG sudo signfast

# Passer à l'utilisateur signfast
su - signfast
```

### Étape 3 : Installation de Node.js

```bash
# Installer Node.js 20 LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Vérifier l'installation
node --version  # Doit afficher v20.x.x
npm --version   # Doit afficher 10.x.x

# Installer PM2 et serve
sudo npm install -g pm2 serve
```

### Étape 4 : Installation de Nginx

```bash
# Installer Nginx
sudo apt install -y nginx

# Démarrer et activer Nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

### Étape 5 : Configuration du Firewall

```bash
# Configurer UFW
sudo ufw allow ssh
sudo ufw allow 22
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Activer le firewall
sudo ufw enable
```

### Étape 6 : Clonage du projet

```bash
# Créer le répertoire
sudo mkdir -p /var/www/signfast
sudo chown signfast:signfast /var/www/signfast

# Cloner le projet
cd /var/www/signfast
git clone -b main https://github.com/hevolife/SignFastv2.git .

# Configurer Git safe.directory
git config --global --add safe.directory /var/www/signfast
```

### Étape 7 : Configuration de l'application

```bash
# Créer le fichier .env
nano /var/www/signfast/.env
```

**Contenu du fichier `.env` :**

```env
NODE_ENV=production
PORT=3000

# Configuration Supabase
VITE_SUPABASE_URL=https://xxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=votre_cle_anon_ici

# Variables optionnelles
VITE_APP_VERSION=1.0.0
VITE_APP_ENV=production
```

```bash
# Sécuriser le fichier
chmod 600 /var/www/signfast/.env
```

### Étape 8 : Installation et Build

```bash
cd /var/www/signfast

# Installer les dépendances
npm ci

# Builder l'application
npm run build

# Vérifier que le build a réussi
ls -la dist/
```

### Étape 9 : Configuration de Nginx

```bash
# Créer la configuration
sudo nano /etc/nginx/sites-available/signfast
```

**Contenu du fichier :**

```nginx
# Configuration HTTP (redirection vers HTTPS)
server {
    listen 80;
    server_name votredomaine.com www.votredomaine.com;
    
    # Permettre à Certbot de valider le domaine
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    # Redirection vers HTTPS (sera activée après SSL)
    return 301 https://$server_name$request_uri;
}

# Configuration HTTPS
server {
    listen 443 ssl http2;
    server_name votredomaine.com www.votredomaine.com;
    
    # Certificats SSL (seront générés par Certbot)
    ssl_certificate /etc/letsencrypt/live/votredomaine.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/votredomaine.com/privkey.pem;
    
    # Configuration SSL moderne
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Headers de sécurité
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
    
    # Cache statique
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|webp)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # Configuration principale
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
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    error_page 404 /index.html;
    error_page 500 502 503 504 /index.html;
}
```

```bash
# Activer le site
sudo ln -s /etc/nginx/sites-available/signfast /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default

# Tester la configuration
sudo nginx -t

# Redémarrer Nginx
sudo systemctl restart nginx
```

### Étape 10 : Installation SSL

```bash
# Installer Certbot
sudo apt install -y certbot python3-certbot-nginx

# Générer le certificat SSL
sudo certbot --nginx -d votredomaine.com -d www.votredomaine.com

# Suivre les instructions :
# 1. Entrer votre email
# 2. Accepter les conditions
# 3. Choisir la redirection HTTPS (option 2)

# Tester le renouvellement automatique
sudo certbot renew --dry-run
```

### Étape 11 : Démarrage de l'application

```bash
cd /var/www/signfast

# Démarrer avec PM2
pm2 start ecosystem.config.cjs

# Sauvegarder la configuration
pm2 save

# Configurer le démarrage automatique
pm2 startup systemd -u signfast --hp /home/signfast

# Exécuter la commande générée (copier-coller)
```

### Étape 12 : Vérification finale

```bash
# Vérifier le statut
pm2 status
sudo systemctl status nginx

# Tester l'application
curl http://localhost:3000
curl https://votredomaine.com
```

---

## 🗄️ Configuration Supabase

### Étape 1 : Créer un projet Supabase

1. Aller sur [supabase.com](https://supabase.com)
2. Créer un compte ou se connecter
3. Cliquer sur "New Project"
4. Remplir les informations :
   - **Name** : SignFast
   - **Database Password** : (générer un mot de passe fort)
   - **Region** : Choisir la région la plus proche
5. Cliquer sur "Create new project"

### Étape 2 : Récupérer les identifiants

1. Aller dans **Settings** → **API**
2. Noter :
   - **Project URL** : `https://xxxxx.supabase.co`
   - **anon public** : `eyJhbGc...` (clé anonyme)

### Étape 3 : Configurer la base de données

Les tables seront créées automatiquement lors de la première utilisation de l'application.

**Tables principales :**
- `forms` : Formulaires créés
- `responses` : Réponses aux formulaires
- `pdf_templates` : Templates PDF personnalisés
- `subscriptions` : Abonnements utilisateurs

### Étape 4 : Configurer l'authentification

1. Aller dans **Authentication** → **Providers**
2. Activer **Email** (déjà activé par défaut)
3. Désactiver la confirmation par email :
   - Aller dans **Authentication** → **Email Templates**
   - Désactiver "Enable email confirmations"

### Étape 5 : Configurer les politiques RLS

Les politiques Row Level Security sont déjà configurées dans les migrations.

Pour vérifier :
1. Aller dans **Database** → **Tables**
2. Sélectionner une table
3. Onglet **Policies**
4. Vérifier que les politiques sont actives

---

## 🔄 Système de Mise à Jour GitHub

### Architecture du système

```
GitHub Repository (hevolife/SignFastv2)
         ↓
    git pull origin main
         ↓
    npm ci (install)
         ↓
    npm run build
         ↓
    pm2 restart signfast
         ↓
    Application mise à jour
```

### Méthode 1 : Mise à jour manuelle

```bash
# Se connecter au serveur
ssh signfast@VOTRE_IP_VPS

# Aller dans le répertoire
cd /var/www/signfast

# Sauvegarder l'ancienne version
cp -r dist dist.backup.$(date +%Y%m%d_%H%M%S)

# Récupérer les dernières modifications
git pull origin main

# Installer les nouvelles dépendances
npm ci

# Rebuilder l'application
npm run build

# Redémarrer l'application
pm2 restart signfast

# Vérifier que tout fonctionne
pm2 status
pm2 logs signfast --lines 20
```

### Méthode 2 : Script de mise à jour automatique

Un script `update.sh` est fourni dans le projet :

```bash
# Rendre le script exécutable (première fois seulement)
chmod +x /var/www/signfast/update.sh

# Lancer la mise à jour
cd /var/www/signfast
./update.sh
```

**Le script fait automatiquement :**
1. ✅ Sauvegarde de l'ancienne version
2. ✅ Récupération des modifications GitHub
3. ✅ Installation des dépendances
4. ✅ Build de l'application
5. ✅ Redémarrage avec PM2
6. ✅ Vérification du statut
7. ✅ Rollback automatique en cas d'erreur

### Méthode 3 : Mise à jour avec rollback manuel

Si vous voulez plus de contrôle :

```bash
cd /var/www/signfast

# 1. Créer une sauvegarde
tar -czf ~/signfast-backup-$(date +%Y%m%d_%H%M%S).tar.gz dist/

# 2. Arrêter l'application
pm2 stop signfast

# 3. Mettre à jour le code
git pull origin main

# 4. Installer les dépendances
npm ci

# 5. Builder
npm run build

# 6. Redémarrer
pm2 start signfast

# 7. Vérifier
pm2 logs signfast --lines 50

# Si problème, restaurer la sauvegarde :
# pm2 stop signfast
# rm -rf dist
# tar -xzf ~/signfast-backup-XXXXXXXX.tar.gz
# pm2 start signfast
```

### Automatisation avec Cron (optionnel)

Pour mettre à jour automatiquement chaque nuit :

```bash
# Éditer le crontab
crontab -e

# Ajouter cette ligne (mise à jour à 3h du matin)
0 3 * * * cd /var/www/signfast && ./update.sh >> /var/www/signfast/logs/update.log 2>&1
```

### Vérifier la version déployée

```bash
cd /var/www/signfast

# Voir le commit actuel
git log -1 --oneline

# Voir les derniers commits
git log --oneline -5

# Voir les différences avec GitHub
git fetch origin
git log HEAD..origin/main --oneline
```

### Notifications de mise à jour (optionnel)

Pour recevoir un email après chaque mise à jour :

```bash
# Installer mailutils
sudo apt install -y mailutils

# Modifier le script update.sh pour ajouter :
echo "Mise à jour terminée le $(date)" | mail -s "SignFast - Mise à jour" votre@email.com
```

---

## 🔧 Maintenance et Monitoring

### Commandes quotidiennes

```bash
# Vérifier le statut de l'application
pm2 status

# Voir les logs en temps réel
pm2 logs signfast

# Voir les 50 dernières lignes de logs
pm2 logs signfast --lines 50

# Redémarrer l'application
pm2 restart signfast

# Vérifier Nginx
sudo systemctl status nginx

# Vérifier les certificats SSL
sudo certbot certificates
```

### Monitoring des ressources

```bash
# Voir l'utilisation CPU/RAM
htop

# Voir l'espace disque
df -h

# Voir l'utilisation mémoire
free -h

# Monitoring PM2 en temps réel
pm2 monit
```

### Gestion des logs

```bash
# Voir les logs Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Voir les logs PM2
pm2 logs signfast

# Vider les logs PM2
pm2 flush signfast

# Logs d'installation
cat /var/log/signfast-install.log
```

### Sauvegardes automatiques

Créer un script de sauvegarde :

```bash
# Créer le script
nano /var/www/signfast/backup.sh
```

**Contenu du script :**

```bash
#!/bin/bash
BACKUP_DIR="/var/backups/signfast"
DATE=$(date +%Y%m%d_%H%M%S)

# Créer le répertoire de sauvegarde
mkdir -p $BACKUP_DIR

# Sauvegarder l'application
tar -czf $BACKUP_DIR/signfast_$DATE.tar.gz -C /var/www signfast

# Garder seulement les 7 dernières sauvegardes
find $BACKUP_DIR -name "signfast_*.tar.gz" -mtime +7 -delete

echo "✅ Sauvegarde créée : $BACKUP_DIR/signfast_$DATE.tar.gz"
```

```bash
# Rendre exécutable
chmod +x /var/www/signfast/backup.sh

# Ajouter au crontab (sauvegarde quotidienne à 2h)
crontab -e
# Ajouter :
0 2 * * * /var/www/signfast/backup.sh
```

### Restauration depuis une sauvegarde

```bash
# Lister les sauvegardes
ls -lh /var/backups/signfast/

# Arrêter l'application
pm2 stop signfast

# Restaurer
cd /var/www
sudo rm -rf signfast
sudo tar -xzf /var/backups/signfast/signfast_XXXXXXXX.tar.gz

# Redémarrer
cd signfast
pm2 start signfast
```

### Installation de Netdata (monitoring avancé)

```bash
# Installation automatique
bash <(curl -Ss https://my-netdata.io/kickstart.sh)

# Accéder à Netdata
# http://VOTRE_IP:19999
```

---

## 🆘 Dépannage

### Problème : Application ne démarre pas

**Symptômes :**
```bash
pm2 status
# signfast | errored
```

**Solutions :**

```bash
# 1. Voir les logs d'erreur
pm2 logs signfast --err

# 2. Vérifier que serve est installé
npm list -g serve

# 3. Réinstaller serve si nécessaire
sudo npm install -g serve

# 4. Vérifier le fichier ecosystem.config.cjs
cat ecosystem.config.cjs

# 5. Redémarrer
pm2 delete signfast
pm2 start ecosystem.config.cjs
```

### Problème : Erreur 502 Bad Gateway

**Symptômes :**
- Le site affiche "502 Bad Gateway"

**Solutions :**

```bash
# 1. Vérifier que l'application tourne
pm2 status

# 2. Vérifier que le port 3000 est utilisé
netstat -tlnp | grep 3000

# 3. Redémarrer l'application
pm2 restart signfast

# 4. Vérifier les logs Nginx
sudo tail -f /var/log/nginx/error.log

# 5. Redémarrer Nginx
sudo systemctl restart nginx
```

### Problème : SSL ne fonctionne pas

**Symptômes :**
- Le site n'est pas accessible en HTTPS
- Erreur de certificat

**Solutions :**

```bash
# 1. Vérifier les certificats
sudo certbot certificates

# 2. Renouveler manuellement
sudo certbot renew

# 3. Vérifier la configuration Nginx
sudo nginx -t

# 4. Redémarrer Nginx
sudo systemctl restart nginx

# 5. Vérifier les logs Certbot
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

### Problème : Build échoue

**Symptômes :**
```bash
npm run build
# Error: ...
```

**Solutions :**

```bash
# 1. Vérifier les variables d'environnement
cat .env

# 2. Vérifier que les variables sont correctes
# VITE_SUPABASE_URL ne doit pas contenir "placeholder"
# VITE_SUPABASE_ANON_KEY ne doit pas contenir "placeholder"

# 3. Nettoyer et réinstaller
rm -rf node_modules package-lock.json
npm install

# 4. Rebuilder
npm run build

# 5. Si erreur de mémoire
export NODE_OPTIONS="--max-old-space-size=4096"
npm run build
```

### Problème : Git pull échoue

**Symptômes :**
```bash
git pull origin main
# error: cannot pull with rebase: You have unstaged changes.
```

**Solutions :**

```bash
# 1. Voir les modifications locales
git status

# 2. Sauvegarder les modifications locales
git stash

# 3. Récupérer les modifications GitHub
git pull origin main

# 4. Réappliquer les modifications locales (si nécessaire)
git stash pop

# Ou ignorer les modifications locales :
git reset --hard origin/main
```

### Problème : Performances lentes

**Symptômes :**
- Le site est lent à charger
- Les cartes mettent du temps à s'afficher

**Solutions :**

```bash
# 1. Vérifier les ressources serveur
htop
free -h
df -h

# 2. Vérifier les logs PM2
pm2 logs signfast --lines 100

# 3. Redémarrer l'application
pm2 restart signfast

# 4. Vérifier la base de données Supabase
# Aller sur supabase.com → Database → Performance

# 5. Vérifier que les index sont créés
# Les index doivent être présents sur :
# - responses(form_id)
# - responses(created_at)
# - responses(form_id, created_at)
```

### Problème : Espace disque plein

**Symptômes :**
```bash
df -h
# /dev/vda1  20G  20G  0  100% /
```

**Solutions :**

```bash
# 1. Nettoyer les logs PM2
pm2 flush signfast

# 2. Nettoyer les logs Nginx
sudo truncate -s 0 /var/log/nginx/access.log
sudo truncate -s 0 /var/log/nginx/error.log

# 3. Nettoyer les anciennes sauvegardes
sudo find /var/backups/signfast -name "*.tar.gz" -mtime +7 -delete

# 4. Nettoyer le cache npm
npm cache clean --force

# 5. Nettoyer les packages inutilisés
sudo apt autoremove
sudo apt clean
```

### Problème : Connexion Supabase échoue

**Symptômes :**
- Erreur "Failed to fetch" dans les logs
- Les formulaires ne se chargent pas

**Solutions :**

```bash
# 1. Vérifier les variables d'environnement
cat /var/www/signfast/.env

# 2. Tester la connexion Supabase
curl -I https://VOTRE_PROJECT.supabase.co

# 3. Vérifier les clés Supabase
# Aller sur supabase.com → Settings → API
# Copier la nouvelle clé si nécessaire

# 4. Mettre à jour le .env
nano /var/www/signfast/.env
# Modifier VITE_SUPABASE_URL et VITE_SUPABASE_ANON_KEY

# 5. Rebuilder et redémarrer
npm run build
pm2 restart signfast
```

---

## 📞 Support

### Logs importants

```bash
# Logs d'installation
cat /var/log/signfast-install.log

# Logs PM2
pm2 logs signfast --lines 100

# Logs Nginx
sudo tail -100 /var/log/nginx/error.log

# Logs système
sudo journalctl -u nginx -n 100
```

### Informations système

```bash
# Version Node.js
node --version

# Version npm
npm --version

# Version PM2
pm2 --version

# Version Nginx
nginx -v

# Informations serveur
uname -a
lsb_release -a
```

### Commandes de diagnostic

```bash
# Statut général
pm2 status
sudo systemctl status nginx
sudo ufw status

# Ports ouverts
sudo netstat -tlnp

# Processus en cours
ps aux | grep node
ps aux | grep nginx

# Utilisation ressources
top
htop
```

---

## 🎉 Félicitations !

Votre application SignFast est maintenant installée et opérationnelle !

**URLs importantes :**
- 🌐 **Application** : https://votredomaine.com
- 📊 **Supabase** : https://supabase.com/dashboard
- 🔧 **GitHub** : https://github.com/hevolife/SignFastv2

**Prochaines étapes recommandées :**
1. ✅ Tester toutes les fonctionnalités
2. ✅ Configurer les sauvegardes automatiques
3. ✅ Installer un système de monitoring (Netdata)
4. ✅ Configurer les alertes email
5. ✅ Documenter vos personnalisations

**Besoin d'aide ?**
- 📧 Email : bookingfastpro@gmail.com
- 🐛 Issues GitHub : https://github.com/hevolife/SignFastv2/issues
- 📚 Documentation : https://github.com/hevolife/SignFastv2/wiki
