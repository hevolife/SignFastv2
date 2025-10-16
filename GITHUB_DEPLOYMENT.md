# 🚀 Guide Déploiement GitHub pour SignFast

## 📋 Configuration initiale (à faire UNE SEULE FOIS)

### 1️⃣ Préparer votre dépôt GitHub

```bash
# Sur votre VPS, dans /var/www/SignFastv2
cd /var/www/SignFastv2

# Initialiser git si pas déjà fait
git init

# Ajouter votre dépôt GitHub comme remote
git remote add origin https://github.com/VOTRE_USERNAME/SignFastv2.git

# Ou si vous utilisez SSH
git remote add origin git@github.com:VOTRE_USERNAME/SignFastv2.git

# Vérifier la configuration
git remote -v
```

### 2️⃣ Premier push vers GitHub

```bash
# Ajouter tous les fichiers
git add .

# Créer le premier commit
git commit -m "Initial commit - SignFast application"

# Pousser vers GitHub
git push -u origin main
```

---

## 🔄 Processus de Mise à Jour (MÉTHODE SIMPLE)

### Option A : Mise à jour manuelle (recommandé pour débuter)

```bash
# 1. Se connecter au VPS
ssh signfast@145.223.80.84

# 2. Aller dans le dossier de l'application
cd /var/www/SignFastv2

# 3. Arrêter l'application
pm2 stop signfast

# 4. Sauvegarder l'ancien build (au cas où)
mv dist dist.old.$(date +%Y%m%d_%H%M%S)

# 5. Récupérer les dernières modifications depuis GitHub
git pull origin main

# 6. Installer les nouvelles dépendances (si package.json a changé)
npm install

# 7. Builder l'application
npm run build

# 8. Vérifier que le build est OK
ls -la dist/

# 9. Corriger les permissions
sudo chown -R www-data:www-data dist/
sudo chmod -R 755 dist/

# 10. Redémarrer l'application
pm2 restart signfast

# 11. Vérifier que tout fonctionne
pm2 status
pm2 logs signfast --lines 50
```

### Option B : Script automatisé (plus rapide)

J'ai créé un script `deploy-from-github.sh` qui fait tout automatiquement :

```bash
# Rendre le script exécutable (une seule fois)
chmod +x deploy-from-github.sh

# Lancer le déploiement
./deploy-from-github.sh
```

---

## 🛠️ Workflow de Développement Recommandé

### Sur votre machine locale :

```bash
# 1. Faire vos modifications
# 2. Tester localement
npm run dev

# 3. Commiter vos changements
git add .
git commit -m "Description de vos modifications"

# 4. Pousser vers GitHub
git push origin main
```

### Sur le VPS :

```bash
# Mettre à jour l'application
./deploy-from-github.sh
```

---

## 🔍 Vérifications après déploiement

```bash
# 1. Vérifier que l'application tourne
pm2 status

# 2. Voir les logs en temps réel
pm2 logs signfast

# 3. Tester l'application
curl http://localhost:3000

# 4. Vérifier Nginx
sudo systemctl status nginx

# 5. Tester depuis l'extérieur
curl https://signfast.pro
```

---

## 🚨 En cas de problème

### Rollback rapide

```bash
# 1. Arrêter l'application
pm2 stop signfast

# 2. Restaurer l'ancien build
rm -rf dist
mv dist.old.YYYYMMDD_HHMMSS dist

# 3. Redémarrer
pm2 start signfast
```

### Logs de débogage

```bash
# Logs de l'application
pm2 logs signfast --lines 100

# Logs Nginx
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# Logs système
journalctl -u nginx -f
```

### Problèmes courants

#### 1. "Permission denied" lors du git pull
```bash
# Vérifier les permissions
ls -la /var/www/SignFastv2

# Corriger si nécessaire
sudo chown -R signfast:signfast /var/www/SignFastv2
```

#### 2. Build qui échoue
```bash
# Nettoyer et réinstaller
rm -rf node_modules package-lock.json
npm install
npm run build
```

#### 3. Application ne démarre pas
```bash
# Vérifier les logs
pm2 logs signfast --err

# Redémarrer PM2
pm2 kill
pm2 start ecosystem.config.cjs
```

---

## 📊 Commandes utiles

```bash
# Voir l'état de Git
git status
git log --oneline -10

# Voir les différences avant de pull
git fetch origin
git diff main origin/main

# Forcer la mise à jour (ATTENTION : écrase les modifications locales)
git fetch origin
git reset --hard origin/main

# Voir les branches
git branch -a

# Changer de branche
git checkout nom-de-branche
```

---

## 🔐 Configuration SSH pour GitHub (optionnel mais recommandé)

```bash
# 1. Générer une clé SSH sur le VPS
ssh-keygen -t ed25519 -C "signfast@145.223.80.84"

# 2. Afficher la clé publique
cat ~/.ssh/id_ed25519.pub

# 3. Copier cette clé et l'ajouter sur GitHub :
#    GitHub → Settings → SSH and GPG keys → New SSH key

# 4. Tester la connexion
ssh -T git@github.com

# 5. Changer le remote pour utiliser SSH
git remote set-url origin git@github.com:VOTRE_USERNAME/SignFastv2.git
```

---

## 📝 Checklist de déploiement

- [ ] Code commité et poussé sur GitHub
- [ ] Connecté au VPS en SSH
- [ ] Dans le bon dossier (`/var/www/SignFastv2`)
- [ ] Application arrêtée (`pm2 stop signfast`)
- [ ] Ancien build sauvegardé
- [ ] Code récupéré (`git pull`)
- [ ] Dépendances installées (`npm install`)
- [ ] Build créé (`npm run build`)
- [ ] Permissions corrigées
- [ ] Application redémarrée (`pm2 restart signfast`)
- [ ] Vérification des logs (`pm2 logs`)
- [ ] Test de l'application (https://signfast.pro)

---

## 🎯 Résumé : Commande rapide

Pour un déploiement rapide en une ligne :

```bash
cd /var/www/SignFastv2 && ./deploy-from-github.sh
```

Ou manuellement :

```bash
cd /var/www/SignFastv2 && pm2 stop signfast && git pull && npm install && npm run build && sudo chown -R www-data:www-data dist/ && pm2 restart signfast && pm2 logs signfast
```
