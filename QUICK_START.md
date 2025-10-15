# 🚀 Quick Start - SignFast

## Installation en 5 minutes

### 1️⃣ Télécharger et lancer le script

```bash
# Se connecter au serveur
ssh root@VOTRE_IP_VPS

# Télécharger le script
wget https://raw.githubusercontent.com/hevolife/SignFastv2/main/install-signfast.sh

# Rendre exécutable
chmod +x install-signfast.sh

# Lancer l'installation
sudo ./install-signfast.sh
```

### 2️⃣ Répondre aux questions

Le script vous demandera :

1. **Domaine** : `signfast.votredomaine.com`
2. **Email** : `votre@email.com`
3. **URL Supabase** : `https://xxxxx.supabase.co`
4. **Clé Supabase** : `eyJhbGc...`
5. **Branche** : `main` (par défaut)

### 3️⃣ Attendre la fin (10-15 min)

Le script installe automatiquement :
- ✅ Node.js 20 LTS
- ✅ PM2 et serve
- ✅ Nginx
- ✅ Certificats SSL
- ✅ Application SignFast

### 4️⃣ Tester votre site

Ouvrir dans le navigateur :
```
https://signfast.votredomaine.com
```

---

## Mise à jour depuis GitHub

### Méthode rapide

```bash
# Se connecter
ssh signfast@VOTRE_IP_VPS

# Lancer la mise à jour
cd /var/www/signfast
./update.sh
```

### Méthode manuelle

```bash
cd /var/www/signfast
git pull origin main
npm ci
npm run build
pm2 restart signfast
```

---

## Commandes utiles

```bash
# Voir le statut
pm2 status

# Voir les logs
pm2 logs signfast

# Redémarrer
pm2 restart signfast

# Vérifier Nginx
sudo systemctl status nginx
```

---

## Besoin d'aide ?

📚 **Documentation complète** : [INSTALLATION_COMPLETE.md](./INSTALLATION_COMPLETE.md)

📧 **Support** : bookingfastpro@gmail.com
