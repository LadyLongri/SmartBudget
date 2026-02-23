# SmartBudget Backend - Checklist de prod (FR)

Ce document sert de reference "pre-prod/prod".
Il explique:

- ce a quoi consistait le travail backend,
- comment le travail a ete mene,
- ce qu'il reste a verifier avant mise en production.

## 1. Perimetre du travail realise

### Objectif global

Mettre le backend SmartBudget dans un etat exploitable en conditions reelles, avec:

- authentification Firebase fiable,
- acces Firestore securise,
- API CRUD transactions/categories robuste,
- procedures de deploiement et de verification claires.

### Livrables techniques produits

- securisation de l'auth backend (`src/middlewares/auth.js`)
- centralisation de l'initialisation Firebase Admin (`src/config/firebase.js`)
- durcissement des routes CRUD (`src/routes/transactions.routes.js`, `src/routes/categories.routes.js`)
- endpoint de sante enrichi (`GET /health` avec `firebaseReady`)
- suppression de la cle sensible du repo
- regles Firestore strictes par proprietaire (`firestore.rules`)
- index Firestore aligns aux requetes (`firestore.indexes.json`)
- tests backend minimaux operationnels (`backend/test/health.test.js`)

## 2. Methode utilisee (comment le travail a ete mene)

### Etape 1 - Audit

- identification des failles prioritaires:
  - cle de service exposee,
  - regles Firestore ouvertes,
  - incoherences auth/config,
  - absence de tests backend exploitables.

### Etape 2 - Correction securite

- retrait de la cle du projet
- correction `.gitignore`
- nouveau flux de credentials par variable d'environnement
- middleware auth strict (Bearer token obligatoire, erreurs propres)

### Etape 3 - Stabilisation API

- validation plus stricte des inputs
- reponses d'erreurs internes non exposees au client
- verification d'etat Firebase avant operations sensibles

### Etape 4 - Gouvernance Firestore

- regles de securite basees sur `request.auth.uid`
- index composes compatibles avec les filtres backend

### Etape 5 - Validation

- `flutter analyze`
- `flutter test`
- `npm test` (backend)
- verification de `/health` avec indicateur `firebaseReady`

## 3. Checklist operationnelle avant PROD

## 3.1 Secrets et credentials

- [ ] Revoquer la cle Firebase compromise (ancienne cle).
- [ ] Generer une nouvelle cle JSON.
- [ ] Stocker la nouvelle cle hors repo (ex: `C:\secrets\smartbudget-admin.json`).
- [ ] Verifier qu'aucun secret n'est versionne.
- [ ] Verifier que `.gitignore` couvre bien:
  - `/backend/serviceAccountKey.json`
  - `/backend/.env*`

## 3.2 Configuration locale serveur

- [ ] Definir la variable d'environnement:

```powershell
$env:FIREBASE_SERVICE_ACCOUNT_PATH="C:\secrets\smartbudget-admin.json"
```

- [ ] Installer et lancer l'API:

```powershell
cd "C:\Users\hp\Documents\Examen PM\smartbudget\backend"
npm install
npm start
```

- [ ] Verifier la sante:

```powershell
Invoke-RestMethod http://localhost:3000/health
```

- [ ] Confirmer `firebaseReady: true`.

## 3.3 Firestore (regles + index)

- [ ] Depuis la racine projet:

```powershell
cd "C:\Users\hp\Documents\Examen PM\smartbudget"
firebase deploy --only firestore:rules,firestore:indexes
```

- [ ] Verifier que les requetes filtrees (`month`, `currency`, `type`, `categoryId`) passent sans erreur d'index.

## 3.4 Auth et API

- [ ] Tester `GET /health` (public).
- [ ] Tester `GET /me` avec token valide.
- [ ] Tester CRUD categories:
  - create
  - read list
  - update
  - delete
- [ ] Tester CRUD transactions:
  - create
  - read list
  - update
  - delete

## 3.5 Qualite et tests

- [ ] Backend tests:

```powershell
cd "C:\Users\hp\Documents\Examen PM\smartbudget\backend"
npm test
```

- [ ] Flutter checks:

```powershell
cd "C:\Users\hp\Documents\Examen PM\smartbudget"
flutter analyze
flutter test
```

## 4. Checklist de deploiement PROD

- [ ] Verifier que les variables d'environnement serveur sont configurees.
- [ ] Verifier les droits IAM du compte de service (principe de moindre privilege).
- [ ] Deployer backend.
- [ ] Deployer regles/index Firestore.
- [ ] Realiser un smoke test complet (auth + CRUD).
- [ ] Mettre en place logs et alertes (erreurs 401/403/500/503).

## 5. Checklist post-deploiement

- [ ] Verifier qu'il n'y a pas de 503 `auth_unavailable`.
- [ ] Verifier que les operations CRUD sont limitees au `uid` courant.
- [ ] Verifier qu'aucune erreur d'index Firestore n'apparait.
- [ ] Verifier latence et taux d'erreur API.

## 6. Commandes utiles (resume rapide)

### Lancer backend

```powershell
cd "C:\Users\hp\Documents\Examen PM\smartbudget\backend"
$env:FIREBASE_SERVICE_ACCOUNT_PATH="C:\secrets\smartbudget-admin.json"
npm start
```

### Tester backend

```powershell
cd "C:\Users\hp\Documents\Examen PM\smartbudget\backend"
npm test
Invoke-RestMethod http://localhost:3000/health
```

### Deployer Firestore

```powershell
cd "C:\Users\hp\Documents\Examen PM\smartbudget"
firebase deploy --only firestore:rules,firestore:indexes
```

## 7. Initialisation automatique de la base

Le backend fournit un script de seed:

- cree/met a jour des categories par defaut pour un ou plusieurs utilisateurs,
- peut aussi inserer des transactions d'exemple (optionnel),
- est idempotent (relancer n'ajoute pas de doublons sur les memes IDs techniques).

### Commandes

```powershell
cd "C:\Users\hp\Documents\Examen PM\smartbudget\backend"
npm run db:init
```

Avec transactions de demo:

```powershell
npm run db:init:samples
```

Mode simulation (sans ecriture):

```powershell
node scripts/init-db.js --dry-run
```

### Ciblage d'un utilisateur precis

Par UID:

```powershell
node scripts/init-db.js --uid=<FIREBASE_UID>
```

Par email (cree le compte si absent, avec mot de passe fourni):

```powershell
node scripts/init-db.js --email=<EMAIL> --password=<MOTDEPASSE>
```

### Variables d'environnement supportees

- `SEED_USER_UID`
- `SEED_USER_EMAIL`
- `SEED_USER_PASSWORD`
- `SEED_ALL_USERS=true`
- `SEED_WITH_SAMPLE_DATA=true`
- `SEED_DRY_RUN=true`

## 8. Test API automatique avec token Firebase

Script disponible: `scripts/smoke-api-auth.js`

Test rapide (recommande, sans mot de passe) via UID:

```powershell
cd "C:\Users\hp\Documents\Examen PM\smartbudget\backend"
npm run api:smoke -- --uid=<FIREBASE_UID> --base-url=http://127.0.0.1:3000
```

Alternative avec email/mot de passe:

```powershell
npm run api:smoke -- --email=<EMAIL> --password=<PASSWORD>
```

Afficher le token complet:

```powershell
npm run api:smoke -- --uid=<FIREBASE_UID> --show-token
```

Mode token uniquement (sans appels `/health`, `/me`, etc.):

```powershell
npm run api:smoke -- --uid=<FIREBASE_UID> --only-token
```

Variables d'environnement supportees:

- `API_BASE_URL`
- `FIREBASE_WEB_API_KEY`
- `AUTH_TEST_UID`
- `AUTH_TEST_EMAIL`
- `AUTH_TEST_PASSWORD`

---

Si cette checklist est cochee integralement, le backend est pret pour un passage prod controle.
