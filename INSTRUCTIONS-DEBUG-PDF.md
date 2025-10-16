# 🔍 INSTRUCTIONS DÉBOGAGE PDF PRODUCTION

## 🚨 Problème Actuel
- ✅ PDF fonctionne en développement
- ❌ PDF échoue en production avec "Erreur lors du chargement du PDF"

## 📋 Étape 1 : Diagnostic Serveur

```bash
# Se connecter au VPS
ssh signfast@145.223.80.84

# Exécuter le diagnostic
cd /var/www/SignFastv2
chmod +x check-production-pdf.sh
./check-production-pdf.sh
```

**Copier TOUTE la sortie du script**

## 📋 Étape 2 : Diagnostic Navigateur

### Console (F12 → Console)
1. Ouvrir https://signfast.pro en navigation privée
2. Aller sur Templates
3. Cliquer sur un template
4. Ouvrir la console (F12)
5. **Copier TOUTES les erreurs rouges**

### Network (F12 → Network)
1. Filtrer par "pdf" ou "worker"
2. Cliquer sur la requête en erreur (rouge)
3. Copier :
   - **Status Code** (ex: 404, 403, 200)
   - **Content-Type** dans Response Headers
   - **Request URL** complète

## 📋 Étape 3 : Correction MIME Types

```bash
# Appliquer la correction Nginx
cd /var/www/SignFastv2
chmod +x fix-nginx-mime-production.sh
./fix-nginx-mime-production.sh
```

## 📋 Étape 4 : Vider Cache Navigateur

1. **Chrome/Edge** : Ctrl+Shift+Delete
   - Cocher "Images et fichiers en cache"
   - Période : "Toutes les périodes"
   - Cliquer "Effacer les données"

2. **Hard Refresh** : Ctrl+Shift+R (plusieurs fois)

3. **Tester à nouveau**

## 📋 Étape 5 : Vérification Post-Correction

```bash
# Vérifier le MIME type
curl -I https://signfast.pro/assets/pdf.worker.min-*.mjs | grep Content-Type

# Devrait afficher :
# Content-Type: text/javascript
```

## 🎯 Informations à Fournir

Pour résoudre rapidement, j'ai besoin de :

1. **Sortie complète** de `check-production-pdf.sh`
2. **Erreurs console** (F12 → Console) - screenshot ou copie texte
3. **Détails Network** (F12 → Network) :
   - Status code de la requête worker
   - Content-Type reçu
   - URL complète de la requête
4. **Résultat** après application de `fix-nginx-mime-production.sh`

## 🔧 Causes Probables

1. **MIME type incorrect** (.mjs servi comme text/plain au lieu de text/javascript)
2. **Fichier worker manquant** (404)
3. **Permissions fichiers** (403)
4. **Cache navigateur** (ancienne version)
5. **Configuration Nginx** (pas appliquée)

## ⚡ Solution Rapide Si Urgent

Si besoin d'une solution immédiate :

```bash
# Forcer le rebuild et redéploiement
cd /var/www/SignFastv2
npm run build
sudo systemctl reload nginx
```

Puis vider cache navigateur et tester.
