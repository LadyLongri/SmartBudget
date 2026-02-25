# QA Package - SmartBudget

Ce document centralise la livraison Quality Engineer (QA) pour la partie
Feature Developer.

## Contenu

- Plan de tests + checklist: [qa/QA-TEST-PLAN.md](qa/QA-TEST-PLAN.md)
- Signalement de bugs: [qa/QA-BUG-REPORT.md](qa/QA-BUG-REPORT.md)
- Validation Definition of Done: [qa/QA-DOD-CHECKLIST.md](qa/QA-DOD-CHECKLIST.md)
- Captures / preuves d'execution: [qa/evidence](qa/evidence)

## Tests automatises ajoutes

### API

- [backend/test/qa-api-contract.test.js](backend/test/qa-api-contract.test.js)
  - smoke sur `/` et `/health`
  - verification du contrat erreur (`missing_token`, `auth_unavailable`)
  - verification du contrat sur routes protegees (`/transactions`, `/stats/summary`)

### Flutter

- [test/qa_user_flow_test.dart](test/qa_user_flow_test.dart)
  - login UI: validations formulaire
  - CRUD local: ajout/suppression transaction
  - dashboard/statistiques: verif mise a jour apres CRUD

## Commandes QA

```powershell
# API tests
cd backend
npm test

# Flutter tests
cd ..
flutter test
```

## Notes

- Les tests API "smoke-auth avec vrai token Firebase" restent disponibles via:
  `npm run api:smoke` (backend deja demarre + credentials Firebase requis).
- Le package QA ne fait pas de merge auto sur `main`.
