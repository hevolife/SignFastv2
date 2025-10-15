# 🚀 SignFast - Application de Signature Électronique

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](https://github.com/hevolife/SignFastv2)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Node](https://img.shields.io/badge/node-20.x-brightgreen.svg)](https://nodejs.org)
[![React](https://img.shields.io/badge/react-18.x-blue.svg)](https://reactjs.org)

Application web moderne pour la création de formulaires, la collecte de signatures électroniques et la génération de PDF.

## ✨ Fonctionnalités

- 📝 **Création de formulaires** : Interface intuitive avec drag & drop
- ✍️ **Signature électronique** : Capture de signatures légales
- 📄 **Génération PDF** : Templates personnalisables
- 🔒 **Sécurité** : Authentification et chiffrement
- 📊 **Tableau de bord** : Statistiques et analytics
- 💳 **Abonnements** : Intégration Stripe
- 🌐 **Multi-langue** : Support français
- 📱 **Responsive** : Mobile, tablette, desktop

## 🚀 Installation

### Installation Automatique (Recommandé)

```bash
# Télécharger le script
wget https://raw.githubusercontent.com/hevolife/SignFastv2/main/install-signfast.sh

# Rendre exécutable
chmod +x install-signfast.sh

# Lancer l'installation
sudo ./install-signfast.sh
```

**Durée** : 10-15 minutes

### Installation Manuelle

Voir la [documentation complète](./INSTALLATION_COMPLETE.md)

## 📚 Documentation

- 📖 [Guide d'installation complet](./INSTALLATION_COMPLETE.md)
- 🚀 [Quick Start](./QUICK_START.md)
- 🔄 [Système de mise à jour](./INSTALLATION_COMPLETE.md#système-de-mise-à-jour-github)
- 🆘 [Dépannage](./INSTALLATION_COMPLETE.md#dépannage)

## 🔄 Mise à Jour

### Méthode Automatique

```bash
cd /var/www/signfast
./update.sh
```

### Méthode Manuelle

```bash
cd /var/www/signfast
git pull origin main
npm ci
npm run build
pm2 restart signfast
```

## 🛠️ Technologies

- **Frontend** : React 18, TypeScript, Tailwind CSS
- **Backend** : Supabase (PostgreSQL, Auth, Storage)
- **Build** : Vite
- **Déploiement** : Nginx, PM2, Certbot
- **Paiements** : Stripe
- **PDF** : jsPDF, pdf-lib

## 📋 Prérequis

- **Serveur** : Ubuntu 24.04 LTS
- **RAM** : 2GB minimum (4GB recommandé)
- **CPU** : 2 vCPU minimum
- **Stockage** : 20GB SSD
- **Domaine** : Nom de domaine configuré
- **Supabase** : Compte et projet créé

## 🔧 Configuration

### Variables d'environnement

Créer un fichier `.env` :

```env
NODE_ENV=production
PORT=3000

# Supabase
VITE_SUPABASE_URL=https://xxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGc...

# Optionnel
VITE_APP_VERSION=2.0.0
VITE_APP_ENV=production
```

### Supabase

1. Créer un projet sur [supabase.com](https://supabase.com)
2. Récupérer l'URL et la clé anonyme
3. Les tables seront créées automatiquement

## 📊 Architecture

```
SignFast/
├── src/
│   ├── components/     # Composants React
│   ├── pages/          # Pages de l'application
│   ├── hooks/          # Hooks personnalisés
│   ├── utils/          # Utilitaires
│   ├── lib/            # Bibliothèques (Supabase)
│   └── contexts/       # Contextes React
├── public/             # Assets statiques
├── supabase/           # Migrations et config
├── dist/               # Build de production
└── ecosystem.config.cjs # Configuration PM2
```

## 🔒 Sécurité

- ✅ HTTPS avec Let's Encrypt
- ✅ Headers de sécurité Nginx
- ✅ Authentification Supabase
- ✅ Row Level Security (RLS)
- ✅ Firewall UFW
- ✅ Fail2Ban

## 📈 Performance

- ⚡ Chargement < 2 secondes
- ⚡ Requêtes optimisées (index DB)
- ⚡ Cache navigateur (1 an)
- ⚡ Compression Gzip
- ⚡ Pagination (12 items)

## 🧪 Tests

```bash
# Tests unitaires
npm run test

# Tests E2E
npm run test:e2e

# Linter
npm run lint
```

## 📦 Build

```bash
# Développement
npm run dev

# Production
npm run build

# Preview
npm run preview
```

## 🚀 Déploiement

### Avec PM2

```bash
# Démarrer
pm2 start ecosystem.config.cjs

# Redémarrer
pm2 restart signfast

# Arrêter
pm2 stop signfast

# Logs
pm2 logs signfast
```

### Avec Docker (optionnel)

```bash
# Build
docker build -t signfast .

# Run
docker run -p 3000:3000 signfast
```

## 🤝 Contribution

Les contributions sont les bienvenues !

1. Fork le projet
2. Créer une branche (`git checkout -b feature/AmazingFeature`)
3. Commit (`git commit -m 'Add AmazingFeature'`)
4. Push (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📝 Changelog

### Version 2.0.0 (2025-01-16)

- ✨ Optimisation des performances (5-8x plus rapide)
- ✨ Système de mise à jour GitHub
- ✨ Script d'installation automatique
- ✨ Documentation complète
- 🐛 Corrections de bugs
- 🔒 Améliorations de sécurité

### Version 1.0.0 (2024-12-01)

- 🎉 Version initiale

## 📄 License

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 👥 Auteurs

- **HevoLife** - [GitHub](https://github.com/hevolife)

## 📧 Support

- 📧 Email : bookingfastpro@gmail.com
- 🐛 Issues : [GitHub Issues](https://github.com/hevolife/SignFastv2/issues)
- 📚 Wiki : [GitHub Wiki](https://github.com/hevolife/SignFastv2/wiki)

## 🙏 Remerciements

- [React](https://reactjs.org)
- [Supabase](https://supabase.com)
- [Tailwind CSS](https://tailwindcss.com)
- [Vite](https://vitejs.dev)
- [Stripe](https://stripe.com)

---

⭐ **Si ce projet vous aide, n'hésitez pas à lui donner une étoile !**

🔗 **Site web** : https://signfast.pro
