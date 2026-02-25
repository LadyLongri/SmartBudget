# QA Test Plan - SmartBudget

## 1) Scope QA

Objectif: valider la livraison Feature Developer avant merge:

- robustesse API (smoke + erreurs standardisees)
- parcours utilisateur Flutter (login UI -> CRUD -> dashboard)
- contrat de reponse API et etats UI

## 2) Preconditions

- backend installable (`npm install` deja fait)
- Flutter SDK disponible
- environnement local sans regression critique

## 3) Scenarios de test

| ID | Type | Scenario | Etapes | Resultat attendu |
| --- | --- | --- | --- | --- |
| API-SMOKE-01 | API | Health check public | `GET /` puis `GET /health` | `200`, format `{ ok: true, data: ... }` |
| API-ERR-01 | API | Route protegee sans token | `GET /me` sans header Auth | `401`, `{ error: "missing_token", message }` |
| API-ERR-02 | API | Token fourni mais Firebase indisponible | `GET /me` avec `Bearer fake_token` et Firebase off | `503`, `{ error: "auth_unavailable", message }` |
| API-ERR-03 | API | Contrat erreur route transactions | `GET /transactions?limit=5` avec token fake | `503`, contrat erreur uniforme |
| API-ERR-04 | API | Contrat erreur route stats | `GET /stats/summary?month=2026-02` avec token fake | `503`, contrat erreur uniforme |
| FL-LOGIN-01 | Flutter | Validation login | Ouvrir Auth, cliquer "Se connecter" vide | erreurs "Email requis" + "Mot de passe requis" |
| FL-LOGIN-02 | Flutter | Validation inscription | Passer en inscription, mdp court, submit | erreur "Minimum 6 caracteres" |
| FL-CRUD-01 | Flutter | Ajout transaction | Ajouter une depense (title + amount) | transaction visible + montant maj |
| FL-CRUD-02 | Flutter | Suppression transaction | Supprimer la transaction | liste vide a nouveau |
| FL-DASH-01 | Flutter | Dashboard lisible apres CRUD | Aller onglet Statistic apres ajout | "Top category" visible et coherent |

## 4) Checklist de validation

- [ ] Tous les tests API passent
- [ ] Tous les tests Flutter passent
- [ ] Contrat API success/error conforme
- [ ] Aucun crash sur parcours critique
- [ ] Bugs bloques identifies avant merge

## 5) Couverture et limites

- Couverture auto validee sur:
  - smoke API
  - erreurs API standardisees
  - parcours Flutter de base (UI login + CRUD + stats)
- Hors scope auto:
  - login Firebase reel en widget test (dependant infra Firebase runtime)
  - scenarios reseau mobile reels (3G, timeout long, mode avion)
