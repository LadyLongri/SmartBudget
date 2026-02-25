# SmartBudget Frontend (Flutter)

## 1) Objectif
Ce frontend Flutter fournit une application de gestion budgetaire mobile/desktop avec:
- onboarding visuel,
- authentification (email/mot de passe + Google),
- portefeuille multi-comptes,
- suivi depenses/revenus,
- statistiques lisibles,
- synchronisation locale + cloud.

## 2) Stack technique
- Flutter (Material 3)
- Firebase Auth
- Cloud Firestore
- SharedPreferences (cache local)
- UI custom (glass/neumorph + animations d'entree)

## 3) Ecrans frontend
- `SplashScreen`:
  - affiche le logo SB avec animation.
  - redirige automatiquement:
    - utilisateur connecte -> dashboard.
    - utilisateur non connecte -> landing.

- `LandingScreen`:
  - accueil premium coherent avec le style interne.
  - apercu portefeuille/statistiques.
  - bouton `Connexion`.

- `AuthScreen`:
  - mode `Connexion` / `Inscription`.
  - email + mot de passe.
  - connexion Google.
  - retour direct vers dashboard apres succes.

- `BudgetDashboardScreen` (principal):
  - 4 onglets:
    - `Accueil`
    - `Stats`
    - `Portefeuille`
    - `Reglages`
  - responsive mobile/desktop.

## 4) Fonctionnalites frontend implementees

### A. Budget, revenus, depenses
- saisie du budget initial.
- ajout de transaction datee (depense/revenu).
- reduction du budget restant selon les depenses.
- mise a jour des soldes de compte selon les mouvements.

### B. Portefeuille
- comptes principaux:
  - Visa
  - Mobile Money
  - Cash
- debiter/crediter chaque compte.
- section `Comptes lies` interactive (edition attributs).

### C. Categories separees (pas de liste commune)
- categories depenses et revenus distinctes.
- plus d'options courantes ajoutees.

Depenses:
- Alimentation, Restaurant, Transport, Carburant, Eau, Electricite, Telecom,
  Internet, Loyer, Sante, Sante familiale, Scolarite, Logement, Factures,
  Shopping, Loisirs, Education, Voyage, Imprevus, Autres.

Revenus:
- Salaire, Freelance, Business, Commerce, Commission, Prime, Remboursement,
  Aides familiales, Interets, Location, Vente, Cadeau, Autres revenus.

### D. Sources de paiement separees
Depenses:
- Visa, Compte bancaire, Mobile Money, Airtel Money, Orange Money, M-Pesa,
  Cash, Caisse.

Revenus:
- Compte bancaire, Mobile Money, Airtel Money, Orange Money, M-Pesa, Cash,
  Caisse.

### E. Statistiques lisibles et detaillees
- courbe revenus vs depenses.
- histogramme de tendance.
- donut par categorie.
- categorie dominante + montants.
- filtres de periode stats:
  - 7j, 30j, 90j, 12m, Tout, Custom (plage date).

Demarcation couleur:
- chaque categorie de depense a une couleur fixe.
- exemple:
  - Transport = orange
  - Restaurant = rouge
  - Sante = turquoise
  - etc.
- affichage visuel dans la legende (dot couleur + montant + pourcentage).

### F. Theme et personnalisation
- mode light prioritaire (mode sombre activable).
- palette de nuances et selection de nuance active.
- intensite glow reglable.
- devise configurable.

### G. Sauvegarde locale + cloud
- local:
  - `SharedPreferences` avec persistence immediate.
- cloud:
  - Firestore `users/{uid}/smartbudget/state`.
- fallback propre:
  - en cas de cloud indisponible, les donnees locales restent actives.
  - messages de statut cloud moins agressifs.
  - si local plus recent que cloud, l'app conserve local puis re-synchronise cloud.

### H. Export
- export CSV des transactions.
- copie CSV directe dans le presse-papiers depuis `Reglages`.

## 5) Synchronisation cloud (important)
Cause principale du `Echec sauvegarde cloud`:
- les regles Firestore n'autorisaient pas le chemin de sauvegarde dashboard.

Correction appliquee:
- regle ajoutee:
  - `match /users/{userId}/smartbudget/{docId} { allow read, write: if isOwner(userId); }`
- regles deployees sur le projet Firebase.

## 6) Commandes frontend utiles

Installation:
```bash
flutter pub get
```

Verification:
```bash
flutter analyze
flutter test
```

Execution Android:
```bash
flutter run -d <device_id>
```

Build APK release:
```bash
flutter build apk --release
```

APK genere:
- `build/app/outputs/flutter-apk/app-release.apk`

## 7) Distribution / mise en ligne test
- Firebase App Distribution utilise pour partager l'APK aux testeurs.
- lien testeur genere apres upload release.

## 8) Ce qui est deja fait (frontend)
- design landing + dashboard harmonises.
- logo SB integre.
- traduction interface en francais.
- auth email/password + Google.
- persistence locale.
- sync cloud par utilisateur.
- onglets interactifs.
- wallet/comptes lies interactifs.
- stats detaillees avec code couleur categorie.
- separation revenus/depenses (categories + sources).
- responsive mobile/desktop.

## 9) Ce qui manque encore (frontend)
- gestion complete des erreurs cloud par type (timeout, permission, quota).
- resolution des conflits multi-device avancee (merge transaction par transaction).
- export PDF des transactions et rapports mensuels.
- onboarding guide utilisateur in-app.
- tests widget/integration plus complets sur chaque onglet.
- iOS distribution test (TestFlight) si necessaire.

## 10) Fichiers frontend principaux
- `lib/main.dart`
- `lib/screens/splash_screen.dart`
- `lib/screens/landing_screen.dart`
- `lib/screens/auth_screen.dart`
- `lib/screens/budget_dashboard_screen.dart`
- `lib/core/theme.dart`
