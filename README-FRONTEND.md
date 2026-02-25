# SmartBudget Frontend

Ce README decrit l'etat reel du frontend Flutter a date.
L'objectif etait d'avoir une app utilisable tout de suite: visuelle, en francais,
avec de la persistence et des stats lisibles.

## Ce que fait l'application aujourd'hui

Le parcours principal est deja en place:
- splash avec logo SB,
- landing page,
- authentification email/mot de passe + Google,
- dashboard principal.

Le dashboard est organise en 4 onglets:
- `Accueil`
- `Stats`
- `Portefeuille`
- `Reglages`

L'interface est responsive mobile/desktop, avec un style glass/neumorph
et un theme light prioritaire.

## Fonctionnalites frontend deja livrees

### Budget et transactions
- saisie d'un budget de depart,
- ajout depense/revenu avec date,
- impact direct sur le budget restant et les soldes.

### Portefeuille
- comptes principaux: Visa, Mobile Money, Cash,
- debit/credit interactif par compte,
- comptes lies modifiables (alias, type, etat).

### Categories et sources (separees)
- depenses et revenus ont leurs propres listes,
- categories enrichies avec options courantes,
- sources de paiement separees (banque, mobile money, cash, etc.).

### Statistiques
- donut par categorie,
- comparaison revenus/depenses,
- barres de tendance,
- categorie dominante + pourcentages + montants.

En plus:
- couleur fixe par categorie de depense (repere visuel constant),
- filtres periode (7j, 30j, 90j, 12m, tout, custom),
- filtres API (mois, devise).

### Donnees et synchronisation
- sauvegarde locale via `SharedPreferences`,
- sauvegarde cloud Firestore par utilisateur,
- fallback local si cloud indisponible,
- logique simple de priorite locale si etat local plus recent.

### Export
- export CSV des transactions (copie dans le presse-papiers depuis Reglages).

## Technique (frontend)

Stack:
- Flutter (Material 3)
- Firebase Auth
- Firestore
- SharedPreferences

Fichiers centraux:
- `lib/screens/budget_dashboard_screen.dart`
- `lib/screens/auth_screen.dart`
- `lib/screens/landing_screen.dart`
- `lib/screens/splash_screen.dart`
- `lib/services/dashboard_feature_service.dart`
- `lib/models/stats_models.dart`

## Lancer et verifier

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Build Android release:
```bash
flutter build apk --release
```

APK:
- `build/app/outputs/flutter-apk/app-release.apk`

## Distribution

Pour les tests Android, l'app peut etre partagee via Firebase App Distribution.

## Ce qu'il reste a faire

- gestion erreurs cloud plus fine (timeout, permissions, quota),
- strategie de merge multi-appareils plus robuste,
- export PDF (le CSV est deja disponible),
- tests widget/integration supplementaires sur le dashboard complet,
- finalisation iOS/TestFlight (hors scope actuel).
