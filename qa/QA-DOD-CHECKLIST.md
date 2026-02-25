# QA Definition of Done (DoD) - SmartBudget

Cette checklist QA doit etre validee avant merge vers `main`.

## 1) Build et tests

- [x] `npm test` (backend) passe sans echec
- [x] `flutter test` (app) passe sans echec
- [x] Aucun test flaky detecte sur 2 executions consecutives

## 2) API quality gate

- [x] Contrat succes respecte: `{ ok: true, data: ... }`
- [x] Contrat erreur respecte: `{ error, message, details? }`
- [ ] Endpoints stats verifies: summary / by-category / trend
- [x] Gestion erreur auth verifiee (`missing_token`, `invalid_token`, `auth_unavailable`)

## 3) Flutter feature gate

- [x] Parcours login UI valide (validation champs + messages erreurs)
- [x] CRUD local valide (ajout/suppression transaction)
- [x] Dashboard/statistiques se mettent a jour apres CRUD
- [x] Etats UI critiques couverts (`loading`, `empty`, `error`)

## 4) Bug management gate

- [x] Bugs Blocker/Critique = 0
- [ ] Tous les bugs Majeurs ont decision explicite (fix ou waiver)
- [x] Chaque bug a etapes + attendu/obtenu + capture

## 5) Merge gate

- [ ] PR relue
- [x] Evidence QA attachee (`qa/evidence/*`)
- [ ] Go QA explicite avant merge
