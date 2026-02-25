# SmartBudget

SmartBudget est une application mobile/desktop de gestion budgetaire.
Le projet est compose de deux parties:
- un frontend Flutter (`lib/`)
- une API Node.js/Express (`backend/`)

Le backend utilise Firebase Authentication et Firestore.

## Demarrage rapide

### 1) Lancer le backend
```bash
cd backend
npm install
npm start
```

### 2) Lancer le frontend Flutter
```bash
flutter pub get
flutter run
```

Si tu veux forcer l'URL API:
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

## Structure utile du repo
- `lib/`: ecrans, services, modeles, theme Flutter
- `backend/`: routes API, validations, scripts de test
- `firestore.rules`: regles de securite Firestore
- `firestore.indexes.json`: indexes Firestore

## Documentation detaillee
- Backend: `backend/README-BACKEND.md`
- Frontend: `README-FRONTEND.md`
- Feature Developer (livraison metier): `README-FEATURE-DEVELOPER.md`

## Commandes utiles backend

Initialiser des donnees de test:
```bash
cd backend
npm run db:init
```

Smoke test API avec un UID Firebase:
```bash
cd backend
npm run api:smoke -- --uid=<FIREBASE_UID>
```
