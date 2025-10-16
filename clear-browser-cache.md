# 🧹 VIDER LE CACHE NAVIGATEUR

## ⚠️ CRITIQUE : Le navigateur cache les anciens fichiers !

Le fichier `pdf-D_jXANCN.js` n'existe plus mais le navigateur le cherche encore.

## 🔧 Solution : Vider le cache complètement

### Chrome / Edge / Brave

1. **Ouvrir les outils développeur** : `F12`
2. **Aller dans Network** (Réseau)
3. **Clic droit sur "Disable cache"** ✅
4. **Ou bien** :
   - `Ctrl + Shift + Delete`
   - Cocher "Images et fichiers en cache"
   - Période : "Toutes les périodes"
   - Cliquer "Effacer les données"

### Firefox

1. `Ctrl + Shift + Delete`
2. Cocher "Cache"
3. Période : "Tout"
4. Cliquer "OK"

### Safari

1. `Cmd + Option + E` (vider les caches)
2. Ou `Safari → Préférences → Avancées → Afficher le menu Développement`
3. `Développement → Vider les caches`

## 🔄 Hard Refresh

Après avoir vidé le cache :

- **Windows** : `Ctrl + Shift + R` (plusieurs fois)
- **Mac** : `Cmd + Shift + R` (plusieurs fois)

## 🧪 Test en Navigation Privée

Pour être sûr que c'est bien corrigé :

1. Ouvrir une **fenêtre de navigation privée** : `Ctrl + Shift + N`
2. Aller sur `https://signfast.pro`
3. Tester le PDF

## ✅ Vérification

Dans la console (F12 → Console), vous ne devriez plus voir :

❌ `GET https://signfast.pro/assets/pdf-D_jXANCN.js 404 (Not Found)`

Mais plutôt :

✅ `GET https://signfast.pro/assets/pdf-D7aZAIIQ.js 200 (OK)`
