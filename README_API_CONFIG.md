# 🚀 Guide de Configuration Dynamique de l'API (Méthode Facile)

Ce guide explique comment changer l'adresse de votre serveur (Backend) sans jamais toucher au code. C'est magique et indispensable pour le déploiement !

---

## 🟢 1. Comment ça marche ? (L'explication simple)

Imaginez que l'application est une radio. Au lieu de souder la fréquence de votre station préférée à l'intérieur de la radio, on a mis un bouton pour que vous puissiez choisir la fréquence que vous voulez.

Dans le code, on utilise un bouton appelé `--dart-define`.

---

## 🛠️ 2. Comment l'utiliser au quotidien ?

### A. Si vous utilisez VS Code (Le plus simple)
Pour ne plus avoir à taper l'IP, on va le configurer une fois pour toutes dans VS Code :

1. Ouvrez le dossier `.vscode` à la racine de votre projet mobile.
2. Créez (ou ouvrez) le fichier `launch.json`.
3. Ajoutez cette ligne magique dans la configuration :
```json
"args": [
    "--dart-define=BASE_URL=http://VOTRE_NOUVELLE_IP:3003/api/v1"
]
```

### B. En ligne de commande (Terminal)
Si vous lancez l'app à la main, tapez ceci :
```bash
flutter run --dart-define=BASE_URL=http://192.168.1.50:3003/api/v1
```

---

## 📦 3. Déploiement : Créer l'application finale (APK)

Quand vous voudrez donner l'application à vos clients ou la mettre en ligne, vous devrez utiliser l'URL de votre vrai serveur (Production).

**La commande magique :**
```bash
flutter build apk --dart-define=BASE_URL=https://mon-vrai-serveur.com/api/v1
```
*L'application générée sera alors configurée pour toujours parler au vrai serveur !*

---

## 🐋 4. Déploiement avec Docker (Le futur)

Si vous voulez mettre votre **Backend** sur un serveur avec Docker, voici comment faire simplement :

1. **Préparez un fichier `docker-compose.yml`** pour votre backend (NestJS + Postgres).
2. **Exposez le port 3003** de votre conteneur vers l'extérieur.
3. Une fois Docker lancé sur votre serveur (ex: IP `157.230.1.2`), vous compilez votre application mobile comme ceci :
```bash
flutter build apk --dart-define=BASE_URL=http://157.230.1.2:3003/api/v1
```

---

## 💡 Astuce pour les tests (Android uniquement)
Si vous travaillez sur l'émulateur Android de votre PC, utilisez cette adresse :
`http://10.0.2.2:3003/api/v1`
Elle pointe toujours vers votre PC, peu importe l'IP de votre Wi-Fi !

---
*Fait avec ❤️ pour simplifier votre développement.*
