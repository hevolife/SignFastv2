# SignFast - Application de Signature Numérique

Application web de gestion de formulaires et signatures numériques.

## 🚀 Déploiement

Voir le guide complet : [GITHUB_DEPLOYMENT.md](./GITHUB_DEPLOYMENT.md)

### Déploiement rapide

```bash
# Sur le VPS
cd /var/www/SignFastv2
./deploy-from-github.sh
```

## 🛠️ Développement local

```bash
# Installation
npm install

# Développement
npm run dev

# Build
npm run build

# Preview du build
npm run preview
```

## 📦 Technologies

- React + TypeScript
- Vite
- Supabase
- Tailwind CSS
- PDF-lib
- React Hook Form

## 🔧 Configuration

Créer un fichier `.env` :

```env
VITE_SUPABASE_URL=https://signfast.hevolife.fr
VITE_SUPABASE_ANON_KEY=votre_clé_anon
```

## 📝 Structure

```
SignFastv2/
├── src/              # Code source
├── public/           # Fichiers statiques
├── dist/             # Build de production
├── supabase/         # Migrations et fonctions
└── deploy-from-github.sh  # Script de déploiement
```

## 🌐 Production

- **URL**: https://signfast.pro
- **Serveur**: 145.223.80.84
- **Base de données**: Supabase (https://signfast.hevolife.fr)

## 📄 Licence

Propriétaire
