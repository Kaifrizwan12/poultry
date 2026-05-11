# Farm Management SaaS

This phase adds the responsive app shell, placeholder home dashboard, and the full settings/definitions module across Flutter and Node.js.

## Settings API

- Base path: `/api/v1/settings`
- Auth: existing in-house JWT middleware in `backend/src/core/middleware/auth.middleware.js`
- Firestore storage: `users/{uid}/settings/{entity}/items/{docId}`

The original prompt used `users/{uid}/settings/{entity}/{docId}`. Firestore alternates collection and document segments, so this implementation stores entity metadata at `users/{uid}/settings/{entity}` and the actual records in that entity's `items` subcollection.

## Recommended Firestore indexes

- Single-field descending index on `createdAt` for each settings `items` subcollection
- Composite index on `groupId + subGroupId` for products
- Composite index on `townId + sectorId` for customers
- Composite index on `townId` for sectors

See `firestore.indexes.json` for a starting point.
