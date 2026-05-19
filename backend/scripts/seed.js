#!/usr/bin/env node
/**
 * seed.js — Ultra-comprehensive seed data for the poultry farm app.
 *
 * Creates realistic, fully cross-linked data across every module:
 *   Settings  → accounts, towns, sectors, vendors, salesmen, customers,
 *               products (with groups/subgroups), units, packings,
 *               discount schemes, posting config
 *   Poultry   → feed schedules, vaccine schedules, flocks, flock feeds,
 *               flock vaccines, chicken invoices
 *   Invoicing → sales invoices (linked + standalone), purchase invoices,
 *               recovery invoices, cash vouchers, bank deposits, bank cheques
 *   Accounts  → ledger entries for every financial event
 *
 * After writing, the script validates EVERY cross-reference in the seeded
 * data and prints a pass/fail report.
 *
 * Usage:
 *   node backend/scripts/seed.js --uid=<FIREBASE_UID>
 *   node backend/scripts/seed.js --uid=<FIREBASE_UID> --wipe   # delete first
 */

require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const { init, getDb } = require('../src/core/firebase/firebase');
init();

// ─── CLI args ─────────────────────────────────────────────────────────────────

const args = Object.fromEntries(
  process.argv.slice(2)
    .filter(a => a.startsWith('--'))
    .map(a => { const [k, v] = a.slice(2).split('='); return [k, v ?? true]; })
);

const UID = args.uid;
if (!UID) { console.error('Usage: node seed.js --uid=<UID>'); process.exit(1); }
const WIPE = !!args.wipe;

// ─── Firestore helpers ────────────────────────────────────────────────────────

const db = () => getDb();
const ts = () => new Date().toISOString();

const col = {
  settings:  (entity)      => db().collection('users').doc(UID).collection('settings').doc(entity).collection('items'),
  poultry:   (entity)      => db().collection('users').doc(UID).collection('poultry').doc(entity).collection('items'),
  invoicing: (entity)      => db().collection('users').doc(UID).collection('invoicing').doc(entity).collection('items'),
  accounts:  (entity)      => db().collection('users').doc(UID).collection('accounts').doc(entity).collection('items'),
  // invoicing counter docs
  counter:   (entity)      => db().collection('users').doc(UID).collection('invoicing').doc(`counter_${entity}`),
};

async function set(colRef, id, data) {
  const now = ts();
  await colRef.doc(id).set({ ...data, uid: UID, createdAt: now, updatedAt: now });
}

async function batchWrite(colRef, docs) {
  const chunks = [];
  for (let i = 0; i < docs.length; i += 400) chunks.push(docs.slice(i, i + 400));
  for (const chunk of chunks) {
    const b = db().batch();
    const now = ts();
    for (const [id, data] of chunk) b.set(colRef.doc(id), { ...data, uid: UID, createdAt: now, updatedAt: now });
    await b.commit();
  }
}

async function wipeCollection(colRef) {
  const snap = await colRef.get();
  if (snap.empty) return;
  const chunks = [];
  for (let i = 0; i < snap.docs.length; i += 400) chunks.push(snap.docs.slice(i, i + 400));
  for (const chunk of chunks) {
    const b = db().batch();
    chunk.forEach(d => b.delete(d.ref));
    await b.commit();
  }
}

// ─── Validation registry ──────────────────────────────────────────────────────

const ERRORS = [];
function fail(msg) { ERRORS.push(msg); }

async function assertExists(colRef, id, label) {
  if (!id) { fail(`${label}: id is empty`); return; }
  const snap = await colRef.doc(id).get();
  if (!snap.exists) fail(`${label}: doc "${id}" not found in collection`);
}

// ─── ID helpers ───────────────────────────────────────────────────────────────

let _siSeq=0,_piSeq=0,_recSeq=0,_cvSeq=0,_bdSeq=0,_bcSeq=0,
    _poSeq=0,_soSeq=0,_srSeq=0,_prSeq=0,_stiSeq=0,
    _wasSeq=0,_expSeq=0,_clmSeq=0,_riwSeq=0,_rrwSeq=0,
    _scrSeq=0,_ppSeq=0;
const nextSI  = () => `SI-${String(++_siSeq).padStart(4,'0')}`;
const nextPI  = () => `PI-${String(++_piSeq).padStart(4,'0')}`;
const nextREC = () => `REC-${String(++_recSeq).padStart(4,'0')}`;
const nextCV  = () => `JV-${String(++_cvSeq).padStart(4,'0')}`;
const nextBD  = () => `BD-${String(++_bdSeq).padStart(4,'0')}`;
const nextBC  = () => `CHQ-${String(++_bcSeq).padStart(4,'0')}`;
const nextPO  = () => `PO-${String(++_poSeq).padStart(4,'0')}`;
const nextSO  = () => `SO-${String(++_soSeq).padStart(4,'0')}`;
const nextSR  = () => `SR-${String(++_srSeq).padStart(4,'0')}`;
const nextPR  = () => `PR-${String(++_prSeq).padStart(4,'0')}`;
const nextSTI = () => `STI-${String(++_stiSeq).padStart(4,'0')}`;
const nextWAS = () => `WAS-${String(++_wasSeq).padStart(4,'0')}`;
const nextEXP = () => `EXP-${String(++_expSeq).padStart(4,'0')}`;
const nextCLM = () => `CLM-${String(++_clmSeq).padStart(4,'0')}`;
const nextRIW = () => `RIW-${String(++_riwSeq).padStart(4,'0')}`;
const nextRRW = () => `RRW-${String(++_rrwSeq).padStart(4,'0')}`;
const nextSCR = () => `SCR-${String(++_scrSeq).padStart(4,'0')}`;
const nextPP  = () => `PP-${String(++_ppSeq).padStart(4,'0')}`;

function pad(n) { return String(n).padStart(4, '0'); }

// ─── Date helpers ─────────────────────────────────────────────────────────────

function daysAgo(n) {
  const d = new Date(); d.setDate(d.getDate() - n);
  return d.toISOString().substring(0, 10);
}

// ══════════════════════════════════════════════════════════════════════════════
// PHASE 1 — SETTINGS
// ══════════════════════════════════════════════════════════════════════════════

async function seedSettings() {
  console.log('\n[1/4] Seeding settings…');

  // ── Units ───────────────────────────────────────────────────────────────────
  const units = [
    ['u-kg',  { name: 'KG',  shortName: 'kg'  }],
    ['u-g',   { name: 'Gram', shortName: 'g'  }],
    ['u-pcs', { name: 'Pieces', shortName: 'pcs' }],
    ['u-ltr', { name: 'Litre', shortName: 'ltr' }],
  ];
  await batchWrite(col.settings('units'), units);
  console.log('  ✓ units (4)');

  // ── Packings ─────────────────────────────────────────────────────────────────
  const packings = [
    ['pk-1',  { name: 'Loose',   pack: 1  }],
    ['pk-12', { name: 'Tray-12', pack: 12 }],
    ['pk-24', { name: 'Box-24',  pack: 24 }],
    ['pk-50', { name: 'Bag-50',  pack: 50 }],
  ];
  await batchWrite(col.settings('packings'), packings);
  console.log('  ✓ packings (4)');

  // ── Product groups & sub-groups ───────────────────────────────────────────
  await batchWrite(col.settings('productGroups'), [
    ['pg-feed',    { name: 'Feed',    code: 'FD' }],
    ['pg-medicine',{ name: 'Medicine',code: 'MD' }],
    ['pg-chicken', { name: 'Chicken', code: 'CK' }],
  ]);
  await batchWrite(col.settings('productSubGroups'), [
    ['psg-starter',  { name: 'Starter Feed',  productGroupId: 'pg-feed'     }],
    ['psg-grower',   { name: 'Grower Feed',   productGroupId: 'pg-feed'     }],
    ['psg-finisher', { name: 'Finisher Feed', productGroupId: 'pg-feed'     }],
    ['psg-vaccine',  { name: 'Vaccine',       productGroupId: 'pg-medicine' }],
    ['psg-antibiotic',{ name: 'Antibiotic',   productGroupId: 'pg-medicine' }],
    ['psg-broiler',  { name: 'Broiler',       productGroupId: 'pg-chicken'  }],
  ]);
  console.log('  ✓ product groups & sub-groups');

  // ── Products ─────────────────────────────────────────────────────────────────
  const products = [
    ['prod-feed-s',  { name: 'Starter Feed 50kg',  productGroupId: 'pg-feed',    productSubGroupId: 'psg-starter',  unitId: 'u-kg',  packingId: 'pk-50', costPrice: 3200, salePrice: 3400, pack: 50 }],
    ['prod-feed-g',  { name: 'Grower Feed 50kg',   productGroupId: 'pg-feed',    productSubGroupId: 'psg-grower',   unitId: 'u-kg',  packingId: 'pk-50', costPrice: 3000, salePrice: 3200, pack: 50 }],
    ['prod-feed-f',  { name: 'Finisher Feed 50kg', productGroupId: 'pg-feed',    productSubGroupId: 'psg-finisher', unitId: 'u-kg',  packingId: 'pk-50', costPrice: 2800, salePrice: 3000, pack: 50 }],
    ['prod-newcas',  { name: 'Newcastle Vaccine',   productGroupId: 'pg-medicine',productSubGroupId: 'psg-vaccine',  unitId: 'u-pcs', packingId: 'pk-1',  costPrice: 180,  salePrice: 220,  pack: 1  }],
    ['prod-gumboro', { name: 'Gumboro Vaccine',     productGroupId: 'pg-medicine',productSubGroupId: 'psg-vaccine',  unitId: 'u-pcs', packingId: 'pk-1',  costPrice: 200,  salePrice: 250,  pack: 1  }],
    ['prod-amox',    { name: 'Amoxicillin 100g',    productGroupId: 'pg-medicine',productSubGroupId: 'psg-antibiotic',unitId: 'u-g', packingId: 'pk-1',  costPrice: 450,  salePrice: 550,  pack: 1  }],
    ['prod-chicken', { name: 'Live Broiler Chicken',productGroupId: 'pg-chicken', productSubGroupId: 'psg-broiler',  unitId: 'u-kg',  packingId: 'pk-1',  costPrice: 0,    salePrice: 0,    pack: 1  }],
  ];
  await batchWrite(col.settings('products'), products);
  console.log('  ✓ products (7)');

  // ── Accounts (Chart of Accounts) ─────────────────────────────────────────
  const accounts = [
    // Assets
    ['acc-cash',    { accountCode: '1001', accountName: 'Cash in Hand',          accountType: 'asset',   balanceType: 'debit',  openingBalance: 150000 }],
    ['acc-bank',    { accountCode: '1002', accountName: 'Bank — HBL Current',    accountType: 'asset',   balanceType: 'debit',  openingBalance: 500000 }],
    ['acc-ar',      { accountCode: '1100', accountName: 'Accounts Receivable',   accountType: 'asset',   balanceType: 'debit',  openingBalance: 0 }],
    ['acc-stock',   { accountCode: '1200', accountName: 'Poultry Stock',         accountType: 'asset',   balanceType: 'debit',  openingBalance: 80000 }],
    ['acc-feed',    { accountCode: '1201', accountName: 'Feed Inventory',        accountType: 'asset',   balanceType: 'debit',  openingBalance: 120000 }],
    ['acc-medicine',{ accountCode: '1202', accountName: 'Medicine Inventory',    accountType: 'asset',   balanceType: 'debit',  openingBalance: 30000 }],
    // Liabilities
    ['acc-ap',      { accountCode: '2001', accountName: 'Accounts Payable',      accountType: 'liability',balanceType: 'credit', openingBalance: 0 }],
    ['acc-tax',     { accountCode: '2100', accountName: 'Sales Tax Payable',     accountType: 'liability',balanceType: 'credit', openingBalance: 0 }],
    // Income
    ['acc-rev',     { accountCode: '4001', accountName: 'Sales Revenue — Chicken',accountType: 'income', balanceType: 'credit', openingBalance: 0 }],
    ['acc-rev-feed',{ accountCode: '4002', accountName: 'Sales Revenue — Feed',  accountType: 'income', balanceType: 'credit', openingBalance: 0 }],
    ['acc-discount',{ accountCode: '4100', accountName: 'Sales Discounts',       accountType: 'income', balanceType: 'debit',  openingBalance: 0 }],
    // Expenses
    ['acc-cogs',    { accountCode: '5001', accountName: 'Cost of Goods Sold',   accountType: 'expense', balanceType: 'debit',  openingBalance: 0 }],
    ['acc-wages',   { accountCode: '5100', accountName: 'Wages & Salaries',      accountType: 'expense', balanceType: 'debit',  openingBalance: 0 }],
    ['acc-util',    { accountCode: '5200', accountName: 'Utilities — Electric',  accountType: 'expense', balanceType: 'debit',  openingBalance: 0 }],
    ['acc-transport',{ accountCode: '5300', accountName: 'Transport Expenses',   accountType: 'expense', balanceType: 'debit',  openingBalance: 0 }],
  ];
  await batchWrite(col.settings('accounts'), accounts);
  console.log('  ✓ accounts — chart of accounts (15)');

  // ── Towns & Sectors ───────────────────────────────────────────────────────
  const towns = [
    ['town-lhr', { name: 'Lahore',     code: 'LHR' }],
    ['town-fsd', { name: 'Faisalabad', code: 'FSD' }],
    ['town-mul', { name: 'Multan',     code: 'MUL' }],
    ['town-rwp', { name: 'Rawalpindi', code: 'RWP' }],
  ];
  await batchWrite(col.settings('towns'), towns);

  const sectors = [
    ['sec-dha',   { name: 'DHA',        townId: 'town-lhr' }],
    ['sec-gulb',  { name: 'Gulberg',    townId: 'town-lhr' }],
    ['sec-jinn',  { name: 'Jinnah Colony', townId: 'town-fsd' }],
    ['sec-chenab',{ name: 'Chenab Nagar',  townId: 'town-fsd' }],
    ['sec-kha',   { name: 'Khanewal Road', townId: 'town-mul' }],
    ['sec-sat',   { name: 'Satellite Town', townId: 'town-rwp' }],
  ];
  await batchWrite(col.settings('sectors'), sectors);
  console.log('  ✓ towns (4) + sectors (6)');

  // ── Vendors (chick suppliers) ─────────────────────────────────────────────
  const vendors = [
    ['vnd-sunrise',  { name: 'Sunrise Hatchery',    contactNo: '0300-1234567', address: 'Lahore', townId: 'town-lhr', openingBalance: 0 }],
    ['vnd-goldenfarm',{ name: 'Golden Farm Ltd',    contactNo: '0311-9876543', address: 'Faisalabad', townId: 'town-fsd', openingBalance: 50000 }],
    ['vnd-pak-feed', { name: 'Pak Feed Industries', contactNo: '0333-5555555', address: 'Multan', townId: 'town-mul', openingBalance: 80000 }],
  ];
  await batchWrite(col.settings('vendors'), vendors);
  console.log('  ✓ vendors (3)');

  // ── Salesmen ──────────────────────────────────────────────────────────────
  const salesmen = [
    ['sm-ali',   { name: 'Ali Raza',    contactNo: '0321-1111111', townId: 'town-lhr', commissionType: 'percentage', commissionRate: 1.5 }],
    ['sm-ahmed', { name: 'Ahmed Shah',  contactNo: '0321-2222222', townId: 'town-fsd', commissionType: 'percentage', commissionRate: 2.0 }],
    ['sm-usman', { name: 'Usman Khan',  contactNo: '0321-3333333', townId: 'town-mul', commissionType: 'flat',       commissionRate: 500 }],
  ];
  await batchWrite(col.settings('salesmen'), salesmen);
  console.log('  ✓ salesmen (3)');

  // ── Customers ─────────────────────────────────────────────────────────────
  const customers = [
    ['cust-rehman',  { name: 'Rehman Poultry', contactNo: '0300-9001001', townId: 'town-lhr', sectorId: 'sec-dha',    salesmanId: 'sm-ali',   openingBalance: 25000,  creditLimit: 200000 }],
    ['cust-farhan',  { name: 'Farhan Traders',  contactNo: '0300-9002002', townId: 'town-lhr', sectorId: 'sec-gulb',   salesmanId: 'sm-ali',   openingBalance: 0,      creditLimit: 150000 }],
    ['cust-bilal',   { name: 'Bilal & Sons',    contactNo: '0311-9003003', townId: 'town-fsd', sectorId: 'sec-jinn',   salesmanId: 'sm-ahmed', openingBalance: 40000,  creditLimit: 300000 }],
    ['cust-tariq',   { name: 'Tariq Poultry',   contactNo: '0311-9004004', townId: 'town-fsd', sectorId: 'sec-chenab', salesmanId: 'sm-ahmed', openingBalance: 0,      creditLimit: 100000 }],
    ['cust-nadeem',  { name: 'Nadeem Farms',    contactNo: '0333-9005005', townId: 'town-mul', sectorId: 'sec-kha',    salesmanId: 'sm-usman', openingBalance: 15000,  creditLimit: 250000 }],
    ['cust-kashif',  { name: 'Kashif Brothers', contactNo: '0333-9006006', townId: 'town-mul', sectorId: 'sec-kha',    salesmanId: 'sm-usman', openingBalance: 0,      creditLimit: 180000 }],
  ];
  await batchWrite(col.settings('customers'), customers);
  console.log('  ✓ customers (6)');

  // ── Discount Schemes ──────────────────────────────────────────────────────
  await batchWrite(col.settings('discountSchemes'), [
    ['ds-bulk',    { name: 'Bulk Buyer 5%',    discountType: 'percentage', discountValue: 5,  applicableTo: 'all'     }],
    ['ds-loyal',   { name: 'Loyal Customer',   discountType: 'flat',       discountValue: 500, applicableTo: 'all'    }],
  ]);
  console.log('  ✓ discount schemes (2)');

  // ── Posting Configuration ─────────────────────────────────────────────────
  const postCfgDoc = db().collection('users').doc(UID).collection('settings').doc('postingConfig');
  await postCfgDoc.set({
    chickenProductId:      'prod-chicken',
    arAccountId:           'acc-ar',
    salesRevenueAccountId: 'acc-rev',
    cashAccountId:         'acc-cash',
    apAccountId:           'acc-ap',
    cogsAccountId:         'acc-cogs',
    feedInventoryAccountId:'acc-feed',
    bankAccountId:         'acc-bank',
    uid: UID, updatedAt: ts(),
  }, { merge: true });
  console.log('  ✓ posting config');

  console.log('  [Phase 1 complete]\n');
}

// ══════════════════════════════════════════════════════════════════════════════
// PHASE 2 — POULTRY
// ══════════════════════════════════════════════════════════════════════════════

async function seedPoultry() {
  console.log('[2/4] Seeding poultry…');

  // ── Feed schedules ────────────────────────────────────────────────────────
  await batchWrite(col.poultry('feedSchedules'), [
    ['fs-broiler-std', {
      name: 'Standard Broiler Feed Programme', birdType: 'broiler',
      phases: [
        { phase: 'Starter',  dayFrom: 1,  dayTo: 10, productId: 'prod-feed-s', gramsPerBird: 20 },
        { phase: 'Grower',   dayFrom: 11, dayTo: 28, productId: 'prod-feed-g', gramsPerBird: 60 },
        { phase: 'Finisher', dayFrom: 29, dayTo: 42, productId: 'prod-feed-f', gramsPerBird: 110 },
      ],
    }],
  ]);

  // ── Vaccine schedules ────────────────────────────────────────────────────
  await batchWrite(col.poultry('vaccineSchedules'), [
    ['vs-broiler-std', {
      name: 'Standard Broiler Vaccine Programme', birdType: 'broiler',
      vaccinations: [
        { day: 7,  name: 'Newcastle (ND) La Sota', productId: 'prod-newcas', route: 'eye_drop' },
        { day: 14, name: 'Gumboro IBD',             productId: 'prod-gumboro',route: 'water'    },
        { day: 21, name: 'Newcastle (ND) Booster',  productId: 'prod-newcas', route: 'water'    },
      ],
    }],
  ]);
  console.log('  ✓ feed schedule + vaccine schedule');

  // ── Flocks ────────────────────────────────────────────────────────────────
  // Flock A: completed & sold
  await set(col.poultry('flocks'), 'flock-a', {
    flockNo: 'FL-0001', flockName: 'Batch Alpha 2024', birdType: 'broiler',
    shedNo: 'Shed-1', vendorId: 'vnd-sunrise',
    placementDate: daysAgo(60), targetAgeDays: 42, targetWeightKg: 2.2,
    initialBirdsCount: 5000, currentBirdsCount: 0,
    mortalityCount: 120, mortalityRate: 2.4,
    feedScheduleId: 'fs-broiler-std', vaccineScheduleId: 'vs-broiler-std',
    status: 'sold', closureDate: daysAgo(18),
  });

  // Flock B: active, partially sold
  await set(col.poultry('flocks'), 'flock-b', {
    flockNo: 'FL-0002', flockName: 'Batch Beta 2024', birdType: 'broiler',
    shedNo: 'Shed-2', vendorId: 'vnd-goldenfarm',
    placementDate: daysAgo(35), targetAgeDays: 42, targetWeightKg: 2.0,
    initialBirdsCount: 8000, currentBirdsCount: 5500,
    mortalityCount: 200, mortalityRate: 2.5,
    feedScheduleId: 'fs-broiler-std', vaccineScheduleId: 'vs-broiler-std',
    status: 'active', closureDate: '',
  });

  // Flock C: active, not sold yet
  await set(col.poultry('flocks'), 'flock-c', {
    flockNo: 'FL-0003', flockName: 'Batch Gamma 2024', birdType: 'broiler',
    shedNo: 'Shed-3', vendorId: 'vnd-sunrise',
    placementDate: daysAgo(15), targetAgeDays: 42, targetWeightKg: 2.1,
    initialBirdsCount: 6000, currentBirdsCount: 5950,
    mortalityCount: 50, mortalityRate: 0.83,
    feedScheduleId: 'fs-broiler-std', vaccineScheduleId: 'vs-broiler-std',
    status: 'active', closureDate: '',
  });
  console.log('  ✓ flocks (3): A=sold, B=active-partial, C=active');

  // ── Flock feeds ───────────────────────────────────────────────────────────
  const feeds = [
    // Flock A — full lifecycle
    ['ff-a-1', { flockId: 'flock-a', date: daysAgo(58), productId: 'prod-feed-s', bags: 20, birdsCount: 5000, mortalityCount: 10, notes: 'Day 2 — Starter' }],
    ['ff-a-2', { flockId: 'flock-a', date: daysAgo(50), productId: 'prod-feed-s', bags: 40, birdsCount: 4990, mortalityCount: 0,  notes: 'Day 10 — Starter end' }],
    ['ff-a-3', { flockId: 'flock-a', date: daysAgo(42), productId: 'prod-feed-g', bags: 80, birdsCount: 4970, mortalityCount: 20, notes: 'Day 18 — Grower' }],
    ['ff-a-4', { flockId: 'flock-a', date: daysAgo(34), productId: 'prod-feed-g', bags: 90, birdsCount: 4940, mortalityCount: 30, notes: 'Day 26 — Grower' }],
    ['ff-a-5', { flockId: 'flock-a', date: daysAgo(26), productId: 'prod-feed-f', bags: 60, birdsCount: 4900, mortalityCount: 40, notes: 'Day 34 — Finisher' }],
    ['ff-a-6', { flockId: 'flock-a', date: daysAgo(20), productId: 'prod-feed-f', bags: 50, birdsCount: 4880, mortalityCount: 20, notes: 'Day 40 — Final feed' }],
    // Flock B — ongoing
    ['ff-b-1', { flockId: 'flock-b', date: daysAgo(33), productId: 'prod-feed-s', bags: 30, birdsCount: 8000, mortalityCount: 50,  notes: 'Day 2 — Starter' }],
    ['ff-b-2', { flockId: 'flock-b', date: daysAgo(25), productId: 'prod-feed-s', bags: 60, birdsCount: 7950, mortalityCount: 50,  notes: 'Day 10 — Starter end' }],
    ['ff-b-3', { flockId: 'flock-b', date: daysAgo(17), productId: 'prod-feed-g', bags: 120, birdsCount: 7800, mortalityCount: 100, notes: 'Day 18 — Grower' }],
    ['ff-b-4', { flockId: 'flock-b', date: daysAgo(9),  productId: 'prod-feed-g', bags: 130, birdsCount: 7700, mortalityCount: 100, notes: 'Day 26 — Grower' }],
    // Flock C — new
    ['ff-c-1', { flockId: 'flock-c', date: daysAgo(13), productId: 'prod-feed-s', bags: 15, birdsCount: 6000, mortalityCount: 30, notes: 'Day 2 — Starter' }],
    ['ff-c-2', { flockId: 'flock-c', date: daysAgo(7),  productId: 'prod-feed-s', bags: 25, birdsCount: 5970, mortalityCount: 20, notes: 'Day 8 — Starter' }],
  ];
  await batchWrite(col.poultry('flockFeeds'), feeds);
  console.log('  ✓ flock feeds (12)');

  // ── Flock vaccines ────────────────────────────────────────────────────────
  const vaccines = [
    ['fv-a-1', { flockId: 'flock-a', date: daysAgo(53), productId: 'prod-newcas',  dosesUsed: 50, vaccineName: 'ND La Sota', route: 'eye_drop', notes: 'Day 7' }],
    ['fv-a-2', { flockId: 'flock-a', date: daysAgo(46), productId: 'prod-gumboro', dosesUsed: 50, vaccineName: 'Gumboro IBD',route: 'water',    notes: 'Day 14' }],
    ['fv-a-3', { flockId: 'flock-a', date: daysAgo(39), productId: 'prod-newcas',  dosesUsed: 50, vaccineName: 'ND Booster',  route: 'water',    notes: 'Day 21' }],
    ['fv-b-1', { flockId: 'flock-b', date: daysAgo(28), productId: 'prod-newcas',  dosesUsed: 80, vaccineName: 'ND La Sota', route: 'eye_drop', notes: 'Day 7' }],
    ['fv-b-2', { flockId: 'flock-b', date: daysAgo(21), productId: 'prod-gumboro', dosesUsed: 80, vaccineName: 'Gumboro IBD',route: 'water',    notes: 'Day 14' }],
    ['fv-c-1', { flockId: 'flock-c', date: daysAgo(8),  productId: 'prod-newcas',  dosesUsed: 60, vaccineName: 'ND La Sota', route: 'eye_drop', notes: 'Day 7' }],
  ];
  await batchWrite(col.poultry('flockVaccines'), vaccines);
  console.log('  ✓ flock vaccines (6)');

  // ── Chicken invoices (sales from flock) ───────────────────────────────────
  // Flock A: fully sold in two batches
  const ci_a1 = {
    invoiceNo: 'CI-0001', flockId: 'flock-a',
    customerId: 'cust-rehman', salesmanId: 'sm-ali',
    invoiceDate: daysAgo(20), saleType: 'live_weight',
    birdsCount: 2500, totalLiveWeightKg: 5250, dressedWeightKg: 0,
    pricePerKg: 270, grossAmount: 1417500,
    discountPercent: 2, discountAmount: 28350, netAmount: 1389150,
    taxPercent: 0, taxAmount: 0, totalAmount: 1389150,
    advanceReceived: 500000, balanceDue: 889150, paymentStatus: 'partial',
    vehicleNo: 'LHR-1234', driverName: 'Malik Rashid',
    postToLedger: true, createSalesInvoice: true,
    linkedSalesInvoiceId: 'si-ci-a1', linkedLedgerEntryIds: ['le-ci-a1-ar', 'le-ci-a1-rev', 'le-ci-a1-cash', 'le-ci-a1-ar-adv'],
    notes: 'First batch sale from Flock A',
  };
  await set(col.poultry('chickenInvoices'), 'ci-a1', ci_a1);

  const ci_a2 = {
    invoiceNo: 'CI-0002', flockId: 'flock-a',
    customerId: 'cust-bilal', salesmanId: 'sm-ahmed',
    invoiceDate: daysAgo(18), saleType: 'live_weight',
    birdsCount: 2380, totalLiveWeightKg: 4998, dressedWeightKg: 0,
    pricePerKg: 268, grossAmount: 1339464,
    discountPercent: 0, discountAmount: 0, netAmount: 1339464,
    taxPercent: 0, taxAmount: 0, totalAmount: 1339464,
    advanceReceived: 1339464, balanceDue: 0, paymentStatus: 'paid',
    vehicleNo: 'FSD-5678', driverName: 'Anwar Ali',
    postToLedger: true, createSalesInvoice: true,
    linkedSalesInvoiceId: 'si-ci-a2', linkedLedgerEntryIds: ['le-ci-a2-ar', 'le-ci-a2-rev', 'le-ci-a2-cash', 'le-ci-a2-ar-adv'],
    notes: 'Second batch — full flock cleared',
  };
  await set(col.poultry('chickenInvoices'), 'ci-a2', ci_a2);

  // Flock B: partially sold
  const ci_b1 = {
    invoiceNo: 'CI-0003', flockId: 'flock-b',
    customerId: 'cust-nadeem', salesmanId: 'sm-usman',
    invoiceDate: daysAgo(5), saleType: 'live_weight',
    birdsCount: 2500, totalLiveWeightKg: 5000, dressedWeightKg: 0,
    pricePerKg: 265, grossAmount: 1325000,
    discountPercent: 0, discountAmount: 0, netAmount: 1325000,
    taxPercent: 0, taxAmount: 0, totalAmount: 1325000,
    advanceReceived: 0, balanceDue: 1325000, paymentStatus: 'unpaid',
    vehicleNo: 'MUL-9999', driverName: 'Zubair Hussain',
    postToLedger: true, createSalesInvoice: true,
    linkedSalesInvoiceId: 'si-ci-b1', linkedLedgerEntryIds: ['le-ci-b1-ar', 'le-ci-b1-rev'],
    notes: 'Partial sale Flock B',
  };
  await set(col.poultry('chickenInvoices'), 'ci-b1', ci_b1);

  console.log('  ✓ chicken invoices (3)');
  console.log('  [Phase 2 complete]\n');
}

// ══════════════════════════════════════════════════════════════════════════════
// PHASE 3 — INVOICING + ACCOUNTS
// ══════════════════════════════════════════════════════════════════════════════

async function seedInvoicingAndAccounts() {
  console.log('[3/4] Seeding invoicing + accounts…');

  const now = ts();

  // ── Sales invoices linked to chicken invoices ─────────────────────────────
  const si_ci_a1 = {
    saleId: nextSI(), entryDate: daysAgo(20),
    customerId: 'cust-rehman', customerName: 'Rehman Poultry',
    townId: 'town-lhr', sectorId: 'sec-dha',
    salesmanId: 'sm-ali', salesmanName: 'Ali Raza',
    prevDebit: 0, status: 'saved',
    items: [{ sNo: 1, productId: 'prod-chicken', productName: 'Live Broiler Chicken',
      packingName: 'Loose', pack: 1, unit: 'kg', qtyPacks: 2500, qtyLoose: 0,
      bonus: 0, price: 270, discPercent: 2, salesTaxPercent: 0,
      lineGross: 1417500, lineDisc: 28350, lineNet: 1389150, lineTax: 0, lineValueIncST: 1389150 }],
    gross: 1417500, disc2Percent: 0, discounts: 28350, invoiceValue: 1389150,
    salesTax: 0, fTax: 0, expense: 0, totalSED: 0, spcDisc: 0,
    netValue: 1389150, totalPayable: 1389150, ttlQty: 2500,
    paidAmount: 500000, remBalance: 889150,
    description: 'Auto-created from Chicken Invoice CI-0001',
    remarks: '', linkedChickenInvoiceId: 'ci-a1',
  };
  await set(col.invoicing('salesInvoices'), 'si-ci-a1', si_ci_a1);

  const si_ci_a2 = {
    saleId: nextSI(), entryDate: daysAgo(18),
    customerId: 'cust-bilal', customerName: 'Bilal & Sons',
    townId: 'town-fsd', sectorId: 'sec-jinn',
    salesmanId: 'sm-ahmed', salesmanName: 'Ahmed Shah',
    prevDebit: 0, status: 'saved',
    items: [{ sNo: 1, productId: 'prod-chicken', productName: 'Live Broiler Chicken',
      packingName: 'Loose', pack: 1, unit: 'kg', qtyPacks: 2380, qtyLoose: 0,
      bonus: 0, price: 268, discPercent: 0, salesTaxPercent: 0,
      lineGross: 1339464, lineDisc: 0, lineNet: 1339464, lineTax: 0, lineValueIncST: 1339464 }],
    gross: 1339464, disc2Percent: 0, discounts: 0, invoiceValue: 1339464,
    salesTax: 0, fTax: 0, expense: 0, totalSED: 0, spcDisc: 0,
    netValue: 1339464, totalPayable: 1339464, ttlQty: 2380,
    paidAmount: 1339464, remBalance: 0,
    description: 'Auto-created from Chicken Invoice CI-0002',
    remarks: '', linkedChickenInvoiceId: 'ci-a2',
  };
  await set(col.invoicing('salesInvoices'), 'si-ci-a2', si_ci_a2);

  const si_ci_b1 = {
    saleId: nextSI(), entryDate: daysAgo(5),
    customerId: 'cust-nadeem', customerName: 'Nadeem Farms',
    townId: 'town-mul', sectorId: 'sec-kha',
    salesmanId: 'sm-usman', salesmanName: 'Usman Khan',
    prevDebit: 0, status: 'saved',
    items: [{ sNo: 1, productId: 'prod-chicken', productName: 'Live Broiler Chicken',
      packingName: 'Loose', pack: 1, unit: 'kg', qtyPacks: 2500, qtyLoose: 0,
      bonus: 0, price: 265, discPercent: 0, salesTaxPercent: 0,
      lineGross: 1325000, lineDisc: 0, lineNet: 1325000, lineTax: 0, lineValueIncST: 1325000 }],
    gross: 1325000, disc2Percent: 0, discounts: 0, invoiceValue: 1325000,
    salesTax: 0, fTax: 0, expense: 0, totalSED: 0, spcDisc: 0,
    netValue: 1325000, totalPayable: 1325000, ttlQty: 2500,
    paidAmount: 0, remBalance: 1325000,
    description: 'Auto-created from Chicken Invoice CI-0003',
    remarks: '', linkedChickenInvoiceId: 'ci-b1',
  };
  await set(col.invoicing('salesInvoices'), 'si-ci-b1', si_ci_b1);

  // ── Standalone sales invoices (feed sales) ────────────────────────────────
  const si_feed_1 = {
    saleId: nextSI(), entryDate: daysAgo(12),
    customerId: 'cust-farhan', customerName: 'Farhan Traders',
    townId: 'town-lhr', sectorId: 'sec-gulb',
    salesmanId: 'sm-ali', salesmanName: 'Ali Raza',
    prevDebit: 0, status: 'saved',
    items: [
      { sNo: 1, productId: 'prod-feed-s', productName: 'Starter Feed 50kg', packingName: 'Bag-50',
        pack: 50, unit: 'kg', qtyPacks: 20, qtyLoose: 0, bonus: 0, price: 3400,
        discPercent: 0, salesTaxPercent: 5,
        lineGross: 68000, lineDisc: 0, lineNet: 68000, lineTax: 3400, lineValueIncST: 71400 },
      { sNo: 2, productId: 'prod-feed-g', productName: 'Grower Feed 50kg', packingName: 'Bag-50',
        pack: 50, unit: 'kg', qtyPacks: 10, qtyLoose: 0, bonus: 2, price: 3200,
        discPercent: 0, salesTaxPercent: 5,
        lineGross: 32000, lineDisc: 0, lineNet: 32000, lineTax: 1600, lineValueIncST: 33600 },
    ],
    gross: 100000, disc2Percent: 0, discounts: 0, invoiceValue: 100000,
    salesTax: 5000, fTax: 0, expense: 0, totalSED: 0, spcDisc: 0,
    netValue: 105000, totalPayable: 105000, ttlQty: 30,
    paidAmount: 50000, remBalance: 55000,
    description: 'Feed sale to Farhan Traders', remarks: '', linkedChickenInvoiceId: '',
  };
  await set(col.invoicing('salesInvoices'), 'si-feed-1', si_feed_1);

  const si_feed_2 = {
    saleId: nextSI(), entryDate: daysAgo(8),
    customerId: 'cust-kashif', customerName: 'Kashif Brothers',
    townId: 'town-mul', sectorId: 'sec-kha',
    salesmanId: 'sm-usman', salesmanName: 'Usman Khan',
    prevDebit: 0, status: 'saved',
    items: [
      { sNo: 1, productId: 'prod-feed-f', productName: 'Finisher Feed 50kg', packingName: 'Bag-50',
        pack: 50, unit: 'kg', qtyPacks: 15, qtyLoose: 0, bonus: 0, price: 3000,
        discPercent: 5, salesTaxPercent: 5,
        lineGross: 45000, lineDisc: 2250, lineNet: 42750, lineTax: 2137.5, lineValueIncST: 44887.5 },
    ],
    gross: 45000, disc2Percent: 0, discounts: 2250, invoiceValue: 42750,
    salesTax: 2137.5, fTax: 0, expense: 0, totalSED: 0, spcDisc: 0,
    netValue: 44887.5, totalPayable: 44887.5, ttlQty: 15,
    paidAmount: 44887.5, remBalance: 0,
    description: 'Feed sale — Kashif Brothers', remarks: '', linkedChickenInvoiceId: '',
  };
  await set(col.invoicing('salesInvoices'), 'si-feed-2', si_feed_2);
  console.log('  ✓ sales invoices (5 total: 3 chicken-linked, 2 standalone)');

  // ── Purchase invoices (feed procurement) ─────────────────────────────────
  const pi_1 = {
    purchaseId: nextPI(), entryDate: daysAgo(40),
    vendorId: 'vnd-pak-feed', vendorName: 'Pak Feed Industries',
    status: 'saved',
    items: [
      { sNo: 1, productId: 'prod-feed-s', productName: 'Starter Feed 50kg',
        pack: 50, qtyPacks: 100, qtyLoose: 0, costPrice: 3200,
        lineGross: 320000, lineDisc: 0, lineNet: 320000 },
      { sNo: 2, productId: 'prod-feed-g', productName: 'Grower Feed 50kg',
        pack: 50, qtyPacks: 200, qtyLoose: 0, costPrice: 3000,
        lineGross: 600000, lineDisc: 0, lineNet: 600000 },
    ],
    gross: 920000, discounts: 0, invoiceValue: 920000,
    salesTax: 0, netValue: 920000, totalPayable: 920000,
    paidAmount: 460000, remBalance: 460000,
    description: 'Feed procurement — Batch Alpha & Beta', remarks: '',
  };
  await set(col.invoicing('purchaseInvoices'), 'pi-feed-1', pi_1);

  const pi_2 = {
    purchaseId: nextPI(), entryDate: daysAgo(15),
    vendorId: 'vnd-pak-feed', vendorName: 'Pak Feed Industries',
    status: 'saved',
    items: [
      { sNo: 1, productId: 'prod-feed-f', productName: 'Finisher Feed 50kg',
        pack: 50, qtyPacks: 150, qtyLoose: 0, costPrice: 2800,
        lineGross: 420000, lineDisc: 0, lineNet: 420000 },
    ],
    gross: 420000, discounts: 0, invoiceValue: 420000,
    salesTax: 0, netValue: 420000, totalPayable: 420000,
    paidAmount: 420000, remBalance: 0,
    description: 'Finisher feed for Flock A & B closeout', remarks: '',
  };
  await set(col.invoicing('purchaseInvoices'), 'pi-feed-2', pi_2);
  console.log('  ✓ purchase invoices (2)');

  // ── Recovery invoices ─────────────────────────────────────────────────────
  const rec_1 = {
    recoveryId: nextREC(), date: daysAgo(10),
    salesmanId: 'sm-ali', salesmanName: 'Ali Raza',
    customerRecoveries: [
      { customerId: 'cust-rehman', customerName: 'Rehman Poultry',
        saleId: 'si-ci-a1', saleValue: 1389150,
        adjusted: 0, receivable: 889150, received: 300000, discount: 0,
        finalCredit: 300000, narration: 'Partial recovery visit 1' },
      { customerId: 'cust-farhan', customerName: 'Farhan Traders',
        saleId: 'si-feed-1', saleValue: 105000,
        adjusted: 0, receivable: 55000, received: 30000, discount: 0,
        finalCredit: 30000, narration: 'First installment' },
    ],
    totalNoInvoices: 2, amount: 330000, discount: 0,
  };
  await set(col.invoicing('recoveryInvoices'), 'rec-1', rec_1);

  const rec_2 = {
    recoveryId: nextREC(), date: daysAgo(3),
    salesmanId: 'sm-usman', salesmanName: 'Usman Khan',
    customerRecoveries: [
      { customerId: 'cust-nadeem', customerName: 'Nadeem Farms',
        saleId: 'si-ci-b1', saleValue: 1325000,
        adjusted: 0, receivable: 1325000, received: 500000, discount: 10000,
        finalCredit: 510000, narration: 'Partial recovery + Rs 10,000 goodwill discount' },
    ],
    totalNoInvoices: 1, amount: 500000, discount: 10000,
  };
  await set(col.invoicing('recoveryInvoices'), 'rec-2', rec_2);
  console.log('  ✓ recovery invoices (2)');

  // ── Cash vouchers (journal entries for expenses) ──────────────────────────
  const cv_wages = {
    voucherNo: nextCV(), voucherDate: daysAgo(30), voucherType: 'debit',
    lines: [
      { accountId: 'acc-wages', accountCode: '5100', accountName: 'Wages & Salaries', debit: 80000, credit: 0, narration: 'Monthly wages — 3 workers' },
      { accountId: 'acc-cash',  accountCode: '1001', accountName: 'Cash in Hand',     debit: 0, credit: 80000, narration: 'Cash paid' },
    ],
    totals: { debit: 80000, credit: 80000 }, status: 'saved', isConfirmed: true,
  };
  await set(col.invoicing('cashVouchers'), 'cv-wages', cv_wages);

  const cv_util = {
    voucherNo: nextCV(), voucherDate: daysAgo(25), voucherType: 'debit',
    lines: [
      { accountId: 'acc-util', accountCode: '5200', accountName: 'Utilities — Electric', debit: 35000, credit: 0, narration: 'Monthly electricity — 3 sheds' },
      { accountId: 'acc-cash', accountCode: '1001', accountName: 'Cash in Hand',          debit: 0, credit: 35000, narration: 'Cash paid' },
    ],
    totals: { debit: 35000, credit: 35000 }, status: 'saved', isConfirmed: true,
  };
  await set(col.invoicing('cashVouchers'), 'cv-util', cv_util);

  const cv_transport = {
    voucherNo: nextCV(), voucherDate: daysAgo(19), voucherType: 'debit',
    lines: [
      { accountId: 'acc-transport', accountCode: '5300', accountName: 'Transport Expenses', debit: 15000, credit: 0, narration: 'Truck hire — chicken sale Flock A' },
      { accountId: 'acc-cash',      accountCode: '1001', accountName: 'Cash in Hand',       debit: 0, credit: 15000, narration: 'Cash paid to driver' },
    ],
    totals: { debit: 15000, credit: 15000 }, status: 'saved', isConfirmed: true,
  };
  await set(col.invoicing('cashVouchers'), 'cv-transport', cv_transport);
  console.log('  ✓ cash vouchers (3)');

  // ── Bank deposit ──────────────────────────────────────────────────────────
  const bd_1 = {
    depositId: nextBD(), depositDate: daysAgo(16), depositType: 'cash',
    bankAccountId: 'acc-bank', bankAccountName: 'Bank — HBL Current',
    depositSlipNo: 'SLP-20241105-001',
    fromAccountId: 'acc-cash', fromAccountName: 'Cash in Hand',
    amount: 200000, narration: 'Cash deposit from Rehman Poultry recovery',
    status: 'confirmed', confirmedAt: daysAgo(16),
  };
  await set(col.invoicing('bankDeposits'), 'bd-1', bd_1);
  console.log('  ✓ bank deposit (1)');

  // ── Bank cheque ───────────────────────────────────────────────────────────
  const bc_1 = {
    chequeId: nextBC(), chequeNo: 'HBL-004521', chequeDate: daysAgo(14),
    bankAccountId: 'acc-bank', bankAcNo: '1002', bankAccountName: 'Bank — HBL Current',
    payeeType: 'vendor', vendorId: 'vnd-pak-feed', payeeAccountId: '',
    payeeName: 'Pak Feed Industries',
    amount: 460000, narration: 'Payment against PI-0001 — feed purchase',
    isPostDated: false, status: 'issued',
  };
  await set(col.invoicing('bankCheques'), 'bc-1', bc_1);
  console.log('  ✓ bank cheque (1)');

  // ─────────────────────────────────────────────────────────────────────────
  // LEDGER ENTRIES (double-entry for every financial event above)
  // ─────────────────────────────────────────────────────────────────────────

  const ledgerEntries = [
    // CI-0001 (Rehman, 1,389,150 total, 500,000 advance)
    ['le-ci-a1-ar',     { entryNo: 'CI-0001-AR',     entryDate: daysAgo(20), accountId: 'acc-ar',    entryType: 'debit',  amount: 1389150, description: 'AR — CI-0001 Rehman Poultry',   referenceType: 'other', referenceId: 'si-ci-a1', referenceNo: 'CI-0001', tags: ['auto-post','chicken-invoice'], isReconciled: false }],
    ['le-ci-a1-rev',    { entryNo: 'CI-0001-SR',     entryDate: daysAgo(20), accountId: 'acc-rev',   entryType: 'credit', amount: 1389150, description: 'Revenue — CI-0001',             referenceType: 'other', referenceId: 'si-ci-a1', referenceNo: 'CI-0001', tags: ['auto-post','chicken-invoice'], isReconciled: false }],
    ['le-ci-a1-cash',   { entryNo: 'CI-0001-CASH',   entryDate: daysAgo(20), accountId: 'acc-cash',  entryType: 'debit',  amount: 500000,  description: 'Advance cash — CI-0001',       referenceType: 'other', referenceId: 'si-ci-a1', referenceNo: 'CI-0001', tags: ['auto-post','chicken-invoice','advance'], isReconciled: false }],
    ['le-ci-a1-ar-adv', { entryNo: 'CI-0001-AR-ADV', entryDate: daysAgo(20), accountId: 'acc-ar',    entryType: 'credit', amount: 500000,  description: 'AR reduced by advance — CI-0001', referenceType: 'other', referenceId: 'si-ci-a1', referenceNo: 'CI-0001', tags: ['auto-post','chicken-invoice','advance'], isReconciled: false }],

    // CI-0002 (Bilal, 1,339,464 fully paid)
    ['le-ci-a2-ar',     { entryNo: 'CI-0002-AR',     entryDate: daysAgo(18), accountId: 'acc-ar',    entryType: 'debit',  amount: 1339464, description: 'AR — CI-0002 Bilal & Sons',    referenceType: 'other', referenceId: 'si-ci-a2', referenceNo: 'CI-0002', tags: ['auto-post','chicken-invoice'], isReconciled: true  }],
    ['le-ci-a2-rev',    { entryNo: 'CI-0002-SR',     entryDate: daysAgo(18), accountId: 'acc-rev',   entryType: 'credit', amount: 1339464, description: 'Revenue — CI-0002',             referenceType: 'other', referenceId: 'si-ci-a2', referenceNo: 'CI-0002', tags: ['auto-post','chicken-invoice'], isReconciled: true  }],
    ['le-ci-a2-cash',   { entryNo: 'CI-0002-CASH',   entryDate: daysAgo(18), accountId: 'acc-cash',  entryType: 'debit',  amount: 1339464, description: 'Full cash received — CI-0002', referenceType: 'other', referenceId: 'si-ci-a2', referenceNo: 'CI-0002', tags: ['auto-post','chicken-invoice','advance'], isReconciled: true  }],
    ['le-ci-a2-ar-adv', { entryNo: 'CI-0002-AR-ADV', entryDate: daysAgo(18), accountId: 'acc-ar',    entryType: 'credit', amount: 1339464, description: 'AR cleared — CI-0002',         referenceType: 'other', referenceId: 'si-ci-a2', referenceNo: 'CI-0002', tags: ['auto-post','chicken-invoice','advance'], isReconciled: true  }],

    // CI-0003 (Nadeem, 1,325,000 unpaid)
    ['le-ci-b1-ar',     { entryNo: 'CI-0003-AR',     entryDate: daysAgo(5),  accountId: 'acc-ar',    entryType: 'debit',  amount: 1325000, description: 'AR — CI-0003 Nadeem Farms',    referenceType: 'other', referenceId: 'si-ci-b1', referenceNo: 'CI-0003', tags: ['auto-post','chicken-invoice'], isReconciled: false }],
    ['le-ci-b1-rev',    { entryNo: 'CI-0003-SR',     entryDate: daysAgo(5),  accountId: 'acc-rev',   entryType: 'credit', amount: 1325000, description: 'Revenue — CI-0003',             referenceType: 'other', referenceId: 'si-ci-b1', referenceNo: 'CI-0003', tags: ['auto-post','chicken-invoice'], isReconciled: false }],

    // Cash voucher — wages
    ['le-cv-wages-dr',  { entryNo: 'JV-0001-DR', entryDate: daysAgo(30), accountId: 'acc-wages', entryType: 'debit',  amount: 80000, description: 'Wages — 3 workers',       referenceType: 'other', referenceId: 'cv-wages', referenceNo: 'JV-0001', tags: ['voucher'], isReconciled: false }],
    ['le-cv-wages-cr',  { entryNo: 'JV-0001-CR', entryDate: daysAgo(30), accountId: 'acc-cash',  entryType: 'credit', amount: 80000, description: 'Cash paid — wages',       referenceType: 'other', referenceId: 'cv-wages', referenceNo: 'JV-0001', tags: ['voucher'], isReconciled: false }],

    // Cash voucher — electricity
    ['le-cv-util-dr',   { entryNo: 'JV-0002-DR', entryDate: daysAgo(25), accountId: 'acc-util',  entryType: 'debit',  amount: 35000, description: 'Electricity bill',         referenceType: 'other', referenceId: 'cv-util',  referenceNo: 'JV-0002', tags: ['voucher'], isReconciled: false }],
    ['le-cv-util-cr',   { entryNo: 'JV-0002-CR', entryDate: daysAgo(25), accountId: 'acc-cash',  entryType: 'credit', amount: 35000, description: 'Cash paid — electricity',  referenceType: 'other', referenceId: 'cv-util',  referenceNo: 'JV-0002', tags: ['voucher'], isReconciled: false }],

    // Cash voucher — transport
    ['le-cv-trans-dr',  { entryNo: 'JV-0003-DR', entryDate: daysAgo(19), accountId: 'acc-transport', entryType: 'debit',  amount: 15000, description: 'Transport — Flock A sale', referenceType: 'other', referenceId: 'cv-transport', referenceNo: 'JV-0003', tags: ['voucher'], isReconciled: false }],
    ['le-cv-trans-cr',  { entryNo: 'JV-0003-CR', entryDate: daysAgo(19), accountId: 'acc-cash',      entryType: 'credit', amount: 15000, description: 'Cash paid — transport',    referenceType: 'other', referenceId: 'cv-transport', referenceNo: 'JV-0003', tags: ['voucher'], isReconciled: false }],

    // Bank deposit
    ['le-bd-1-cash',    { entryNo: 'BD-0001-CR', entryDate: daysAgo(16), accountId: 'acc-cash', entryType: 'credit', amount: 200000, description: 'Cash deposited to bank', referenceType: 'other', referenceId: 'bd-1', referenceNo: 'BD-0001', tags: ['bank-deposit'], isReconciled: false }],
    ['le-bd-1-bank',    { entryNo: 'BD-0001-DR', entryDate: daysAgo(16), accountId: 'acc-bank', entryType: 'debit',  amount: 200000, description: 'Bank — cash deposit',    referenceType: 'other', referenceId: 'bd-1', referenceNo: 'BD-0001', tags: ['bank-deposit'], isReconciled: false }],

    // Cheque payment to vendor
    ['le-bc-1-ap',      { entryNo: 'CHQ-0001-DR', entryDate: daysAgo(14), accountId: 'acc-ap',   entryType: 'debit',  amount: 460000, description: 'Cheque — Pak Feed PI-0001', referenceType: 'other', referenceId: 'bc-1', referenceNo: 'CHQ-0001', tags: ['bank-cheque'], isReconciled: false }],
    ['le-bc-1-bank',    { entryNo: 'CHQ-0001-CR', entryDate: daysAgo(14), accountId: 'acc-bank', entryType: 'credit', amount: 460000, description: 'Bank — cheque issued',      referenceType: 'other', referenceId: 'bc-1', referenceNo: 'CHQ-0001', tags: ['bank-cheque'], isReconciled: false }],
  ];

  await batchWrite(col.accounts('ledgerEntries'), ledgerEntries);
  console.log(`  ✓ ledger entries (${ledgerEntries.length})`);

  // ── Purchase orders ───────────────────────────────────────────────────────
  const po1Items = [
    { sNo:1, productId:'prod-feed-s', productName:'Starter Feed 50kg', packingName:'Bag-50', pack:50, unit:'kg', qtyPacks:50, qtyLoose:0, bonus:0, price:3200, discPercent:0, salesTaxPercent:5, lineGross:160000, lineDisc:0, lineNet:160000, lineTax:8000, lineValueIncST:168000 },
    { sNo:2, productId:'prod-newcas',  productName:'Newcastle Vaccine',  packingName:'Loose',  pack:1,  unit:'pcs',qtyPacks:100,qtyLoose:0, bonus:0, price:180,  discPercent:0, salesTaxPercent:0, lineGross:18000,  lineDisc:0, lineNet:18000,  lineTax:0,    lineValueIncST:18000  },
  ];
  await set(col.invoicing('purchaseOrders'),'po-1',{
    orderId:nextPO(), entryDate:daysAgo(45), vendorId:'vnd-pak-feed', vendorName:'Pak Feed Industries',
    city:'Multan', status:'saved',
    items:po1Items,
    gross:178000, disc2Percent:0, discounts:0, invoiceValue:178000, salesTax:8000,
    fTaxPercent:0, furtherTaxValue:0, netValue:186000,
  });
  const po2Items = [
    { sNo:1, productId:'prod-feed-g', productName:'Grower Feed 50kg',   packingName:'Bag-50', pack:50, unit:'kg', qtyPacks:80, qtyLoose:0, bonus:0, price:3000, discPercent:2, salesTaxPercent:5, lineGross:240000, lineDisc:4800, lineNet:235200, lineTax:11760, lineValueIncST:246960 },
    { sNo:2, productId:'prod-gumboro', productName:'Gumboro Vaccine',   packingName:'Loose',  pack:1,  unit:'pcs',qtyPacks:80, qtyLoose:0, bonus:0, price:200,  discPercent:0, salesTaxPercent:0, lineGross:16000,  lineDisc:0,   lineNet:16000,  lineTax:0,    lineValueIncST:16000  },
  ];
  await set(col.invoicing('purchaseOrders'),'po-2',{
    orderId:nextPO(), entryDate:daysAgo(32), vendorId:'vnd-goldenfarm', vendorName:'Golden Farm Ltd',
    city:'Faisalabad', status:'saved',
    items:po2Items,
    gross:256000, disc2Percent:0, discounts:4800, invoiceValue:251200, salesTax:11760,
    fTaxPercent:0, furtherTaxValue:0, netValue:262960,
  });
  console.log('  ✓ purchase orders (2)');

  // ── Send orders (linked to purchase orders) ───────────────────────────────
  await set(col.invoicing('sendOrders'),'so-1',{
    sendOrderId:nextSO(), orderId:'po-1',
    vendorId:'vnd-pak-feed', vendorName:'Pak Feed Industries',
    draftNo:'HBL-DRAFT-0023', draftDate:daysAgo(44), draftAmount:186000,
    bankAccountId:'acc-bank', bankAcNo:'1002', bankAccountName:'Bank — HBL Current',
    description:'Send order against PO-0001 — Starter Feed + Newcastle Vaccine',
    includeAllProductsWhenPrinting:false,
    items:po1Items, totalOrderValue:186000,
  });
  console.log('  ✓ send orders (1)');

  // ── Sales returns ─────────────────────────────────────────────────────────
  // With invoice — return 5 bags of starter feed from Farhan Traders
  await set(col.invoicing('salesReturns'),'sr-1',{
    returnId:nextSR(), returnType:'with_invoice',
    returnDate:daysAgo(10), saleId:'si-feed-1', saleDate:daysAgo(12),
    isFullReturn:false,
    customerId:'cust-farhan', customerName:'Farhan Traders',
    townId:'town-lhr', sectorId:'sec-gulb',
    salesmanId:'sm-ali', salesmanName:'Ali Raza',
    toMainStore:true,
    items:[{
      sNo:1, productId:'prod-feed-s', productName:'Starter Feed 50kg', packingName:'Bag-50',
      pack:50, price:3400, discPercent:0, salesTaxPercent:5,
      saleQtyPacks:20, saleQtyLoose:0, saleBns:0,
      prevReturnedQtyPacks:0, prevReturnedQtyLoose:0,
      currentReturnQtyPacks:5, currentReturnQtyLoose:0,
      lineGross:17000, lineDisc:0, lineNet:17000, lineTax:850, lineValueIncST:17850,
    }],
    disc2Percent:0, invoiceValue:17000, salesTax:850,
    fTaxPercent:0, furtherTaxValue:0, sed:0, specialDiscount:0,
    netValue:17850, prevCredit:0, totalPayable:17850, paidAmount:17850, remBalance:0,
    description:'Return of 5 bags starter feed — quality issue',
  });
  // Without invoice — walk-in return
  await set(col.invoicing('salesReturns'),'sr-2',{
    returnId:nextSR(), returnType:'without_invoice',
    returnDate:daysAgo(6), saleId:'', saleDate:'',
    isFullReturn:false,
    customerId:'cust-tariq', customerName:'Tariq Poultry',
    townId:'town-fsd', sectorId:'sec-chenab',
    salesmanId:'sm-ahmed', salesmanName:'Ahmed Shah',
    toMainStore:true,
    items:[{
      sNo:1, productId:'prod-amox', productName:'Amoxicillin 100g', packingName:'Loose',
      pack:1, qtyPacks:10, qtyLoose:0, price:550, discPercent:0, salesTaxPercent:0,
      lineGross:5500, lineDisc:0, lineNet:5500, lineTax:0, lineValueIncST:5500,
    }],
    disc2Percent:0, invoiceValue:5500, salesTax:0,
    fTaxPercent:0, furtherTaxValue:0, sed:0, specialDiscount:0,
    netValue:5500, prevCredit:0, totalPayable:5500, paidAmount:5500, remBalance:0,
    description:'Walk-in return — 10 pcs Amoxicillin, damaged packaging',
  });
  console.log('  ✓ sales returns (2: with_invoice + without_invoice)');

  // ── Purchase returns ──────────────────────────────────────────────────────
  await set(col.invoicing('purchaseReturns'),'pr-1',{
    returnId:nextPR(), returnType:'with_invoice',
    returnDate:daysAgo(13), purchaseInvoiceId:'pi-feed-1',
    vendorId:'vnd-pak-feed', vendorName:'Pak Feed Industries',
    items:[{
      sNo:1, productId:'prod-feed-s', productName:'Starter Feed 50kg', packingName:'Bag-50',
      pack:50, unit:'kg', qtyPacks:5, qtyLoose:0, bonus:0, price:3200, discPercent:0, salesTaxPercent:0,
      lineGross:16000, lineDisc:0, lineNet:16000, lineTax:0, lineValueIncST:16000,
    }],
    gross:16000, disc2Percent:0, discounts:0, invoiceValue:16000, salesTax:0,
    fTaxPercent:0, furtherTaxValue:0, netValue:16000,
  });
  console.log('  ✓ purchase returns (1)');

  // ── Stock issues (to salesmen) ────────────────────────────────────────────
  await set(col.invoicing('stockIssues'),'sti-1',{
    issueId:nextSTI(), issueType:'issue', date:daysAgo(11),
    salesmanId:'sm-ali', salesmanName:'Ali Raza',
    originalIssueId:'', returnAll:false,
    items:[
      { productId:'prod-feed-s', productName:'Starter Feed 50kg', packingId:'pk-50', packingName:'Bag-50', pack:50, qtyPacks:10, qtyLoose:0, cost:3200, value:320000 },
      { productId:'prod-newcas', productName:'Newcastle Vaccine',  packingId:'pk-1',  packingName:'Loose',  pack:1,  qtyPacks:20, qtyLoose:0, cost:180,  value:3600  },
    ],
    netValue:323600,
  });
  await set(col.invoicing('stockIssues'),'sti-2',{
    issueId:nextSTI(), issueType:'issue', date:daysAgo(9),
    salesmanId:'sm-ahmed', salesmanName:'Ahmed Shah',
    originalIssueId:'', returnAll:false,
    items:[
      { productId:'prod-feed-g', productName:'Grower Feed 50kg', packingId:'pk-50', packingName:'Bag-50', pack:50, qtyPacks:15, qtyLoose:0, cost:3000, value:450000 },
      { productId:'prod-amox',   productName:'Amoxicillin 100g', packingId:'pk-1',  packingName:'Loose',  pack:1,  qtyPacks:30, qtyLoose:0, cost:450,  value:13500 },
    ],
    netValue:463500,
  });
  // Stock return from Ali — 2 bags returned
  await set(col.invoicing('stockIssues'),'sti-3',{
    issueId:`STI-${String(++_stiSeq).padStart(4,'0')}`, issueType:'return', date:daysAgo(7),
    salesmanId:'sm-ali', salesmanName:'Ali Raza',
    originalIssueId:'sti-1', returnAll:false,
    items:[
      { productId:'prod-feed-s', productName:'Starter Feed 50kg', packingId:'pk-50', packingName:'Bag-50', pack:50, qtyPacks:2, qtyLoose:0, cost:3200, value:64000 },
    ],
    netValue:64000,
  });
  console.log('  ✓ stock issues (2 issues, 1 return)');

  // ── Stock wastages ────────────────────────────────────────────────────────
  await set(col.invoicing('stockWastages'),'was-1',{
    wastageId:nextWAS(), date:daysAgo(22),
    items:[{
      productId:'prod-feed-g', productName:'Grower Feed 50kg', packingName:'Bag-50', pack:50,
      expQtyPacks:2, expQtyLoose:0, damQtyPacks:1, damQtyLoose:0, cost:3000,
      value:(2*50 + 0 + 1*50 + 0)*3000,
    }],
    netValue:450000,
  });
  console.log('  ✓ stock wastages (1)');

  // ── Stock expiries ────────────────────────────────────────────────────────
  await set(col.invoicing('stockExpiries'),'exp-1',{
    expiryId:nextEXP(), date:daysAgo(18),
    items:[
      { productId:'prod-newcas', productName:'Newcastle Vaccine', packingName:'Loose', pack:1, expQtyPacks:5, expQtyLoose:0, damQtyPacks:0, damQtyLoose:0, cost:180, value:5*180 },
      { productId:'prod-amox',   productName:'Amoxicillin 100g', packingName:'Loose', pack:1, expQtyPacks:3, expQtyLoose:0, damQtyPacks:0, damQtyLoose:0, cost:450, value:3*450 },
    ],
    netValue:5*180 + 3*450,
  });
  console.log('  ✓ stock expiries (1)');

  // ── Expiry claims ─────────────────────────────────────────────────────────
  await set(col.invoicing('expiryClaims'),'clm-1',{
    claimId:nextCLM(), date:daysAgo(15),
    vendorId:'vnd-pak-feed', vendorName:'Pak Feed Industries',
    items:[{
      sNo:1, productId:'prod-newcas', productName:'Newcastle Vaccine', packingName:'Loose', pack:1,
      expQtyPacks:5, expQtyLoose:0, damQtyPacks:0, damQtyLoose:0, costPerUnit:180, price:180,
      value:5*180,
    }],
    replyItems:[{
      sNo:1, productId:'prod-newcas', productName:'Newcastle Vaccine', packingName:'Loose', pack:1,
      qtyPacks:5, qtyLoose:0, price:180, value:5*180,
    }],
    netValue:5*180, claimStatus:'approved',
    description:'Expired Newcastle Vaccine — 5 vials returned to Pak Feed',
  });
  console.log('  ✓ expiry claims (1)');

  // ── Recovery invoice wise (multi-customer, invoice-by-invoice) ────────────
  await set(col.invoicing('recoveryInvoicesWise'),'riw-1',{
    recoveryId:nextRIW(), recoveryDate:daysAgo(8),
    salesmanId:'sm-ali', salesmanName:'Ali Raza',
    townId:'town-lhr', sectorId:'', showSalesmanInNarration:true,
    customerRecoveries:[
      { customerId:'cust-rehman', customerName:'Rehman Poultry', sector:'DHA',
        invoices:[
          { saleId:'si-ci-a1', date:daysAgo(20), invoiceValue:1389150, adjusted:0, receivable:589150, received:200000, discount:0, balance:389150, narration:'2nd installment' },
        ]},
      { customerId:'cust-farhan', customerName:'Farhan Traders', sector:'Gulberg',
        invoices:[
          { saleId:'si-feed-1', date:daysAgo(12), invoiceValue:105000, adjusted:17850, receivable:25000, received:25000, discount:0, balance:0, narration:'Full clearance after return' },
        ]},
    ],
    netReceived:225000, discount:0, grossRecoveries:225000,
  });
  console.log('  ✓ recovery invoice wise (1)');

  // ── Recovery receivable wise (bulk by customer total) ─────────────────────
  await set(col.invoicing('recoveryReceivableWise'),'rrw-1',{
    recoveryId:nextRRW(), recoveryDate:daysAgo(4),
    salesmanId:'sm-ahmed', salesmanName:'Ahmed Shah',
    townId:'town-fsd', sectorId:'', showSalesmanInNarration:false,
    customerRecoveries:[
      { customerId:'cust-bilal', customerName:'Bilal & Sons', sector:'Jinnah Colony',
        receivable:40000, received:40000, discount:0, balance:0, narration:'Opening balance cleared' },
      { customerId:'cust-tariq', customerName:'Tariq Poultry', sector:'Chenab Nagar',
        receivable:5500,  received:5000,  discount:500, balance:0, narration:'Rs 500 goodwill discount' },
    ],
    netReceived:45000, discount:500, grossRecoveries:45500,
  });
  console.log('  ✓ recovery receivable wise (1)');

  // ── Salesman cash reconciliation ──────────────────────────────────────────
  await set(col.invoicing('salesmanCashReconciliations'),'scr-1',{
    reconciliationId:nextSCR(), date:daysAgo(3),
    salesmanId:'sm-ali', salesmanName:'Ali Raza',
    openingBalance:50000,
    recoveryEntries:[
      { recoveryId:'rec-1', recoveryDate:daysAgo(10), cashReceived:330000, discountGiven:0, narration:'Recovery visit REC-0001' },
    ],
    expenseEntries:[
      { description:'Fuel & travel',      amount:3500 },
      { description:'Customer lunch',     amount:1200 },
    ],
    totalCashReceived:330000, totalDiscount:0,
    totalExpenses:4700, cashDeposited:200000,
    closingBalance:50000 + 330000 - 4700 - 200000,
    status:'saved',
  });
  await set(col.invoicing('salesmanCashReconciliations'),'scr-2',{
    reconciliationId:nextSCR(), date:daysAgo(2),
    salesmanId:'sm-usman', salesmanName:'Usman Khan',
    openingBalance:0,
    recoveryEntries:[
      { recoveryId:'rec-2', recoveryDate:daysAgo(3), cashReceived:500000, discountGiven:10000, narration:'Nadeem Farms partial' },
    ],
    expenseEntries:[
      { description:'Truck hire', amount:5000 },
    ],
    totalCashReceived:500000, totalDiscount:10000,
    totalExpenses:5000, cashDeposited:490000,
    closingBalance:0 + 500000 - 5000 - 490000,
    status:'saved',
  });
  console.log('  ✓ salesman cash reconciliations (2)');

  // ── Payment promises ──────────────────────────────────────────────────────
  await set(col.invoicing('paymentPromises'),'pp-1',{
    promiseId:nextPP(), promiseType:'recovery',
    entryDate:daysAgo(7), promiseDate:daysAgo(2),
    customerId:'cust-nadeem', customerName:'Nadeem Farms',
    vendorId:'', vendorName:'',
    salesmanId:'sm-usman', salesmanName:'Usman Khan',
    chequeNo:'MCB-0091823', bankName:'MCB Bank',
    amount:815000, narration:'Post-dated cheque for SI-0003 balance',
    linkedSaleIds:['si-ci-b1'], linkedPurchaseIds:[],
    status:'pending', processedDate:'',
  });
  await set(col.invoicing('paymentPromises'),'pp-2',{
    promiseId:nextPP(), promiseType:'payment',
    entryDate:daysAgo(5), promiseDate:daysAgo(1),
    customerId:'', customerName:'',
    vendorId:'vnd-pak-feed', vendorName:'Pak Feed Industries',
    salesmanId:'', salesmanName:'',
    chequeNo:'HBL-004522', bankName:'HBL Bank',
    amount:420000, narration:'Cheque for PI-0002 finisher feed',
    linkedSaleIds:[], linkedPurchaseIds:['pi-feed-2'],
    status:'cleared', processedDate:daysAgo(1),
  });
  console.log('  ✓ payment promises (2: recovery + payment)');

  // ── Set business ID counters so the app continues from correct sequence ───
  await col.counter('salesInvoices').set({ lastNo: _siSeq, updatedAt: now }, { merge: true });
  await col.counter('purchaseInvoices').set({ lastNo: _piSeq, updatedAt: now }, { merge: true });
  await col.counter('recoveryInvoices').set({ lastNo: _recSeq, updatedAt: now }, { merge: true });
  await col.counter('cashVouchers').set({ lastNo: _cvSeq, updatedAt: now }, { merge: true });
  await col.counter('bankDeposits').set({ lastNo: _bdSeq, updatedAt: now }, { merge: true });
  await col.counter('bankCheques').set({ lastNo: _bcSeq, updatedAt: now }, { merge: true });
  await col.counter('purchaseOrders').set({ lastNo: _poSeq, updatedAt: now }, { merge: true });
  await col.counter('sendOrders').set({ lastNo: _soSeq, updatedAt: now }, { merge: true });
  await col.counter('salesReturns').set({ lastNo: _srSeq, updatedAt: now }, { merge: true });
  await col.counter('purchaseReturns').set({ lastNo: _prSeq, updatedAt: now }, { merge: true });
  await col.counter('stockIssues').set({ lastNo: _stiSeq, updatedAt: now }, { merge: true });
  await col.counter('stockWastages').set({ lastNo: _wasSeq, updatedAt: now }, { merge: true });
  await col.counter('stockExpiries').set({ lastNo: _expSeq, updatedAt: now }, { merge: true });
  await col.counter('expiryClaims').set({ lastNo: _clmSeq, updatedAt: now }, { merge: true });
  await col.counter('recoveryInvoicesWise').set({ lastNo: _riwSeq, updatedAt: now }, { merge: true });
  await col.counter('recoveryReceivableWise').set({ lastNo: _rrwSeq, updatedAt: now }, { merge: true });
  await col.counter('salesmanCashReconciliations').set({ lastNo: _scrSeq, updatedAt: now }, { merge: true });
  await col.counter('paymentPromises').set({ lastNo: _ppSeq, updatedAt: now }, { merge: true });
  console.log('  ✓ business ID counters reset');
  console.log('  [Phase 3 complete]\n');
}

// ══════════════════════════════════════════════════════════════════════════════
// PHASE 4 — VALIDATION
// ══════════════════════════════════════════════════════════════════════════════

async function validate() {
  console.log('[4/4] Validating cross-references…');

  // Helper: fetch all docs from a collection for in-memory checks
  async function getAll(colRef) {
    const snap = await colRef.get();
    return Object.fromEntries(snap.docs.map(d => [d.id, d.data()]));
  }

  const [
    accounts, units, packings, prodGroups, prodSubGroups, products,
    towns, sectors, vendors, salesmen, customers,
    flocks, flockFeeds, flockVaccines, chickenInvoices,
    feedSchedules, vaccineSchedules,
    salesInvoices, purchaseInvoices, recoveryInvoices,
    cashVouchers, bankDeposits, bankCheques, ledgerEntries,
    purchaseOrders, sendOrders, salesReturns, purchaseReturns,
    stockIssues, stockWastages, stockExpiries, expiryClaims,
    recoveryInvoicesWise, recoveryReceivableWise,
    salesmanCashReconciliations, paymentPromises,
  ] = await Promise.all([
    getAll(col.settings('accounts')),
    getAll(col.settings('units')),
    getAll(col.settings('packings')),
    getAll(col.settings('productGroups')),
    getAll(col.settings('productSubGroups')),
    getAll(col.settings('products')),
    getAll(col.settings('towns')),
    getAll(col.settings('sectors')),
    getAll(col.settings('vendors')),
    getAll(col.settings('salesmen')),
    getAll(col.settings('customers')),
    getAll(col.poultry('flocks')),
    getAll(col.poultry('flockFeeds')),
    getAll(col.poultry('flockVaccines')),
    getAll(col.poultry('chickenInvoices')),
    getAll(col.poultry('feedSchedules')),
    getAll(col.poultry('vaccineSchedules')),
    getAll(col.invoicing('salesInvoices')),
    getAll(col.invoicing('purchaseInvoices')),
    getAll(col.invoicing('recoveryInvoices')),
    getAll(col.invoicing('cashVouchers')),
    getAll(col.invoicing('bankDeposits')),
    getAll(col.invoicing('bankCheques')),
    getAll(col.accounts('ledgerEntries')),
    getAll(col.invoicing('purchaseOrders')),
    getAll(col.invoicing('sendOrders')),
    getAll(col.invoicing('salesReturns')),
    getAll(col.invoicing('purchaseReturns')),
    getAll(col.invoicing('stockIssues')),
    getAll(col.invoicing('stockWastages')),
    getAll(col.invoicing('stockExpiries')),
    getAll(col.invoicing('expiryClaims')),
    getAll(col.invoicing('recoveryInvoicesWise')),
    getAll(col.invoicing('recoveryReceivableWise')),
    getAll(col.invoicing('salesmanCashReconciliations')),
    getAll(col.invoicing('paymentPromises')),
  ]);

  function has(map, id, label) {
    if (!id || !map[id]) fail(`${label}: "${id}" not found`);
  }
  function eq(a, b, label) {
    if (Math.abs(a - b) > 0.05) fail(`${label}: expected ${b}, got ${a}`);
  }

  // ── Settings internal references ──────────────────────────────────────────
  for (const [id, psg] of Object.entries(prodSubGroups)) {
    has(prodGroups, psg.productGroupId, `productSubGroup[${id}].productGroupId`);
  }
  for (const [id, prod] of Object.entries(products)) {
    has(prodGroups, prod.productGroupId, `product[${id}].productGroupId`);
    if (prod.productSubGroupId) has(prodSubGroups, prod.productSubGroupId, `product[${id}].productSubGroupId`);
    if (prod.unitId)    has(units,    prod.unitId,    `product[${id}].unitId`);
    if (prod.packingId) has(packings, prod.packingId, `product[${id}].packingId`);
  }
  for (const [id, sec] of Object.entries(sectors)) {
    has(towns, sec.townId, `sector[${id}].townId`);
  }
  for (const [id, vnd] of Object.entries(vendors)) {
    if (vnd.townId) has(towns, vnd.townId, `vendor[${id}].townId`);
  }
  for (const [id, sm] of Object.entries(salesmen)) {
    if (sm.townId) has(towns, sm.townId, `salesman[${id}].townId`);
  }
  for (const [id, cust] of Object.entries(customers)) {
    if (cust.townId)     has(towns,    cust.townId,    `customer[${id}].townId`);
    if (cust.sectorId)   has(sectors,  cust.sectorId,  `customer[${id}].sectorId`);
    if (cust.salesmanId) has(salesmen, cust.salesmanId,`customer[${id}].salesmanId`);
    // Sector must belong to customer's town
    if (cust.sectorId && sectors[cust.sectorId] && cust.townId) {
      if (sectors[cust.sectorId].townId !== cust.townId)
        fail(`customer[${id}]: sector "${cust.sectorId}" town mismatch`);
    }
  }
  console.log('  ✓ settings references valid');

  // ── Poultry references ────────────────────────────────────────────────────
  for (const [id, f] of Object.entries(flocks)) {
    if (f.vendorId)          has(vendors,          f.vendorId,          `flock[${id}].vendorId`);
    if (f.feedScheduleId)    has(feedSchedules,    f.feedScheduleId,    `flock[${id}].feedScheduleId`);
    if (f.vaccineScheduleId) has(vaccineSchedules, f.vaccineScheduleId, `flock[${id}].vaccineScheduleId`);
  }
  for (const [id, ff] of Object.entries(flockFeeds)) {
    has(flocks,   ff.flockId,   `flockFeed[${id}].flockId`);
    has(products, ff.productId, `flockFeed[${id}].productId`);
  }
  for (const [id, fv] of Object.entries(flockVaccines)) {
    has(flocks,   fv.flockId,   `flockVaccine[${id}].flockId`);
    has(products, fv.productId, `flockVaccine[${id}].productId`);
  }
  for (const [id, ci] of Object.entries(chickenInvoices)) {
    has(flocks,    ci.flockId,    `chickenInvoice[${id}].flockId`);
    has(customers, ci.customerId, `chickenInvoice[${id}].customerId`);
    if (ci.salesmanId) has(salesmen, ci.salesmanId, `chickenInvoice[${id}].salesmanId`);
    // Linked SI must exist
    if (ci.linkedSalesInvoiceId) {
      has(salesInvoices, ci.linkedSalesInvoiceId, `chickenInvoice[${id}].linkedSalesInvoiceId`);
      // SI must back-reference the CI
      const si = salesInvoices[ci.linkedSalesInvoiceId];
      if (si && si.linkedChickenInvoiceId !== id)
        fail(`chickenInvoice[${id}]: SI "${ci.linkedSalesInvoiceId}" does not back-reference this CI`);
    }
    // Linked ledger entries must all exist
    for (const leId of (ci.linkedLedgerEntryIds || [])) {
      has(ledgerEntries, leId, `chickenInvoice[${id}].linkedLedgerEntryIds["${leId}"]`);
    }
    // Accounting invariant: gross - discountAmount == netAmount
    eq(ci.grossAmount - ci.discountAmount, ci.netAmount, `chickenInvoice[${id}] netAmount`);
    eq(ci.netAmount + ci.taxAmount, ci.totalAmount, `chickenInvoice[${id}] totalAmount`);
    eq(ci.totalAmount - ci.advanceReceived, ci.balanceDue, `chickenInvoice[${id}] balanceDue`);
  }
  console.log('  ✓ poultry references + accounting invariants valid');

  // ── Invoicing references ──────────────────────────────────────────────────
  for (const [id, si] of Object.entries(salesInvoices)) {
    has(customers, si.customerId, `salesInvoice[${id}].customerId`);
    if (si.salesmanId) has(salesmen, si.salesmanId, `salesInvoice[${id}].salesmanId`);
    if (si.linkedChickenInvoiceId) has(chickenInvoices, si.linkedChickenInvoiceId, `salesInvoice[${id}].linkedChickenInvoiceId`);
    for (const item of (si.items || [])) {
      if (item.productId) has(products, item.productId, `salesInvoice[${id}].item[${item.sNo}].productId`);
    }
    // Balance invariant
    eq(si.totalPayable - si.paidAmount, si.remBalance, `salesInvoice[${id}] remBalance`);
  }

  for (const [id, pi] of Object.entries(purchaseInvoices)) {
    has(vendors, pi.vendorId, `purchaseInvoice[${id}].vendorId`);
    for (const item of (pi.items || [])) {
      if (item.productId) has(products, item.productId, `purchaseInvoice[${id}].item[${item.sNo}].productId`);
    }
  }

  for (const [id, ri] of Object.entries(recoveryInvoices)) {
    has(salesmen, ri.salesmanId, `recoveryInvoice[${id}].salesmanId`);
    for (const rc of (ri.customerRecoveries || [])) {
      has(customers,     rc.customerId, `recoveryInvoice[${id}].rc.customerId`);
      has(salesInvoices, rc.saleId,     `recoveryInvoice[${id}].rc.saleId`);
      // finalCredit must = received + discount
      eq(rc.received + rc.discount, rc.finalCredit, `recoveryInvoice[${id}].rc[${rc.saleId}] finalCredit`);
      // received must not exceed saleValue
      if (rc.received + rc.discount > rc.saleValue + 0.05)
        fail(`recoveryInvoice[${id}].rc[${rc.saleId}]: recovery ${rc.received + rc.discount} exceeds saleValue ${rc.saleValue}`);
    }
    // Total amount consistency
    const sumReceived = (ri.customerRecoveries || []).reduce((s, r) => s + (r.received || 0), 0);
    eq(sumReceived, ri.amount, `recoveryInvoice[${id}] amount total`);
  }

  for (const [id, bd] of Object.entries(bankDeposits)) {
    if (bd.bankAccountId) has(accounts, bd.bankAccountId, `bankDeposit[${id}].bankAccountId`);
    if (bd.fromAccountId) has(accounts, bd.fromAccountId, `bankDeposit[${id}].fromAccountId`);
  }
  for (const [id, bc] of Object.entries(bankCheques)) {
    if (bc.bankAccountId) has(accounts, bc.bankAccountId, `bankCheque[${id}].bankAccountId`);
    if (bc.vendorId) has(vendors, bc.vendorId, `bankCheque[${id}].vendorId`);
    if (bc.payeeAccountId) has(accounts, bc.payeeAccountId, `bankCheque[${id}].payeeAccountId`);
  }
  console.log('  ✓ invoicing references + balance invariants valid');

  // ── Ledger double-entry balance check ─────────────────────────────────────
  // Group entries by referenceId and check debits == credits within each transaction group
  const groups = {};
  for (const [, le] of Object.entries(ledgerEntries)) {
    const key = le.referenceId || le.referenceNo || 'ungrouped';
    if (!groups[key]) groups[key] = { debit: 0, credit: 0 };
    if (le.entryType === 'debit')  groups[key].debit  += le.amount || 0;
    else                           groups[key].credit += le.amount || 0;
  }
  for (const [ref, { debit, credit }] of Object.entries(groups)) {
    if (Math.abs(debit - credit) > 0.05)
      fail(`Ledger group "${ref}": unbalanced — debit ${debit.toFixed(2)} ≠ credit ${credit.toFixed(2)}`);
  }
  console.log('  ✓ ledger double-entry balanced across all transaction groups');

  // ── Ledger account references ─────────────────────────────────────────────
  for (const [id, le] of Object.entries(ledgerEntries)) {
    has(accounts, le.accountId, `ledgerEntry[${id}].accountId`);
  }
  console.log('  ✓ ledger account references valid');

  // ── Cash voucher balance check ────────────────────────────────────────────
  for (const [id, cv] of Object.entries(cashVouchers)) {
    const debitSum  = (cv.lines || []).reduce((s, l) => s + (l.debit  || 0), 0);
    const creditSum = (cv.lines || []).reduce((s, l) => s + (l.credit || 0), 0);
    if (Math.abs(debitSum - creditSum) > 0.05)
      fail(`cashVoucher[${id}]: unbalanced — debit ${debitSum} ≠ credit ${creditSum}`);
    for (const line of (cv.lines || [])) {
      if (line.accountId) has(accounts, line.accountId, `cashVoucher[${id}].line.accountId`);
    }
  }
  console.log('  ✓ cash voucher line balances valid');

  // ── New entities ──────────────────────────────────────────────────────────
  for (const [id, po] of Object.entries(purchaseOrders)) {
    has(vendors, po.vendorId, `purchaseOrder[${id}].vendorId`);
    for (const it of (po.items || [])) has(products, it.productId, `purchaseOrder[${id}].item.productId`);
    eq(po.gross - po.discounts, po.invoiceValue, `purchaseOrder[${id}] invoiceValue`);
  }
  for (const [id, so] of Object.entries(sendOrders)) {
    has(purchaseOrders, so.orderId, `sendOrder[${id}].orderId`);
    if (so.bankAccountId) has(accounts, so.bankAccountId, `sendOrder[${id}].bankAccountId`);
    for (const it of (so.items || [])) has(products, it.productId, `sendOrder[${id}].item.productId`);
  }
  for (const [id, sr] of Object.entries(salesReturns)) {
    has(customers, sr.customerId, `salesReturn[${id}].customerId`);
    if (sr.salesmanId) has(salesmen, sr.salesmanId, `salesReturn[${id}].salesmanId`);
    if (sr.saleId) has(salesInvoices, sr.saleId, `salesReturn[${id}].saleId`);
    for (const it of (sr.items || [])) has(products, it.productId, `salesReturn[${id}].item.productId`);
    eq(sr.totalPayable - sr.paidAmount, sr.remBalance, `salesReturn[${id}] remBalance`);
  }
  for (const [id, pr] of Object.entries(purchaseReturns)) {
    has(vendors, pr.vendorId, `purchaseReturn[${id}].vendorId`);
    if (pr.purchaseInvoiceId) has(purchaseInvoices, pr.purchaseInvoiceId, `purchaseReturn[${id}].purchaseInvoiceId`);
    for (const it of (pr.items || [])) has(products, it.productId, `purchaseReturn[${id}].item.productId`);
  }
  for (const [id, si] of Object.entries(stockIssues)) {
    has(salesmen, si.salesmanId, `stockIssue[${id}].salesmanId`);
    if (si.issueType === 'return' && si.originalIssueId) has(stockIssues, si.originalIssueId, `stockIssue[${id}].originalIssueId`);
    for (const it of (si.items || [])) has(products, it.productId, `stockIssue[${id}].item.productId`);
  }
  for (const [id, wa] of Object.entries(stockWastages)) {
    for (const it of (wa.items || [])) has(products, it.productId, `stockWastage[${id}].item.productId`);
  }
  for (const [id, ex] of Object.entries(stockExpiries)) {
    for (const it of (ex.items || [])) has(products, it.productId, `stockExpiry[${id}].item.productId`);
  }
  for (const [id, cl] of Object.entries(expiryClaims)) {
    if (cl.vendorId) has(vendors, cl.vendorId, `expiryClaim[${id}].vendorId`);
    for (const it of (cl.items || [])) has(products, it.productId, `expiryClaim[${id}].item.productId`);
  }
  for (const [id, riw] of Object.entries(recoveryInvoicesWise)) {
    has(salesmen, riw.salesmanId, `recoveryInvoiceWise[${id}].salesmanId`);
    for (const cr of (riw.customerRecoveries || [])) {
      has(customers, cr.customerId, `recoveryInvoiceWise[${id}].cr.customerId`);
      for (const inv of (cr.invoices || [])) {
        has(salesInvoices, inv.saleId, `recoveryInvoiceWise[${id}].cr.invoice.saleId`);
        eq(inv.receivable - inv.received - inv.discount, inv.balance, `recoveryInvoiceWise[${id}] balance`);
      }
    }
    const sumRec = (riw.customerRecoveries||[]).flatMap(c=>c.invoices||[]).reduce((s,i)=>s+i.received,0);
    eq(sumRec, riw.netReceived, `recoveryInvoiceWise[${id}] netReceived`);
  }
  for (const [id, rrw] of Object.entries(recoveryReceivableWise)) {
    has(salesmen, rrw.salesmanId, `recoveryReceivableWise[${id}].salesmanId`);
    for (const cr of (rrw.customerRecoveries || [])) {
      has(customers, cr.customerId, `recoveryReceivableWise[${id}].cr.customerId`);
      eq(cr.receivable - cr.received - cr.discount, cr.balance, `recoveryReceivableWise[${id}].cr balance`);
    }
    const sumRec = (rrw.customerRecoveries||[]).reduce((s,r)=>s+r.received,0);
    eq(sumRec, rrw.netReceived, `recoveryReceivableWise[${id}] netReceived`);
  }
  for (const [id, scr] of Object.entries(salesmanCashReconciliations)) {
    has(salesmen, scr.salesmanId, `SCR[${id}].salesmanId`);
    const expectedClose = scr.openingBalance + scr.totalCashReceived - scr.totalExpenses - scr.cashDeposited;
    eq(scr.closingBalance, expectedClose, `SCR[${id}] closingBalance`);
    for (const re of (scr.recoveryEntries||[])) has(recoveryInvoices, re.recoveryId, `SCR[${id}].recoveryEntry.recoveryId`);
  }
  for (const [id, pp] of Object.entries(paymentPromises)) {
    if (pp.customerId) has(customers, pp.customerId, `paymentPromise[${id}].customerId`);
    if (pp.vendorId)   has(vendors,   pp.vendorId,   `paymentPromise[${id}].vendorId`);
    if (pp.salesmanId) has(salesmen,  pp.salesmanId, `paymentPromise[${id}].salesmanId`);
    for (const sid of (pp.linkedSaleIds||[]))     has(salesInvoices,   sid, `paymentPromise[${id}].linkedSaleId`);
    for (const pid of (pp.linkedPurchaseIds||[])) has(purchaseInvoices, pid, `paymentPromise[${id}].linkedPurchaseId`);
  }
  console.log('  ✓ all extended entity references valid');

  console.log('  [Phase 4 complete]\n');
}

// ══════════════════════════════════════════════════════════════════════════════
// WIPE
// ══════════════════════════════════════════════════════════════════════════════

async function wipe() {
  console.log('\n[WIPE] Clearing all collections for UID:', UID, '…');
  const settingsEntities = ['accounts','units','packings','productGroups','productSubGroups','products','discountSchemes','vendors','towns','sectors','customers','salesmen','openings'];
  const poultryEntities  = ['flocks','flockFeeds','flockVaccines','chickenInvoices','feedSchedules','vaccineSchedules'];
  const invoicingEntities= ['salesInvoices','purchaseInvoices','purchaseOrders','sendOrders','salesReturns','purchaseReturns','stockIssues','stockExpiries','stockWastages','expiryClaims','recoveryInvoices','recoveryInvoicesWise','recoveryReceivableWise','cashVouchers','salesmanCashReconciliations','bankCheques','bankDeposits','paymentPromises'];
  const accountsEntities = ['ledgerEntries'];

  await Promise.all([
    ...settingsEntities.map(e  => wipeCollection(col.settings(e))),
    ...poultryEntities.map(e   => wipeCollection(col.poultry(e))),
    ...invoicingEntities.map(e => wipeCollection(col.invoicing(e))),
    ...accountsEntities.map(e  => wipeCollection(col.accounts(e))),
  ]);
  console.log('  ✓ all collections wiped\n');
}

// ══════════════════════════════════════════════════════════════════════════════
// MAIN
// ══════════════════════════════════════════════════════════════════════════════

async function main() {
  console.log('══════════════════════════════════════════');
  console.log('  POULTRY FARM — SEED DATA');
  console.log(`  UID: ${UID}`);
  console.log('══════════════════════════════════════════');

  try {
    if (WIPE) await wipe();

    await seedSettings();
    await seedPoultry();
    await seedInvoicingAndAccounts();
    await validate();

    // ── Final report ─────────────────────────────────────────────────────────
    console.log('══════════════════════════════════════════');
    if (ERRORS.length === 0) {
      console.log('  ✅ ALL VALIDATIONS PASSED');
      console.log('\n  Data written:');
      console.log('    Settings : 15 accounts, 7 products, 6 customers, 3 salesmen, 3 vendors, 4 towns, 6 sectors');
      console.log('    Poultry  : 3 flocks, 12 feed records, 6 vaccine records, 3 chicken invoices');
      console.log('    Invoicing: 5 sales invoices, 2 purchase invoices, 2 purchase orders, 1 send order');
      console.log('               2 sales returns, 1 purchase return, 3 stock issues, 1 wastage, 1 expiry, 1 expiry claim');
      console.log('               2 recovery invoices, 1 recovery-invoice-wise, 1 recovery-receivable-wise');
      console.log('               2 salesman cash reconciliations, 2 payment promises');
      console.log('               3 cash vouchers, 1 bank deposit, 1 bank cheque');
      console.log('    Accounts : 20 ledger entries (fully balanced)');
    } else {
      console.log(`  ❌ ${ERRORS.length} VALIDATION ERROR(S):`);
      ERRORS.forEach((e, i) => console.log(`    ${i + 1}. ${e}`));
    }
    console.log('══════════════════════════════════════════\n');

    process.exit(ERRORS.length > 0 ? 1 : 0);
  } catch (err) {
    console.error('\nFATAL ERROR:', err.message);
    console.error(err.stack);
    process.exit(1);
  }
}

main();
