#!/usr/bin/env node
/**
 * backfill-invoicing-counters.js
 *
 * One-time migration: reads all existing invoicing documents per user,
 * finds the maximum numeric suffix for each entity's human-readable ID,
 * and writes the counter doc so nextBusinessId continues from the right number.
 *
 * Safe to run multiple times (idempotent — always writes the correct max).
 *
 * Usage:
 *   node backend/scripts/backfill-invoicing-counters.js
 *   node backend/scripts/backfill-invoicing-counters.js --uid=SPECIFIC_UID
 */

require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const { init, getDb } = require('../src/core/firebase/firebase');
init();

const ENTITY_CONFIG = [
  { entity: 'bankCheques',               field: 'chequeId'         },
  { entity: 'bankDeposits',              field: 'depositId'        },
  { entity: 'expiryClaims',              field: 'claimId'          },
  { entity: 'paymentPromises',           field: 'promiseId'        },
  { entity: 'purchaseInvoices',          field: 'purchaseId'       },
  { entity: 'purchaseOrders',            field: 'orderId'          },
  { entity: 'purchaseReturns',           field: 'returnId'         },
  { entity: 'recoveryInvoices',          field: 'recoveryId'       },
  { entity: 'recoveryInvoicesWise',      field: 'recoveryId'       },
  { entity: 'recoveryReceivableWise',    field: 'recoveryId'       },
  { entity: 'salesInvoices',             field: 'saleId'           },
  { entity: 'salesReturns',              field: 'returnId'         },
  { entity: 'salesmanCashReconciliations', field: 'reconciliationId' },
  { entity: 'sendOrders',               field: 'sendOrderId'       },
  { entity: 'stockExpiries',            field: 'expiryId'          },
  { entity: 'stockIssues',              field: 'issueId'           },
  { entity: 'stockWastages',            field: 'wastageId'         },
];

async function getAllUsers(db) {
  const args = process.argv.slice(2);
  const uidArg = args.find(a => a.startsWith('--uid='));
  if (uidArg) return [uidArg.split('=')[1]];
  const snap = await db.collection('users').get();
  return snap.docs.map(d => d.id);
}

async function backfillUser(db, uid) {
  console.log(`\n  User: ${uid}`);
  const invoicingRef = db.collection('users').doc(uid).collection('invoicing');

  for (const { entity, field } of ENTITY_CONFIG) {
    const itemsSnap = await invoicingRef.doc(entity).collection('items').get();
    let max = 0;
    itemsSnap.docs.forEach(doc => {
      const val = doc.data()[field] || '';
      const n   = parseInt(val.replace(/\D/g, ''), 10);
      if (!isNaN(n) && n > max) max = n;
    });

    const counterRef = invoicingRef.doc(`counter_${entity}`);
    const existing   = await counterRef.get();
    const currentMax = existing.exists ? (existing.data().lastNo || 0) : 0;
    const writeMax   = Math.max(max, currentMax);

    await counterRef.set({ lastNo: writeMax, backfilledAt: new Date().toISOString() }, { merge: true });
    console.log(`    ${entity.padEnd(35)} max=${String(writeMax).padStart(4)}  (${itemsSnap.size} docs)`);
  }
}

async function main() {
  const db = getDb();
  if (!db) { console.error('Firebase not initialized — check credentials'); process.exit(1); }

  const uids = await getAllUsers(db);
  console.log(`Backfilling counters for ${uids.length} user(s)…`);

  for (const uid of uids) {
    await backfillUser(db, uid);
  }

  console.log('\n✓ Done — all counters are up to date.\n');
  process.exit(0);
}

main().catch(err => { console.error(err); process.exit(1); });
