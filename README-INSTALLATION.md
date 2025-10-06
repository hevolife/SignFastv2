# 🚀 Installation Automatique de SignFast

Ce guide explique comment utiliser le script d'installation automatique pour déployer SignFast sur un VPS Ubuntu 24.04 LTS **directement depuis GitHub**.

## 📋 Prérequis

Avant de commencer, assurez-vous d'avoir :

### Serveur VPS
- **OS** : Ubuntu 24.04 LTS
- **RAM** : Minimum 2GB (4GB recommandé)
- **CPU** : 2 vCPU minimum
- **Stockage** : 20GB SSD minimum
- **Accès** : Root ou sudo

### Domaine et DNS
- Un nom de domaine (ex: `signfast.votredomaine.com`)
- DNS configuré pour pointer vers votre VPS
- Propagation DNS terminée (vérifiez avec `nslookup votredomaine.com`)

### Projet Supabase
- Projet Supabase créé sur [supabase.com](https://supabase.com)
- URL du projet (ex: `https://xxxxx.supabase.co`)
- Clé anonyme (anon key) disponible

---

## 🎯 Installation en 3 étapes

### Étape 1 : Télécharger le script

Sur votre **VPS Ubuntu 24**, connectez-vous en SSH :

```bash
# Connexion SSH
ssh root@VOTRE_IP_VPS

# Télécharger le script
wget https://raw.githubusercontent.com/hevolife/SignFastv2/main/install-signfast.sh

# Ou avec curl
curl -O https://raw.githubusercontent.com/hevolife/SignFastv2/main/install-signfast.sh
```

### Étape 2 : Rendre le script exécutable

```bash
chmod +x install-signfast.sh
```

### Étape 3 : Lancer l'installation

```bash
sudo ./install-signfast.sh
```

---

## 📝 Processus d'installation

Le script va vous demander les informations suivantes :

### 1. Nom de domaine
```
🌐 Entrez votre nom de domaine (ex: signfast.votredomaine.com):
```
**Exemple** : `signfast.monsite.com`

### 2. Email pour SSL
```
📧 Entrez votre email pour les certificats SSL:
```
**Exemple** : `admin@monsite.com`

### 3. URL Supabase
```
🔗 Entrez l'URL de votre projet Supabase:
```
**Exemple** : `https://abcdefghijk.supabase.co`

### 4. Clé anonyme Supabase
```
🔑 Entrez votre clé anonyme Supabase (anon key):
```
**Exemple** : `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### 5. Branche GitHub (optionnel)
```
🌿 Branche GitHub à déployer (défaut: main):
```
**Appuyez sur Entrée** pour utiliser la branche `main` ou entrez une autre branche.

### 6. Confirmation
Le script affichera un récapitulatif et demandera confirmation.

---

## ✅ Ce que fait le script automatiquement

Le script effectue **toutes** les opérations suivantes :

### 1. Préparation du système (Étape 1/11)
- ✅ Mise à jour des paquets système
- ✅ Installation des outils essentiels (git, curl, wget, etc.)
- ✅ Configuration de base

### 2. Création de l'utilisateur (Étape 2/11)
- ✅ Création de l'utilisateur `signfast`
- ✅ Configuration des permissions sudo
- ✅ Configuration SSH

### 3. Installation de Node.js (Étape 3/11)
- ✅ Installation de Node.js 20 LTS
- ✅ Installation de npm
- ✅ Installation de PM2 et serve

### 4. Installation de Nginx (Étape 4/11)
- ✅ Installation du serveur web Nginx
- ✅ Démarrage et activation automatique

### 5. Configuration du Firewall (Étape 5/11)
- ✅ Configuration UFW
- ✅ Ouverture des ports 22, 80, 443
- ✅ Activation du firewall

### 6. Création des répertoires (Étape 6/11)
- ✅ Création de `/var/www/signfast`
- ✅ Création des dossiers logs et backups
- ✅ Configuration des permissions

### 7. Clonage depuis GitHub (Étape 7/11) 🆕
- ✅ Clonage du repository depuis GitHub
- ✅ Checkout de la branche spécifiée
- ✅ Affichage du commit actuel

### 8. Configuration de l'application (Étape 8/11)
- ✅ Création du fichier `.env`
- ✅ Vérification du fichier `ecosystem.config.cjs`

### 9. Installation et Build (Étape 9/11) 🆕
- ✅ Installation des dépendances npm
- ✅ Build de l'application React
- ✅ Vérification du build

### 10. Configuration de Nginx (Étape 10/11)
- ✅ Création de la configuration Nginx
- ✅ Activation du site
- ✅ Test de la configuration

### 11. Installation SSL (Étape 11/11)
- ✅ Installation de Certbot
- ✅ Génération du certificat SSL Let's Encrypt
- ✅ Configuration du renouvellement automatique

### 12. Démarrage de l'application
- ✅ Démarrage avec PM2
- ✅ Configuration du démarrage automatique

---

## 🎉 Après l'installation

Une fois l'installation terminée, vous verrez un résumé complet :

```
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║        🎉 INSTALLATION TERMINÉE AVEC SUCCÈS ! 🎉          ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝

📊 INFORMATIONS DE L'INSTALLATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  🌐 URL de votre site:
     https://signfast.votredomaine.com

  📁 Répertoire de l'application:
     /var/www/signfast

  👤 Utilisateur système:
     signfast

  📝 Fichier de logs:
     /var/log/signfast-install.log

  🔗 Repository GitHub:
     https://github.com/hevolife/SignFastv2.git

  🌿 Branche déployée:
     main

  📌 Commit actuel:
     abc1234
```

### Vérifier que tout fonctionne

```bash
# 1. Vérifier le statut de l'application
sudo -u signfast pm2 status

# 2. Voir les logs
sudo -u signfast pm2 logs signfast

# 3. Tester l'accès local
curl http://localhost:3000

# 4. Tester l'accès HTTPS
curl -I https://votredomaine.com
```

### Accéder à votre site

Ouvrez votre navigateur et allez sur :
```
https://votredomaine.com
```

---

## 🔄 Mettre à jour l'application

Pour mettre à jour votre application depuis GitHub :

```bash
# Se connecter au serveur
ssh signfast@VOTRE_IP

# Aller dans le répertoire de l'application
cd /var/www/signfast

# Récupérer les dernières modifications
sudo -u signfast git pull origin main

# Installer les nouvelles dépendances
sudo -u signfast npm ci

# Rebuilder l'application
sudo -u signfast npm run build

# Redémarrer l'application
sudo -u signfast pm2 restart signfast

# Vérifier le statut
sudo -u signfast pm2 status
```

Ou utilisez ce script one-liner :

```bash
cd /var/www/signfast && \
sudo -u signfast git pull origin main && \
sudo -u signfast npm ci && \
sudo -u signfast npm run build && \
sudo -u signfast pm2 restart signfast
```

---

## 🔧 Commandes utiles

### Gestion de l'application

```bash
# Voir le statut
sudo -u signfast pm2 status

# Redémarrer l'application
sudo -u signfast pm2 restart signfast

# Arrêter l'application
sudo -u signfast pm2 stop signfast

# Voir les logs en temps réel
sudo -u signfast pm2 logs signfast

# Monitoring en temps réel
sudo -u signfast pm2 monit
```

### Gestion de Nginx

```bash
# Redémarrer Nginx
sudo systemctl restart nginx

# Recharger la configuration
sudo systemctl reload nginx

# Voir le statut
sudo systemctl status nginx

# Tester la configuration
sudo nginx -t
```

### Gestion SSL

```bash
# Voir les certificats
sudo certbot certificates

# Renouveler manuellement
sudo certbot renew

# Test de renouvellement
sudo certbot renew --dry-run
```

### Gestion Git

```bash
# Voir le commit actuel
cd /var/www/signfast && git log -1

# Voir les branches disponibles
git branch -a

# Changer de branche
sudo -u signfast git checkout nom-de-branche

# Voir les modifications
git status
```

### Logs

```bash
# Logs d'installation
cat /var/log/signfast-install.log

# Logs de l'application
sudo -u signfast pm2 logs signfast --lines 50

# Logs Nginx
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

---

## 🆘 Dépannage

### Problème : Le script s'arrête avec une erreur

```bash
# Consulter les logs détaillés
cat /var/log/signfast-install.log

# Relancer le script (il est idempotent)
sudo ./install-signfast.sh
```

### Problème : Le clonage GitHub échoue

```bash
# Vérifier la connexion à GitHub
ping github.com

# Vérifier que git est installé
git --version

# Cloner manuellement
cd /var/www/signfast
sudo -u signfast git clone https://github.com/hevolife/SignFastv2.git temp
```

### Problème : Le build échoue

```bash
# Voir les logs de build
cat /var/log/signfast-install.log | grep -A 50 "Build de l'application"

# Vérifier les dépendances
cd /var/www/signfast
sudo -u signfast npm list

# Nettoyer et rebuilder
sudo -u signfast rm -rf node_modules dist
sudo -u signfast npm install
sudo -u signfast npm run build
```

### Problème : L'application ne démarre pas

```bash
# Vérifier les logs PM2
sudo -u signfast pm2 logs signfast --lines 100

# Vérifier que dist/ existe
ls -la /var/www/signfast/dist/

# Redémarrer manuellement
cd /var/www/signfast
sudo -u signfast pm2 restart signfast
```

### Problème : Erreur 502 Bad Gateway

```bash
# Vérifier que l'app écoute sur le port 3000
sudo netstat -tlnp | grep 3000

# Redémarrer l'application
sudo -u signfast pm2 restart signfast

# Redémarrer Nginx
sudo systemctl restart nginx
```

### Problème : SSL ne fonctionne pas

```bash
# Vérifier que le DNS pointe vers le serveur
nslookup votredomaine.com

# Vérifier les certificats
sudo certbot certificates

# Régénérer les certificats
sudo certbot --nginx -d votredomaine.com -d www.votredomaine.com --force-renewal
```

---

## 📚 Fichiers créés par le script

Le script crée automatiquement les fichiers suivants :

```
/var/www/signfast/
├── .git/                    # Repository Git
├── dist/                    # Application buildée
├── logs/                    # Logs de l'application
│   ├── err.log
│   ├── out.log
│   └── combined.log
├── backups/                 # Sauvegardes
├── .env                     # Variables d'environnement
├── ecosystem.config.cjs     # Configuration PM2
├── package.json            # Dépendances npm
└── [autres fichiers du repo]

/etc/nginx/sites-available/
└── signfast                # Configuration Nginx

/var/log/
└── signfast-install.log    # Logs d'installation

/var/backups/signfast/      # Sauvegardes système
```

---

## 🔒 Sécurité

Le script configure automatiquement :

- ✅ **Firewall UFW** : Seuls les ports 22, 80, 443 sont ouverts
- ✅ **Fail2Ban** : Protection contre les attaques par force brute
- ✅ **SSL/TLS** : Certificat Let's Encrypt avec renouvellement automatique
- ✅ **Headers de sécurité** : X-Frame-Options, CSP, HSTS, etc.
- ✅ **Utilisateur dédié** : L'application tourne sous l'utilisateur `signfast`
- ✅ **Permissions** : Fichiers .env protégés (chmod 600)

---

## 🚀 Prochaines étapes recommandées

Après l'installation, vous pouvez :

1. **Configurer les sauvegardes automatiques**
   ```bash
   # Créer un script de sauvegarde quotidienne
   sudo crontab -e
   # Ajouter : 0 2 * * * /var/www/signfast/backup.sh
   ```

2. **Installer un système de monitoring**
   ```bash
   # Installer Netdata
   bash <(curl -Ss https://my-netdata.io/kickstart.sh)
   ```

3. **Configurer les logs rotatifs**
   ```bash
   # Créer la configuration logrotate
   sudo nano /etc/logrotate.d/signfast
   ```

4. **Mettre en place des alertes email**
   - Configurer Postfix ou un service SMTP
   - Créer des scripts de surveillance

5. **Optimiser les performances**
   - Activer le cache Nginx
   - Configurer la compression Brotli
   - Optimiser les images

---

## 🆕 Nouveautés de la version 2.0

- ✅ **Déploiement depuis GitHub** : Plus besoin d'upload manuel
- ✅ **Build automatique** : npm install et build automatiques
- ✅ **Choix de la branche** : Déployez n'importe quelle branche
- ✅ **Mise à jour simplifiée** : git pull + rebuild en une commande
- ✅ **Traçabilité** : Affichage du commit déployé

---

## 📞 Support

Si vous rencontrez des problèmes :

1. Consultez les logs : `cat /var/log/signfast-install.log`
2. Vérifiez la documentation complète
3. Contactez le support technique

---

## 📄 Licence

Ce script est fourni "tel quel" sans garantie d'aucune sorte.

---

**Bonne installation ! 🚀**
