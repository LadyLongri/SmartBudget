# QA Bug Report - SmartBudget

## Format standard de signalement

- ID:
- Titre:
- Severite: `Blocker | Critique | Majeur | Mineur`
- Priorite: `P0 | P1 | P2 | P3`
- Environnement:
- Preconditions:
- Etapes de reproduction:
  1. ...
  2. ...
  3. ...
- Resultat attendu:
- Resultat obtenu:
- Capture:
- Statut: `Open | In Progress | Fixed | Retest`

---

## BUG-QA-001

- ID: `BUG-QA-001`
- Titre: Melange FR/EN sur l'interface `FrontendHomeScreen`
- Severite: Majeur
- Priorite: P1
- Environnement: Android emulator, Flutter app
- Preconditions: application lancee sur l'ecran `FrontendHomeScreen`
- Etapes de reproduction:
  1. Ouvrir l'ecran principal frontend.
  2. Observer la navigation basse et les libelles d'actions.
  3. Ouvrir la modal d'ajout transaction.
- Resultat attendu:
  - Interface 100% en francais (ex: "Transactions", "Statistiques", "Ajouter").
- Resultat obtenu:
  - Plusieurs textes restent en anglais (`Transaction`, `Statistic`, `Add transaction`, `Save day ...`).
- Capture:
  - `qa/captures/BUG-QA-001-mix-language.png` (a produire sur device)
- Statut: Open

## BUG-QA-002

- ID: `BUG-QA-002`
- Titre: Taxonomie categories incoherente entre ecrans de demo et dashboard principal
- Severite: Mineur
- Priorite: P2
- Environnement: Flutter app (frontend demo + dashboard principal)
- Preconditions: comparer les categories dans les deux experiences UI
- Etapes de reproduction:
  1. Ouvrir le flux `FrontendHomeScreen` et noter les categories (`Restaurant`, `Electricity`, `Education`, `Others`).
  2. Ouvrir le dashboard principal et noter les categories FR (`Alimentation`, `Transport`, `Sante`, etc.).
  3. Comparer les dictionnaires de categories et couleurs stats.
- Resultat attendu:
  - Un seul referentiel categories/couleurs pour toutes les vues.
- Resultat obtenu:
  - Deux taxonomies separes, risque de stats incoherentes en integration complete.
- Capture:
  - `qa/captures/BUG-QA-002-category-mismatch.png` (a produire sur device)
- Statut: Open
