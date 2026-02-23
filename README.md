# SmartBudget

SmartBudget is a Flutter client with a Node.js/Express backend using Firebase Authentication and Firestore.

## Project structure

- `lib/`: Flutter app
- `backend/`: Express API
- `firestore.rules`: Firestore security rules
- `firestore.indexes.json`: Firestore composite indexes

## Run Flutter app

```bash
flutter pub get
flutter run
```

Optional API override:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

## Run backend

```bash
cd backend
npm install
npm start
```

Read backend setup details in `backend/README-BACKEND.md`.

## Initialize Firestore data (seed)

```bash
cd backend
npm run db:init
```

## API smoke test with Firebase token

```bash
cd backend
npm run api:smoke -- --uid=<FIREBASE_UID>
```
