# 🚀 Installation Automatique SignFast

## 📋 Prérequis

- **VPS Ubuntu 24.04 LTS** (fraîchement installé)
- **Accès root** (ou sudo)
- **Nom de domaine** pointant vers votre VPS
- **Projet Supabase** configuré (URL + Anon Key)

---

## ⚡ Installation Rapide (1 commande)

```bash
curl -fsSL https://raw.githubusercontent.com/hevolife/SignFastv2/main/install-signfast.sh | sudo bash
```

---

## 📝 Installation Manuelle

### 1. Télécharger le script

```bash
# Télécharger le script
wget https://raw.githubusercontent.com/hevolife/SignFastv2/main/install-signfast.sh

# Rendre le script exécutable
chmod +x install-signfast.sh
```

### 2. Exécuter le script

```bash
sudo ./install-signfast.sh
```

### 3. Suivre les instructions

Le script vous demandera :

1. **Nom de domaine** (ex: signfast.votredomaine.com)
2. **Email** pour les certificats SSL
3. **URL Supabase** (ex: https://xxxxx.supabase.co)
4. **Clé anonyme Supabase** (anon key)
5. **Branche GitHub** (défaut: main)

---

## 🎯 Ce que fait le script

### ✅ Étapes automatisées :

1. **Préparation système**
   - Mise à jour Ubuntu 24.04
   - Installation des outils essentiels

2. **Création utilisateur**
   - Utilisateur dédié `signfast`
   - Configuration SSH

3. **Installation Node.js 20 LTS**
   - NodeSource repository
   - PM2 et serve

4. **Installation Nginx**
   - Configuration reverse proxy
   - Headers de sécurité

5. **Configuration Firewall**
   - UFW activé
   - Ports 22, 80, 443 ouverts

6. **Clonage GitHub**
   - Clone du repository
   - Gestion des permissions

7. **Configuration application**
   - Fichier .env
   - Configuration PM2

8. **Build production**
   - Installation dépendances
   - Build optimisé

9. **Configuration Nginx**
   - Virtual host
   - Proxy vers Node.js

10. **Certificats SSL**
    - Let's Encrypt
    - Renouvellement automatique

11. **Démarrage application**
    - PM2 process manager
    - Démarrage automatique

---

## 📊 Après l'installation

### Vérifier le statut

```bash
# Statut de l'application
sudo -u signfast pm2 status

# Logs en temps réel
sudo -u signfast pm2 logs signfast

# Statut Nginx
sudo systemctl status nginx

# Vérifier SSL
sudo certbot certificates
```

### Accéder à votre site

```
https://votre-domaine.com
```

---

## 🔧 Commandes utiles

### Gestion de l'application

```bash
# Redémarrer
sudo -u signfast pm2 restart signfast

# Arrêter
sudo -u signfast pm2 stop signfast

# Voir les logs
sudo -u signfast pm2 logs signfast --lines 50
```

### Mise à jour depuis GitHub

```bash
cd /var/www/signfast
sudo -u signfast git pull origin main
sudo -u signfast npm ci
sudo -u signfast npm run build
sudo -u signfast pm2 restart signfast
```

### Gestion Nginx

```bash
# Tester la configuration
sudo nginx -t

# Redémarrer
sudo systemctl restart nginx

# Voir les logs
sudo tail -f /var/log/nginx/error.log
```

---

## 🆘 Dépannage

### Application ne démarre pas

```bash
# Voir les logs détaillés
sudo -u signfast pm2 logs signfast --lines 100

# Vérifier le port 3000
sudo netstat -tlnp | grep 3000

# Redémarrer manuellement
cd /var/www/signfast
sudo -u signfast pm2 delete signfast
sudo -u signfast pm2 start ecosystem.config.cjs
```

### Erreur 502 Bad Gateway

```bash
# Vérifier que l'app tourne
sudo -u signfast pm2 status

# Vérifier Nginx
sudo nginx -t
sudo systemctl restart nginx
```

### SSL ne fonctionne pas

```bash
# Vérifier les certificats
sudo certbot certificates

# Renouveler manuellement
sudo certbot renew --force-renewal

# Vérifier la configuration Nginx
sudo nginx -t
```

---

## 📁 Structure des fichiers

```
/var/www/signfast/          # Application
├── dist/                   # Build production
├── logs/                   # Logs PM2
├── .env                    # Variables d'environnement
└── ecosystem.config.cjs    # Configuration PM2

/etc/nginx/sites-available/signfast  # Config Nginx
/etc/letsencrypt/live/DOMAIN/        # Certificats SSL
/var/log/signfast-install.log        # Logs installation
```

---

## 🔒 Sécurité

Le script configure automatiquement :

- ✅ Firewall UFW (ports 22, 80, 443)
- ✅ Fail2Ban (protection brute force)
- ✅ SSL/TLS avec Let's Encrypt
- ✅ Headers de sécurité Nginx
- ✅ Utilisateur dédié non-root
- ✅ Permissions fichiers sécurisées

---

## 📚 Documentation complète

Pour plus de détails, consultez :
- [Guide d'installation VPS](./INSTALLATION_VPS.md)
- [Guide de déploiement Ubuntu 24](./DEPLOIEMENT_VPS_UBUNTU24.md)

---

## 🎉 Support

En cas de problème :

1. Consultez les logs : `cat /var/log/signfast-install.log`
2. Vérifiez les services : `sudo systemctl status nginx` et `sudo -u signfast pm2 status`
3. Ouvrez une issue sur GitHub

---

**Votre SignFast est maintenant en production ! 🚀**
