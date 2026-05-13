# Claude Code Prompt: Full Invoicing Module + Product Model Corrections


---

## 0. Codebase Quick Reference

**Package name:** `farm_mgt_auth`  
**State management:** Provider (ChangeNotifier) — no GetX, Riverpod, or BLoC  
**No new packages** — use only what is already in pubspec.yaml

**Firestore path pattern (ALL modules follow this exactly):**
```
users/{uid}/{module}/{entity}/items/{docId}
```
Where `{module}` is one of: `settings`, `poultry`, `accounts`, `invoicing` (new).

Each module has a `{module}EntityDoc(uid, entity)` function that returns the entity metadata doc, and a `{module}Collection(uid, entity)` function that returns `.collection('items')` on that doc. Copy the exact pattern from `backend/src/modules/poultry/poultry.validators.js`.

**Existing scopes registered wrapping the whole app (do NOT re-register):**
- `SettingsScope` — provides all settings controllers: `CustomersController`, `VendorsController`, `ProductsController`, `PackingsController`, `SalesmenController`, `TownsController`, `SectorsController`, `AccountsController`, `CompaniesController`, `UnitsController`, etc.
- `PoultryScope` — provides poultry controllers
- `AccountsReportsScope` — provides ledger controllers

**InvoicingScope must NOT re-register any settings controllers.** All invoicing screens read settings controllers from the parent scope via `context.read<>()`.

---

## Part 1 — Product Model Corrections (settings module changes)

### 1.1 New fields to add in `frontend/lib/modules/settings/config/settings_definitions.dart`

Add these fields to the `products` SettingsCategoryConfig. Remove the old single `packingId` field and replace with two packing fields:

```dart
// After 'name':
SettingsFieldConfig(key: 'companyId', label: 'Company', type: SettingsFieldType.dropdown,
  optionsBuilder: (context, values, item) => _companyOptions(context)),
SettingsFieldConfig(key: 'longName', label: 'Long Name', type: SettingsFieldType.text),

// After existing unitId:
SettingsFieldConfig(key: 'size', label: 'Size', type: SettingsFieldType.number),
SettingsFieldConfig(key: 'displayOrder', label: 'Display Order', type: SettingsFieldType.number),

// REMOVE old 'packingId' field. REPLACE with:
SettingsFieldConfig(key: 'purPackingId', label: 'Purchase Packing', type: SettingsFieldType.dropdown,
  optionsBuilder: (context, values, item) => _packingOptions(context)),
SettingsFieldConfig(key: 'salePackingId', label: 'Sale Packing', type: SettingsFieldType.dropdown,
  optionsBuilder: (context, values, item) => _packingOptions(context)),

// Price grid — 4 price tiers:
SettingsFieldConfig(key: 'purchasePrice', label: 'Purchase Price', type: SettingsFieldType.number),
SettingsFieldConfig(key: 'purchaseDiscPercent', label: 'Purchase Disc%', type: SettingsFieldType.number),
SettingsFieldConfig(key: 'sale1Price', label: 'Sale Price 1', type: SettingsFieldType.number),
SettingsFieldConfig(key: 'sale1DiscPercent', label: 'Sale 1 Disc%', type: SettingsFieldType.number),
SettingsFieldConfig(key: 'sale2Price', label: 'Sale Price 2', type: SettingsFieldType.number),
SettingsFieldConfig(key: 'sale2DiscPercent', label: 'Sale 2 Disc%', type: SettingsFieldType.number),
SettingsFieldConfig(key: 'sale3Price', label: 'Sale Price 3', type: SettingsFieldType.number),
SettingsFieldConfig(key: 'sale3DiscPercent', label: 'Sale 3 Disc%', type: SettingsFieldType.number),

// RENAME existing taxPercent key to salesTaxPercent:
SettingsFieldConfig(key: 'salesTaxPercent', label: 'Sales Tax (%)', type: SettingsFieldType.number),
SettingsFieldConfig(key: 'sedValue', label: 'SED Value', type: SettingsFieldType.number),
SettingsFieldConfig(key: 'retailPrice', label: 'Retail Price', type: SettingsFieldType.number),
SettingsFieldConfig(key: 'isPoultryItem', label: 'Poultry Item', type: SettingsFieldType.boolToggle),
SettingsFieldConfig(key: 'inactiveInAdditions', label: 'Inactive in Additions', type: SettingsFieldType.boolToggle),
SettingsFieldConfig(key: 'inactiveOnBonusForSales', label: 'Inactive on Bonus for Sales', type: SettingsFieldType.boolToggle),
```

Update `listSubtitleKeys` for products: `['code', 'companyId', 'sale1Price', 'salesTaxPercent']`

### 1.2 Update `frontend/lib/modules/settings/models/product.dart`

Add typed getters. The `salesTaxPercent` getter must include a backward-compat fallback for existing Firestore documents that still have the old `taxPercent` key:

```dart
String get longName => text('longName');
String get companyId => text('companyId');
String get purPackingId => text('purPackingId');
String get salePackingId => text('salePackingId');
double get size => number('size');
double get displayOrder => number('displayOrder');
double get purchasePrice => number('purchasePrice');
double get purchaseDiscPercent => number('purchaseDiscPercent');
double get sale1Price => number('sale1Price');
double get sale1DiscPercent => number('sale1DiscPercent');
double get sale2Price => number('sale2Price');
double get sale2DiscPercent => number('sale2DiscPercent');
double get sale3Price => number('sale3Price');
double get sale3DiscPercent => number('sale3DiscPercent');
double get retailPrice => number('retailPrice');
// Backward-compat: read salesTaxPercent, fall back to old taxPercent field
double get salesTaxPercent {
  final v = number('salesTaxPercent');
  return v != 0 ? v : number('taxPercent');
}
double get sedValue => number('sedValue');
bool get isPoultryItem => boolean('isPoultryItem');
bool get inactiveInAdditions => boolean('inactiveInAdditions');
bool get inactiveOnBonusForSales => boolean('inactiveOnBonusForSales');
bool get isActive => boolean('isActive');
```

### 1.3 Update `backend/src/models/settings.config.js` — products sanitize()

Remove old `packingId`. Add all new fields. The `salesTaxPercent` field replaces `taxPercent`:

```js
companyId:     await requireNullableRef(uid, 'companies', asNullableString(body.companyId), 'companyId', errors),
longName:      asNullableString(body.longName),
size:          asNumber(body.size, 'size', errors, { min: 0, defaultValue: 0 }),
displayOrder:  asNumber(body.displayOrder, 'displayOrder', errors, { min: 0, defaultValue: 0 }),
purPackingId:  asNullableString(body.purPackingId),   // FK check optional — products can exist without packing
salePackingId: asNullableString(body.salePackingId),
purchasePrice:        asNumber(body.purchasePrice, 'purchasePrice', errors, { min: 0, defaultValue: 0 }),
purchaseDiscPercent:  asNumber(body.purchaseDiscPercent, 'purchaseDiscPercent', errors, { min: 0, max: 100, defaultValue: 0 }),
sale1Price:           asNumber(body.sale1Price, 'sale1Price', errors, { min: 0, defaultValue: 0 }),
sale1DiscPercent:     asNumber(body.sale1DiscPercent, 'sale1DiscPercent', errors, { min: 0, max: 100, defaultValue: 0 }),
sale2Price:           asNumber(body.sale2Price, 'sale2Price', errors, { min: 0, defaultValue: 0 }),
sale2DiscPercent:     asNumber(body.sale2DiscPercent, 'sale2DiscPercent', errors, { min: 0, max: 100, defaultValue: 0 }),
sale3Price:           asNumber(body.sale3Price, 'sale3Price', errors, { min: 0, defaultValue: 0 }),
sale3DiscPercent:     asNumber(body.sale3DiscPercent, 'sale3DiscPercent', errors, { min: 0, max: 100, defaultValue: 0 }),
salesTaxPercent:      asNumber(body.salesTaxPercent, 'salesTaxPercent', errors, { min: 0, defaultValue: 0 }),
sedValue:      asNumber(body.sedValue, 'sedValue', errors, { min: 0, defaultValue: 0 }),
retailPrice:   asNumber(body.retailPrice, 'retailPrice', errors, { min: 0, defaultValue: 0 }),
isPoultryItem:          asBoolean(body.isPoultryItem, false),
inactiveInAdditions:    asBoolean(body.inactiveInAdditions, false),
inactiveOnBonusForSales: asBoolean(body.inactiveOnBonusForSales, false),
```

---

## Part 2 — Invoicing Module Overview

**34 transaction screens** across 5 menu groups. All use the same Flutter/Node.js patterns as the poultry module.

**Firestore module namespace:** `invoicing`
**Backend base route:** `/api/v1/invoicing/`
**Frontend base service path:** `/invoicing/`

---

## Part 3 — Complete File Structure

### Frontend: `frontend/lib/modules/invoicing/`

```
invoicing/
  config/
    invoicing_definitions.dart    ← InvoicingSection enum + all lookup constants
    invoicing_nav_config.dart     ← nav group/item definitions
  models/                         ← 18 model files (all extend BaseSettingsModel)
    purchase_order_model.dart
    send_order_model.dart
    purchase_invoice_model.dart
    purchase_return_model.dart
    sales_invoice_model.dart
    sales_return_model.dart
    stock_issue_model.dart
    stock_expiry_model.dart
    expiry_claim_model.dart
    stock_wastage_model.dart
    recovery_invoice_model.dart
    recovery_invoice_wise_model.dart
    recovery_receivable_wise_model.dart
    cash_voucher_model.dart
    salesman_cash_reconciliation_model.dart
    bank_cheque_model.dart
    bank_deposit_model.dart
    payment_promise_model.dart
  controllers/                    ← 19 controller files (all extend ChangeNotifier)
    invoicing_nav_controller.dart
    purchase_order_controller.dart
    send_order_controller.dart
    purchase_invoice_controller.dart
    purchase_return_controller.dart
    sales_invoice_controller.dart
    sales_return_controller.dart
    stock_issue_controller.dart
    stock_expiry_controller.dart
    expiry_claim_controller.dart
    stock_wastage_controller.dart
    recovery_invoice_controller.dart
    recovery_invoice_wise_controller.dart
    recovery_receivable_wise_controller.dart
    cash_voucher_controller.dart
    salesman_cash_reconciliation_controller.dart
    bank_cheque_controller.dart
    bank_deposit_controller.dart
    payment_promise_controller.dart
  services/                       ← 15 service files
    invoicing_json_service.dart   ← base service (mirrors PoultryJsonService, path = /invoicing/)
    purchase_order_service.dart
    send_order_service.dart
    purchase_invoice_service.dart
    purchase_return_service.dart
    sales_invoice_service.dart
    sales_return_service.dart
    stock_issue_service.dart
    stock_expiry_service.dart
    expiry_claim_service.dart
    stock_wastage_service.dart
    recovery_invoice_service.dart
    recovery_invoice_wise_service.dart
    recovery_receivable_wise_service.dart
    cash_voucher_service.dart
    salesman_cash_reconciliation_service.dart
    bank_cheque_service.dart
    bank_deposit_service.dart
    payment_promise_service.dart
  views/                          ← 39 view files
    invoicing_screen.dart         ← top-level shell with nav rail + content area
    purchase_order_screen.dart
    send_order_screen.dart
    purchase_invoice_screen.dart
    purchase_return_screen.dart
    sales_invoice_screen.dart
    sales_return_screen.dart
    stock_issue_screen.dart
    stock_expiry_screen.dart
    expiry_claim_screen.dart
    stock_wastage_screen.dart
    recovery_invoice_screen.dart
    recovery_invoice_wise_screen.dart
    recovery_receivable_wise_screen.dart
    cash_voucher_screen.dart
    salesman_cash_reconciliation_screen.dart
    bank_cheque_issuing_screen.dart
    bank_cheques_reconciliation_screen.dart
    cash_deposit_screen.dart
    cheque_deposit_screen.dart
    deposit_confirmation_screen.dart
    deposit_reconciliation_screen.dart
    voucher_confirmation_screen.dart
    post_dated_recovery_promise_screen.dart
    post_dated_payment_promise_screen.dart
    promises_processing_screen.dart
  widgets/
    invoice_line_item_row.dart    ← reusable product line-item data row
    invoice_totals_footer.dart    ← reusable totals bar
    voucher_line_row.dart         ← account/debit/credit/narration row
  invoicing_scope.dart
```

### Backend: `backend/src/modules/invoicing/`

```
invoicing/
  entities/                       ← 18 config files
    purchase_order.config.js
    send_order.config.js
    purchase_invoice.config.js
    purchase_return.config.js
    sales_invoice.config.js
    sales_return.config.js
    stock_issue.config.js
    stock_expiry.config.js
    expiry_claim.config.js
    stock_wastage.config.js
    recovery_invoice.config.js
    recovery_invoice_wise.config.js
    recovery_receivable_wise.config.js
    cash_voucher.config.js
    salesman_cash_reconciliation.config.js
    bank_cheque.config.js
    bank_deposit.config.js
    payment_promise.config.js
  invoicing.routes.js
  invoicing.validators.js
```

---

## Part 4 — Backend: invoicing.validators.js

Model exactly on `backend/src/modules/poultry/poultry.validators.js`. Change:
- `poultryEntityDoc` → `invoicingEntityDoc`
- `poultryCollection` → `invoicingCollection`
- `ensurePoultryExists` → `ensureInvoicingExists`
- `requirePoultryRef` → `requireInvoicingRef`
- Collection path: `.collection('invoicing').doc(entity)` (not `poultry`)

Export the same primitive validators (`asRequiredString`, `asNullableString`, `asNumber`, `asBoolean`, `asEnum`, `asDateString`, `cleanStringList`) and both `requireSettingsRef` + `requireInvoicingRef`.

### Sequential ID generation helper

Add this to `invoicing.validators.js` — used by all entity configs to generate sequential human-readable IDs:

```js
async function nextSequentialId(uid, entity, prefix) {
  // Reads all items, finds max numeric suffix, returns prefix + (max+1)
  // e.g. nextSequentialId(uid, 'salesInvoices', 'SI') → 'SI-2533'
  const snap = await invoicingCollection(uid, entity)
    .orderBy('createdAt', 'desc')
    .limit(100)
    .get();
  let max = 0;
  snap.docs.forEach(doc => {
    const id = doc.data()[`${entity.replace(/s$/, '')}Id`] || '';
    const n = parseInt(id.replace(/\D/g, ''), 10);
    if (!isNaN(n) && n > max) max = n;
  });
  return `${prefix}-${String(max + 1).padStart(4, '0')}`;
}
```

Export `nextSequentialId`.

---

## Part 5 — Detailed Data Models (field-by-field, FK references explicit)

### IMPORTANT: Line item value formula (consistent across ALL transaction types)

```
lineGross     = (qtyPacks × pack + qtyLoose) × price
lineDisc      = lineGross × (discPercent / 100)
lineNet       = lineGross - lineDisc
lineTax       = lineNet × (salesTaxPercent / 100)
lineValueIncST = lineNet + lineTax
```

Header totals formula (consistent across Sales Invoice, Purchase Invoice, Sales Return, etc.):
```
gross         = sum(lineGross)          ← sum of pre-discount line values
discounts     = gross × (disc2Percent / 100) + sum(lineDisc)  ← header disc + all line discs
invoiceValue  = gross - discounts
salesTax      = sum(lineTax)            ← already computed per line
fTax          = fTaxPercent% of invoiceValue (or flat input)
totalSED      = sum(line.sedValue × lineQty)  OR flat input
netValue      = invoiceValue + salesTax + fTax + expense + totalSED - spcDisc
totalPayable  = netValue + prevDebit    (for sales) OR netValue + prevCredit (for purchase)
remBalance    = totalPayable - paidAmount
```

---

### 5.1 Sales Invoice (`salesInvoices` collection)

**Header:**
- `saleId` — string, auto-generated via `nextSequentialId(uid, 'salesInvoices', 'SI')`, unique
- `entryDate` — ISO date, required
- `customerId` — required, `requireSettingsRef(uid, 'customers', ...)`
- `customerName` — denormalized string
- `townId` — nullable string (no FK check — just trim)
- `sectorId` — nullable string, dependent on townId (no FK check — just trim)
- `salesmanId` — nullable, `requireSettingsRef(uid, 'salesmen', ...)` if provided
- `salesmanName` — denormalized
- `prevDebit` — number default 0 (customer's existing debit balance, entered by user)
- `status` — enum: `'pending' | 'saved'`, default `'pending'`

**`items[]` array (each object):**
- `sNo` — number (line sequence 1,2,3...)
- `productId` — `requireSettingsRef(uid, 'products', ...)`
- `productName` — denormalized
- `packingName` — denormalized from product.salePackingId → packing.name
- `pack` — number (multiplier from packing record)
- `unit` — denormalized from product.unitId → unit.name
- `qtyPacks` — number ≥ 0
- `qtyLoose` — number ≥ 0
- `bonus` — number ≥ 0, default 0
- `price` — number ≥ 0, defaults to product.sale1Price
- `discPercent` — number 0–100, default 0
- `salesTaxPercent` — number (copied from product.salesTaxPercent at time of entry)
- `lineGross` — number, auto-calc server-side
- `lineDisc` — number, auto-calc
- `lineNet` — number, auto-calc
- `lineTax` — number, auto-calc
- `lineValueIncST` — number, auto-calc

**Totals (all auto-calc server-side, all stored):**
`gross`, `disc2Percent` (input, default 0), `discounts`, `invoiceValue`, `salesTax`, `fTax` (input, default 0), `expense` (input, default 0), `totalSED` (input, default 0), `spcDisc` (input, default 0), `netValue`, `totalPayable`, `ttlQty`, `paidAmount` (input, default 0), `remBalance`, `description`, `remarks`

---

### 5.2 Purchase Order (`purchaseOrders` collection)

**Header:**
- `orderId` — auto-generated via `nextSequentialId(uid, 'purchaseOrders', 'PO')`
- `entryDate` — required ISO date
- `vendorId` — required, `requireSettingsRef(uid, 'vendors', ...)`
- `vendorName` — denormalized
- `city` — nullable string
- `status` — `'pending' | 'saved'`, default `'pending'`

**`items[]`:** Same structure as sales invoice items EXCEPT uses `product.purPackingId` (not `salePackingId`) for packingName/pack, and `product.purchasePrice` as default price.
- Same fields: `sNo`, `productId`, `productName`, `packingName`, `pack`, `size` (from product.size), `qtyPacks`, `qtyLoose`, `bonus`, `price`, `discPercent`, `salesTaxPercent`, auto-calc line values

**Totals:** `gross`, `disc2Percent`, `discounts`, `invoiceValue`, `salesTax`, `fTaxPercent`, `furtherTaxValue`, `netValue`

---

### 5.3 Send Purchase Order (`sendOrders` collection)

**Header:**
- `sendOrderId` — auto-generated via `nextSequentialId(uid, 'sendOrders', 'SO')`
- `orderId` — **REQUIRED**, `requireInvoicingRef(uid, 'purchaseOrders', ...)` — must reference an existing Purchase Order
- When `orderId` is set: backend auto-populates `vendorId`, `vendorName`, `items[]` from the referenced Purchase Order
- `vendorId` — denormalized from PO, not user-editable
- `vendorName` — denormalized
- `draftNo` — string, nullable
- `draftDate` — ISO date, nullable
- `draftAmount` — number ≥ 0, default 0
- `bankAccountId` — nullable, `requireSettingsRef(uid, 'accounts', ...)` if provided
- `bankAcNo` — string (account number text, denormalized from account record)
- `bankAccountName` — denormalized
- `description` — string, nullable
- `includeAllProductsWhenPrinting` — bool, default false
- `totalOrderValue` — number, auto-calc = sum(items[].lineValueIncST)

**`items[]`:** Same as Purchase Order items, pre-populated from the linked PO but user can adjust quantities

**Actions on screen:** Save | Clear | Print | Open | Remove | Close — **NO Pending button**

---

### 5.4 Purchase Invoice (`purchaseInvoices` collection)

- `purchaseId` — auto-generated via `nextSequentialId(uid, 'purchaseInvoices', 'PI')`
- `entryDate` — required ISO date
- `vendorBillNo` — string, nullable (vendor's own bill number)
- `billDate` — ISO date, nullable
- `orderId` — nullable, `requireInvoicingRef(uid, 'purchaseOrders', ...)` if provided. When set: auto-populate `vendorId`, `vendorName`, `items[]` from PO
- `orderDate` — denormalized from PO if orderId set
- `vendorId` — required, `requireSettingsRef(uid, 'vendors', ...)`
- `vendorName` — denormalized
- `city` — string, nullable
- `status` — `'pending' | 'saved'`, default `'pending'`

**`items[]`:** Same as Purchase Order items (uses `purPackingId`)

**Totals:** `gross`, `disc2Percent`, `discounts`, `invoiceValue`, `salesTax`, `fTax`, `totalSED`, `spcDisc`, `netValue`, `prevCredit` (vendor's existing credit balance, input, default 0), `totalPayable` (= netValue + prevCredit), `paidAmount`, `remBalance`, `description`

---

### 5.5 Purchase Return (`purchaseReturns` collection)

- `returnId` — auto-generated via `nextSequentialId(uid, 'purchaseReturns', 'PR')`
- `returnType` — enum: `'with_invoice' | 'without_invoice'`
- `returnDate` — required ISO date
- `purchaseInvoiceId` — **required if `returnType = 'with_invoice'`**, nullable otherwise, `requireInvoicingRef(uid, 'purchaseInvoices', ...)`. When set: auto-populate `vendorId`, `vendorName`, items from the referenced PI
- `vendorId` — required (populated from PI when with_invoice, or entered directly for without_invoice), `requireSettingsRef(uid, 'vendors', ...)`
- `vendorName` — denormalized

**`items[]`:** Same structure as purchase invoice items representing returned quantities

**Totals:** `gross`, `disc2Percent`, `discounts`, `invoiceValue`, `salesTax`, `fTaxPercent`, `furtherTaxValue`, `netValue`

---

### 5.6 Sales Return (`salesReturns` collection)

- `returnId` — auto-generated via `nextSequentialId(uid, 'salesReturns', 'SR')`
- `returnType` — enum: `'with_invoice' | 'without_invoice'`
- `returnDate` — required ISO date

**Additional fields when `returnType = 'with_invoice'`:**
- `saleId` — required, `requireInvoicingRef(uid, 'salesInvoices', ...)`. When set: auto-populate `customerId`, `customerName`, `townId`, `sectorId`, `salesmanId`, `salesmanName` from the SI; also query `salesReturns` collection filtered by this `saleId` to calculate `previousReturnedQty` per product
- `saleDate` — denormalized from SI
- `isFullReturn` — bool (when true, current return qty = original sale qty minus previous returned qty)

**Fields for both types:**
- `customerId` — required, `requireSettingsRef(uid, 'customers', ...)`
- `customerName`, `townId`, `sectorId`, `salesmanId`, `salesmanName` — as in sales invoice
- `toMainStore` — bool, default true

**`items[]` for `with_invoice`:** Each item has:
- `productId`, `productName`, `packingName`, `pack`
- `saleQtyPacks`, `saleQtyLoose`, `saleBns` — original sale quantities (from SI)
- `prevReturnedQtyPacks`, `prevReturnedQtyLoose` — sum of previous returns for this saleId + productId
- `currentReturnQtyPacks`, `currentReturnQtyLoose` — what user enters (must not exceed saleQty - prevReturned)
- `price`, `discPercent`, `salesTaxPercent`, line calc fields

**`items[]` for `without_invoice`:** Standard line item entry (same as sales invoice items)

**Totals:** `disc2Percent`, `invoiceValue`, `salesTax`, `fTaxPercent`, `furtherTaxValue`, `sed`, `specialDiscount`, `netValue`, `prevCredit`, `totalPayable`, `paidAmount`, `remBalance`, `description`

---

### 5.7 Stock Issue / Stock Return from Salesman (`stockIssues` collection)

- `issueId` — auto-generated via `nextSequentialId(uid, 'stockIssues', issueType === 'issue' ? 'STI' : 'STR')`
- `issueType` — enum: `'issue' | 'return'`
- `date` — required ISO date
- `salesmanId` — required, `requireSettingsRef(uid, 'salesmen', ...)`
- `salesmanName` — denormalized
- `originalIssueId` — **nullable, only for `issueType = 'return'`**, `requireInvoicingRef(uid, 'stockIssues', ...)` if provided. "Return All" button fetches the most recent `issueType = 'issue'` for this salesman and populates items
- `returnAll` — bool, default false (only relevant when issueType = 'return')

**`items[]`:** `productId` (required, `requireSettingsRef`), `productName`, `packingId` (nullable, `requireSettingsRef(uid, 'packings', ...)`), `packingName`, `pack`, `qtyPacks`, `qtyLoose`, `cost`, `value` (auto-calc = qty × cost)

**Totals:** `netValue` = sum(item.value)

---

### 5.8 Stock Expiry / Damages Invoice (`stockExpiries` collection)

- `expiryId` — auto-generated via `nextSequentialId(uid, 'stockExpiries', 'EXP')`
- `date` — required ISO date

**`items[]`:** `productId` (required), `productName`, `packingName`, `pack`, `expQtyPacks`, `expQtyLoose`, `damQtyPacks`, `damQtyLoose`, `cost` (per unit, from product.purchasePrice), `value` (auto-calc = (expQtyPacks×pack + expQtyLoose + damQtyPacks×pack + damQtyLoose) × cost)

**Totals:** `netValue`

---

### 5.9 Expiry / Damages Claims (`expiryClaims` collection)

- `claimId` — auto-generated via `nextSequentialId(uid, 'expiryClaims', 'EC')`
- `direction` — enum: `'from_customer' | 'to_vendor'`
- `claimDate` — required ISO date
- `customerId` — required if `direction = 'from_customer'`, `requireSettingsRef(uid, 'customers', ...)`
- `customerName` — denormalized
- `vendorId` — required if `direction = 'to_vendor'`, `requireSettingsRef(uid, 'vendors', ...)`
- `vendorName` — denormalized

**`items[]`:** `productId` (required, `requireSettingsRef(uid, 'products', ...)`), `productName`, `packingName`, `pack`, `expQtyPacks`, `expQtyLoose`, `damQtyPacks`, `damQtyLoose`, `costPerUnit`, `price`, `value` (auto-calc)

**Totals:** `netValue`

**Reply section:**
- `replyDate` — ISO date, nullable
- `returnSameProducts` — bool, default false
- `replyItems[]` — `productId` (required if non-empty, `requireSettingsRef`), `productName`, `packingName`, `pack`, `qtyPacks`, `qtyLoose`, `price`, `value`
- `replyNetValue` — auto-calc from replyItems
- `repliedAmount` — number, nullable

---

### 5.10 Stock Wastage Invoice (`stockWastages` collection)

- `wastageId` — auto-generated via `nextSequentialId(uid, 'stockWastages', 'WAS')`
- `date` — required ISO date

**`items[]`:** `productId` (required), `productName`, `packingName`, `pack`, `expQtyPacks`, `expQtyLoose`, `damQtyPacks`, `damQtyLoose`, `cost`, `value`

**Totals:** `netValue`

---

### 5.11 Recovery Invoice (`recoveryInvoices` collection)

- `recoveryId` — auto-generated via `nextSequentialId(uid, 'recoveryInvoices', 'REC')`
- `date` — required ISO date
- `salesmanId` — required, `requireSettingsRef(uid, 'salesmen', ...)`
- `salesmanName` — denormalized

**`customerRecoveries[]`:**
- `customerId` — required per entry, `requireSettingsRef(uid, 'customers', ...)`
- `customerName` — denormalized
- `saleId` — required per entry, `requireInvoicingRef(uid, 'salesInvoices', ...)`
- `saleValue` — number (denormalized from SI.totalPayable)
- `adjusted` — number (amount previously adjusted)
- `receivable` — number (saleValue - adjusted - previously received — populated from SI.remBalance)
- `received` — number (what is being received now, user input ≥ 0)
- `discount` — number (discount being given now, ≥ 0)
- `finalCredit` — number (auto-calc = received + discount)
- `narration` — string, nullable

**Totals:** `totalNoInvoices` (count of customer rows), `amount` (sum of received), `discount` (sum of discount)

---

### 5.12 Recovery (Invoice Wise) (`recoveryInvoicesWise` collection)

- `recoveryId` — auto-generated via `nextSequentialId(uid, 'recoveryInvoicesWise', 'RIW')`
- `recoveryDate` — required ISO date
- `salesmanId` — required, `requireSettingsRef(uid, 'salesmen', ...)`
- `salesmanName` — denormalized
- `townId` — nullable (filter only, no FK check)
- `sectorId` — nullable (filter only)
- `showSalesmanInNarration` — bool, default false

**`customerRecoveries[]`:**
- `customerId`, `customerName`, `sector`
- `invoices[]`:
  - `saleId` — `requireInvoicingRef(uid, 'salesInvoices', ...)`
  - `date`, `invoiceValue`, `adjusted`, `receivable`, `received`, `discount`, `balance`, `narration`

**Totals:** `netReceived`, `discount`, `grossRecoveries`

---

### 5.13 Recovery (Receivable Wise) (`recoveryReceivableWise` collection)

- `recoveryId` — auto-generated via `nextSequentialId(uid, 'recoveryReceivableWise', 'RRW')`
- `recoveryDate` — required ISO date
- `salesmanId` — required, `requireSettingsRef(uid, 'salesmen', ...)`
- `salesmanName` — denormalized
- `townId`, `sectorId` — nullable filters
- `showSalesmanInNarration` — bool, default false

**`customerRecoveries[]`:**
- `customerId` — `requireSettingsRef(uid, 'customers', ...)`
- `customerName`, `sector`, `receivable`, `received`, `discount`, `balance`, `narration`

**Totals:** `netReceived`, `discount`, `grossRecoveries`

---

### 5.14 Cash Vouchers (`cashVouchers` collection)

- `voucherType` — required enum: `'credit' | 'debit' | 'journal'`
- `voucherNo` — auto-generated sequential per voucherType via:
  ```js
  // Counter stored at: invoicingEntityDoc(uid, `cashVoucherCounter_${voucherType}`)
  // Each counter doc has a `lastNo` field incremented atomically in a transaction
  ```
- `voucherDate` — required ISO date, default today
- `isConfirmed` — bool, default false
- `confirmedDate` — nullable ISO date
- `confirmedBy` — nullable string

**`lines[]`:**
- `accountId` — required, `requireSettingsRef(uid, 'accounts', ...)`
- `accountNo` — denormalized from account.accountCode
- `accountName` — denormalized from account.accountName
- `debit` — number, default 0 (never null)
- `credit` — number, default 0 (never null)
- `narration` — string, nullable

Validation: `credit` voucher → all lines must have `debit = 0`; `debit` voucher → all lines must have `credit = 0`; `journal` → no restriction but `sum(debit) === sum(credit)` is enforced

**`totals`:** `debit` = sum(lines.debit), `credit` = sum(lines.credit)

---

### 5.15 Salesman Cash Reconciliation (`salesmanCashReconciliations` collection)

- `reconciliationId` — auto-generated via `nextSequentialId(uid, 'salesmanCashReconciliations', 'SCR')`
- `date` — required ISO date
- `salesmanId` — required, `requireSettingsRef(uid, 'salesmen', ...)`
- `salesmanName` — denormalized
- `openingBalance` — number, default 0

**`recoveryEntries[]`:**
- `recoveryId` — `requireInvoicingRef(uid, 'recoveryInvoices', ...)`
- `recoveryDate` — denormalized
- `cashReceived` — number ≥ 0
- `discountGiven` — number ≥ 0
- `narration` — string, nullable

**`expenseEntries[]`:**
- `description` — string, required per entry
- `amount` — number ≥ 0

**Totals (all auto-calc):**
- `totalCashReceived`, `totalDiscount`, `totalExpenses`
- `cashDeposited` — number, user input
- `closingBalance` = openingBalance + totalCashReceived - totalExpenses - cashDeposited
- `status` — `'pending' | 'saved'`

---

### 5.16 Bank Cheque (`bankCheques` collection)

- `chequeId` — auto-generated via `nextSequentialId(uid, 'bankCheques', 'CHQ')`
- `chequeNo` — string, required
- `chequeDate` — required ISO date
- `bankAccountId` — required, `requireSettingsRef(uid, 'accounts', ...)`
- `bankAcNo` — denormalized from account.accountCode
- `bankAccountName` — denormalized
- `payeeType` — enum: `'vendor' | 'account' | 'other'`
- `vendorId` — required if `payeeType = 'vendor'`, `requireSettingsRef(uid, 'vendors', ...)`
- `vendorName` — denormalized
- `payeeAccountId` — required if `payeeType = 'account'`, `requireSettingsRef(uid, 'accounts', ...)`
- `payeeAccountName` — denormalized
- `payeeName` — string, required if `payeeType = 'other'`
- `amount` — number, required, min 0.01
- `narration` — string, nullable
- `isPostDated` — bool, default false
- `status` — enum: `'issued' | 'cleared' | 'bounced' | 'cancelled'`, default `'issued'`
- `clearedDate` — nullable ISO date

---

### 5.17 Bank Deposit (`bankDeposits` collection)

- `depositId` — auto-generated via `nextSequentialId(uid, 'bankDeposits', 'DEP')`
- `depositType` — enum: `'cash' | 'cheque'`
- `depositDate` — required ISO date
- `bankAccountId` — required, `requireSettingsRef(uid, 'accounts', ...)`
- `bankAccountName` — denormalized
- `depositSlipNo` — string, nullable
- `amount` — number, required, min 0.01
- `fromAccountId` — nullable, `requireSettingsRef(uid, 'accounts', ...)` if provided
- `fromAccountName` — denormalized
- `narration` — string, nullable
- `isConfirmed` — bool, default false
- `confirmedDate` — nullable ISO date
- `isReconciled` — bool, default false
- `reconciledDate` — nullable ISO date
- `bankStatementRef` — string, nullable

**Additional fields when `depositType = 'cheque'`:**
- `chequeNo` — string, required if cheque
- `chequeDate` — ISO date, nullable
- `drawerName` — string, nullable
- `drawerBankName` — string, nullable

---

### 5.18 Payment Promise (`paymentPromises` collection)

- `promiseId` — auto-generated via `nextSequentialId(uid, 'paymentPromises', 'PP')`
- `promiseType` — enum: `'recovery' | 'payment'`
- `entryDate` — required ISO date, default today
- `promiseDate` — required ISO date (future date of the promise)
- `customerId` — required if `promiseType = 'recovery'`, `requireSettingsRef(uid, 'customers', ...)`
- `customerName` — denormalized
- `vendorId` — required if `promiseType = 'payment'`, `requireSettingsRef(uid, 'vendors', ...)`
- `vendorName` — denormalized
- `salesmanId` — nullable, `requireSettingsRef(uid, 'salesmen', ...)` if provided
- `salesmanName` — denormalized
- `chequeNo` — string, nullable
- `bankName` — string, nullable
- `amount` — number, required, min 0.01
- `narration` — string, nullable
- `linkedSaleIds[]` — array of strings, each `requireInvoicingRef(uid, 'salesInvoices', ...)` (only when `promiseType = 'recovery'`)
- `linkedPurchaseIds[]` — array of strings, each `requireInvoicingRef(uid, 'purchaseInvoices', ...)` (only when `promiseType = 'payment'`)
- `status` — enum: `'pending' | 'cleared' | 'bounced' | 'cancelled'`, default `'pending'`
- `processedDate` — nullable ISO date

---

## Part 6 — Backend: invoicing.routes.js

Model exactly on `backend/src/modules/poultry/poultry.routes.js`. Use the same `createCrudRouter(config)` pattern.

```js
const express = require('express');
const { log } = require('../../core/logger');
const {
  invoicingCollection, invoicingEntityDoc,
  stampNew, stampUpdated, nowIso,
} = require('./invoicing.validators');

// Import all 18 entity configs
const purchaseOrderConfig              = require('./entities/purchase_order.config');
const sendOrderConfig                  = require('./entities/send_order.config');
// ... (all 18)

const router = express.Router();

// ─── Standard CRUD routers ────────────────────────────────────────────────────
router.use('/purchase-orders',               createCrudRouter(purchaseOrderConfig));
router.use('/purchase-invoices',             createCrudRouter(purchaseInvoiceConfig));
router.use('/purchase-returns',              createCrudRouter(purchaseReturnConfig));
router.use('/sales-invoices',                createCrudRouter(salesInvoiceConfig));
router.use('/sales-returns',                 createCrudRouter(salesReturnConfig));
router.use('/stock-issues',                  createCrudRouter(stockIssueConfig));
router.use('/stock-expiries',                createCrudRouter(stockExpiryConfig));
router.use('/expiry-claims',                 createCrudRouter(expiryClaimConfig));
router.use('/stock-wastages',               createCrudRouter(stockWastageConfig));
router.use('/recovery-invoices',             createCrudRouter(recoveryInvoiceConfig));
router.use('/recovery-invoices-wise',        createCrudRouter(recoveryInvoiceWiseConfig));
router.use('/recovery-receivable-wise',      createCrudRouter(recoveryReceivableWiseConfig));
router.use('/cash-vouchers',                 createCrudRouter(cashVoucherConfig));
router.use('/salesman-cash-reconciliations', createCrudRouter(salesmanCashReconciliationConfig));
router.use('/bank-cheques',                  createCrudRouter(bankChequeConfig));
router.use('/bank-deposits',                 createCrudRouter(bankDepositConfig));
router.use('/payment-promises',              createCrudRouter(paymentPromiseConfig));

// send-orders has special auto-populate from PO — custom POST only, uses createCrudRouter for GET/PUT/DELETE
router.use('/send-orders', createCrudRouter(sendOrderConfig));
```

**Custom PATCH endpoints (implement inline with try/catch + log pattern):**

```js
// Bank cheque status update
router.patch('/bank-cheques/:id/status', async (req, res) => { ... });
// accepts: { status: 'cleared'|'bounced'|'cancelled', clearedDate }

// Bank deposit confirmation
router.patch('/bank-deposits/:id/confirm', async (req, res) => { ... });
// sets: isConfirmed=true, confirmedDate=today

// Bank deposit reconciliation
router.patch('/bank-deposits/:id/reconcile', async (req, res) => { ... });
// sets: isReconciled=true, reconciledDate=today, bankStatementRef

// Cash voucher confirmation
router.patch('/cash-vouchers/:id/confirm', async (req, res) => { ... });
// sets: isConfirmed=true, confirmedDate=today, confirmedBy=req.user.email

// Payment promise status update
router.patch('/payment-promises/:id/status', async (req, res) => { ... });
// accepts: { status: 'cleared'|'bounced'|'cancelled', processedDate }
```

**Register in `backend/src/index.js`:**
```js
const invoicingRoutes = require('./modules/invoicing/invoicing.routes');
app.use('/api/v1/invoicing', authenticate, invoicingRoutes);
```

---

## Part 7 — Frontend Service Pattern

### 7.1 InvoicingJsonService base class

Create `invoicing_json_service.dart` as an exact copy of `poultry_json_service.dart` with:
1. Class renamed to `InvoicingJsonService<T>`
2. `String get _basePath => '/invoicing/$entityPath';` (not `/poultry/`)
3. All `OfflineCacheService.poultryListKey(...)` calls changed to `OfflineCacheService.invoicingListKey(...)`
4. All `OfflineCacheService.poultryItemKey(...)` calls changed to `OfflineCacheService.invoicingItemKey(...)`
5. All `module: 'poultry'` in OfflineOperation changed to `module: 'invoicing'`
6. Log prefix changed from `[POULTRY]` to `[INVOICING]`

### 7.2 OfflineCacheService additions

**Modify** `frontend/lib/services/offline_cache_service.dart` — add these key methods alongside the existing `poultryListKey` etc.:

```dart
static String invoicingListKey(String entity, {String? queryString}) {
  final suffix = (queryString != null && queryString.isNotEmpty)
      ? ':${queryString.hashCode.abs()}'
      : '';
  return 'cache:${_fid()}:invoicing:$entity:list$suffix';
}

static String invoicingItemKey(String entity, String id) =>
    'cache:${_fid()}:invoicing:$entity:item:$id';

static String invoicingTsKey(String entity) =>
    'cache:${_fid()}:invoicing:$entity:ts';
```

### 7.3 Individual service pattern

Every service extends `InvoicingJsonService<TModel>`:

```dart
// Example: sales_invoice_service.dart
import '../models/sales_invoice_model.dart';
import 'invoicing_json_service.dart';

class SalesInvoiceService extends InvoicingJsonService<SalesInvoiceModel> {
  SalesInvoiceService()
      : super(entityPath: 'sales-invoices', parser: SalesInvoiceModel.fromMap);

  Future<List<SalesInvoiceModel>> fetchPending() =>
      fetchAll(queryString: 'status=pending');
}
```

Services that need PATCH calls (bank cheque, bank deposit, cash voucher, payment promise) add extra methods using `_api.patch(path, body, auth: true)` alongside the inherited CRUD methods.

---

## Part 8 — Frontend Controller Pattern

### 8.1 Standard controller template

Every controller follows `FlockController` exactly:

```dart
class SalesInvoiceController extends ChangeNotifier {
  SalesInvoiceController() : _service = SalesInvoiceService() {
    OfflineSyncService.instance.addSyncListener(_onSyncComplete);
    OfflineSyncService.instance.addTempIdListener('sales-invoices', _onTempIdReplaced);
  }
  final SalesInvoiceService _service;
  List<SalesInvoiceModel> _items = [];
  bool _isLoading = false;
  String? _error;
  bool _isOfflineData = false;

  // getters, fetchAll, add, updateItem, deleteItem, dispose
  // _onSyncComplete, _onTempIdReplaced — same pattern as FlockController
}
```

### 8.2 InvoicingNavController

```dart
import 'package:flutter/foundation.dart';

enum InvoicingSection {
  // Invoicing group
  purchaseOrder, sendPurchaseOrder, purchaseInvoice,
  purchaseReturnWithInvoice, purchaseReturnWithoutInvoice,
  salesInvoice, salesReturnWithInvoice, salesReturnWithoutInvoice,
  // Stock group
  stockIssueToSalesman, stockReturnFromSalesman, stockExpiryInvoice,
  expiryClaimFromCustomer, expiryClaimToVendor, stockWastageInvoice,
  // Recovery group
  recoveryInvoice, recoveryInvoiceWise, recoveryReceivableWise,
  salesmanCashReconciliation,
  // Vouchers group
  cashReceivingVoucher, cashPaymentVoucher, journalVoucher,
  // Banking group
  bankChequeIssuing, bankChequesReconciliation,
  cashDepositInBank, chequeDepositInBank,
  depositConfirmation, depositReconciliation, voucherConfirmation,
  // Promises group
  postDatedRecoveryPromise, postDatedPaymentPromise, promisesProcessing,
}

class InvoicingNavController extends ChangeNotifier {
  InvoicingSection selectedSection = InvoicingSection.salesInvoice;

  void selectSection(InvoicingSection section) {
    selectedSection = section;
    notifyListeners();
  }
}
```

---

## Part 9 — Frontend InvoicingScope

```dart
// invoicing_scope.dart
// Bootstrap on init: salesInvoiceController.fetchAll(), purchaseOrderController.fetchAll()
// Do NOT re-register any settings controllers — they come from parent SettingsScope

MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => InvoicingNavController()),
    ChangeNotifierProvider(create: (_) => SalesInvoiceController()),
    ChangeNotifierProvider(create: (_) => PurchaseOrderController()),
    ChangeNotifierProvider(create: (_) => SendOrderController()),
    ChangeNotifierProvider(create: (_) => PurchaseInvoiceController()),
    ChangeNotifierProvider(create: (_) => PurchaseReturnController()),
    ChangeNotifierProvider(create: (_) => SalesReturnController()),
    ChangeNotifierProvider(create: (_) => StockIssueController()),
    ChangeNotifierProvider(create: (_) => StockExpiryController()),
    ChangeNotifierProvider(create: (_) => ExpiryClaimController()),
    ChangeNotifierProvider(create: (_) => StockWastageController()),
    ChangeNotifierProvider(create: (_) => RecoveryInvoiceController()),
    ChangeNotifierProvider(create: (_) => RecoveryInvoiceWiseController()),
    ChangeNotifierProvider(create: (_) => RecoveryReceivableWiseController()),
    ChangeNotifierProvider(create: (_) => CashVoucherController()),
    ChangeNotifierProvider(create: (_) => SalesmanCashReconciliationController()),
    ChangeNotifierProvider(create: (_) => BankChequeController()),
    ChangeNotifierProvider(create: (_) => BankDepositController()),
    ChangeNotifierProvider(create: (_) => PaymentPromiseController()),
  ],
  child: Builder(builder: (context) {
    // bootstrap on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesInvoiceController>().fetchAll();
      context.read<PurchaseOrderController>().fetchAll();
    });
    return widget.child;
  }),
);
```

---

## Part 10 — UI Patterns

### 10.1 Standard invoicing screen layout

```
Scaffold
  AppBar (title = transaction name)
  body: Column
    ── Header Card ─────────────────────────────────────────
       Row(wrap): date picker | customer/vendor lookup | salesman lookup | [other header fields]
    ── Line Item Entry Card ─────────────────────────────────
       Row: product lookup → auto-populates packing/price/tax | qty(P) | qty(L) | bonus | price | disc% | [Add] button
    ── Items DataTable (Expanded, scrollable) ───────────────
       Columns per transaction type (from Part 5)
       Each row has an inline delete icon
    ── Totals Footer Card (bottom-pinned) ───────────────────
       Gross | Disc2% | Discounts | InvValue | S.Tax | F.Tax | Expense | TotalSED | SpcDisc | NetValue | TotalPayable
    ── Action Bar ───────────────────────────────────────────
       [Pending] [Clear] [Open Pending] [Open] [Print] [Remove] [Save] [Close]
       (Send Order has NO Pending button — only Save/Clear/Print/Open/Remove/Close)
```

### 10.2 Product auto-populate rule (CRITICAL)

When user selects a product on a line item:
- **Sales Invoice / Sales Return / Stock Issue:** use `product.salePackingId` → fetch packing → fill `packingName`, `pack`; use `product.sale1Price` as default `price`; copy `product.salesTaxPercent` to `salesTaxPercent`
- **Purchase Invoice / Purchase Order / Purchase Return:** use `product.purPackingId`; use `product.purchasePrice` as default `price`

### 10.3 Voucher screen layout

```
Scaffold / AppBar
  Voucher No (auto-generated, read-only, yellow background) | Voucher Date
  Account entry row: Account No | Account Name (auto-lookup) | Debit | Credit | Narration | [Add]
  Lines DataTable (Expanded)
    credit voucher: Account No | Account Name | Credit | Narration
    debit voucher: Account No | Account Name | Debit | Narration
    journal voucher: Account No | Account Name | Debit | Credit | Narration
  Totals bar: Totals: [debitSum] [creditSum]
  Actions: [Save] [Clear] [Open] [Print] [Remove] [Close]
```

### 10.4 Recovery screen layout

```
Header: Recovery ID | Date | Salesman (lookup) | Town | Sector | [Show SM in Narration toggle] | [Populate]
Customer table: ID | Customer Name | Sector | Receivable | Received | Discount | Balance | Narration
(Invoice Wise only) Sub-table per customer: Sale ID | Date | InvValue | Adjusted | Receivable | Received | Discount | Balance | Narration
Footer: Recovery Salesman | Net Received | Discount | Gross Recoveries
Actions: [Save] [Clear] [Open] [Remove] [Close]
```

### 10.5 Pending / Open flow (all standard screens)

- **[Pending]** → `create(body.copyWith(status: 'pending'))` or `update(id, {status: 'pending'})`
- **[Open Pending]** → show dialog with list from `controller.items.where(status == 'pending')`, user taps to load into form
- **[Open]** → text field for ID → `fetchById(id)` → load into form
- **[Save]** → `create/update(body.copyWith(status: 'saved'))`
- **[Clear]** → reset all form fields, generate new sequential ID
- **[Remove]** → confirmation dialog → `deleteItem(id)`
- **[Print]** → show SnackBar "Print not yet implemented"
- **[Close]** → `Navigator.pop(context)`

### 10.6 Banking / reconciliation screen layout (read-filter-action pattern)

```
Filter Row: [filter fields] [Load button]
Results table with per-row action buttons
Footer summary row
Actions: [Save Changes] [Close]
```

---

## Part 11 — Navigation & Routing

### 11.1 invoicing_screen.dart (top-level shell)

Mirror `poultry_screen.dart` exactly. Uses `InvoicingNavController`. Navigation groups and items:

**Invoicing group:**
Purchase Order | Send Purchase Order | Purchase Invoice | Purchase Return (With Invoice) | Purchase Return (Without Invoice) | Sales Invoice | Sales Return (With Invoice) | Sales Return (Without Invoice)

**Stock group:**
Stock Issue to Salesman | Stock Return from Salesman | Stock Expiry Invoice | Expiry Claim From Customer | Expiry Claim To Vendor | Stock Wastage Invoice

**Recovery group:**
Recovery Invoice | Recovery (Invoice Wise) | Recovery (Receivable Wise) | Salesman Cash Reconciliation

**Vouchers group:**
Cash Receiving Voucher | Cash Payment Voucher | Journal Voucher

**Banking group:**
Bank Cheque Issuing | Bank Cheques Reconciliation | Cash Deposit in Bank | Cheque Deposit in Bank | Deposit Confirmation | Deposit Reconciliation | Voucher Confirmation

**Promises group:**
Post Dated Recovery Promise | Post Dated Payment Promise | Promises Processing

### 11.2 Route registration

`frontend/lib/core/route_manager.dart`: add `/invoicing` route alongside existing `/poultry`

`frontend/lib/modules/shell/main_shell.dart`: add Invoicing nav item alongside Poultry and Accounts Reports

`frontend/lib/main.dart`: wrap app with `InvoicingScope` at the same level as `PoultryScope`

---

## Part 12 — Execution Order

1. **Modify `offline_cache_service.dart`** — add `invoicingListKey`, `invoicingItemKey`, `invoicingTsKey`
2. **Modify `backend/src/models/settings.config.js`** — update products sanitize
3. **Modify `frontend/lib/modules/settings/`** — definitions + product.dart
4. **Create `backend/src/modules/invoicing/invoicing.validators.js`**
5. **Create all 18 backend entity configs** (start with sales_invoice, purchase_order, cash_voucher as they are most complex)
6. **Create `invoicing.routes.js`** and register in `index.js`
7. **Create `invoicing_json_service.dart`** (base)
8. **Create all 18 model files**
9. **Create all 18 entity service files** (each extends InvoicingJsonService)
10. **Create all 19 controller files**
11. **Create `invoicing_definitions.dart`** (InvoicingSection enum + lookup constants)
12. **Create `invoicing_nav_config.dart`**
13. **Create `invoicing_scope.dart`**
14. **Create `invoicing_screen.dart`** (shell)
15. **Create all 38 remaining view files** (sales_invoice_screen.dart first, then purchase screens, then stock, then recovery, then vouchers, then banking, then promises)
16. **Create 3 widget files**
17. **Wire routes, shell, main.dart**

---

## Part 13 — Do Not Touch

- Any file in `frontend/lib/modules/poultry/` (except the nav/shell if it needs an Invoicing entry)
- Any file in `frontend/lib/modules/accounts_reports/`
- Any file in `frontend/lib/modules/auth/`
- Any file in `backend/src/modules/poultry/`
- Any file in `backend/src/modules/accounts/`
- Any file in `backend/src/modules/auth/`