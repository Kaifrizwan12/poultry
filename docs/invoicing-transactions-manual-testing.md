# Farm Management System — Complete User Guide

This guide covers the entire system from first setup to daily operations. It is written for the farm owner, accountant, data entry staff, and salesmen. No accounting background needed.

---

## Part 1 — How the System Is Organized

The app has six main sections accessible from the left sidebar:

| Section | What it's for |
|---|---|
| **Home** | Overview dashboard |
| **Settings** | Master data setup — products, customers, vendors, accounts, etc. |
| **Invoicing** | Buying goods, selling goods, stock adjustments |
| **Transactions** | Cash collection, vouchers, bank operations, promises |
| **Poultry** | Flock management — bird placement, feeding, vaccination, chicken sales |
| **Reports** | Coming soon |

**The golden rule:** Always set up Settings first. Every other module depends on data that lives in Settings.

---

## Part 2 — Settings: Set Up Once, Use Everywhere

Settings is your master data. You set it up once at the start. Everything in Invoicing, Transactions, and Poultry references this data.

### 2.1 Setup Order (Follow This Exactly)

Set up settings in this order — each step depends on the previous one:

1. **Units** — kg, litre, piece, dozen, etc.
2. **Packings** — 50kg Bag, 5kg Bag, 1L Bottle, etc. Each packing links to a Unit.
3. **Companies** — the companies you buy from or sell to
4. **Product Groups** — Poultry Feed, Vaccines & Medicines, etc.
5. **Product Sub-Groups** — Broiler Feed, Layer Feed, Live Vaccines, etc. Each links to a Group.
6. **Products** — your actual inventory items. Each product links to a Group, Sub-Group, Unit, and two Packings (one for purchase, one for sale).
7. **Discount Schemes** — customer-level discount rules (percentage or flat amount)
8. **Towns** — geographic areas
9. **Sectors** — sub-areas within towns
10. **Salesmen** — your sales representatives. Each links to the towns they cover.
11. **Vendors** — your suppliers
12. **Customers** — your buyers. Each links to a Town, Sector, Salesman, and optionally a Discount Scheme.
13. **Accounts (Chart of Accounts)** — your bookkeeping accounts (Cash, Bank, Revenue, Expenses, etc.)
14. **Opening Stock** — how much of each product you had at system start
15. **Opening Receivables** — which customers owed you money at system start
16. **Opening Payables** — which vendors you owed money at system start
17. **Posting Config** — (last, after all accounts exist) maps GL accounts for automatic ledger posting

### 2.2 Products — The Most Important Setting

Every product has two packing configurations:

- **Purchase Packing** — the size you receive from vendors (e.g. 50kg Bag)
- **Sale Packing** — the size you sell to customers (e.g. 5kg Bag)

This matters because when your salesman sells 100 packs of 5kg bags, the system knows that's 500kg total.

Products also have three sale price tiers (Sale Price 1, 2, 3) and a purchase price. The system auto-fills Sale Price 1 when you create a sales invoice. Your accountant can set up Discount Schemes in settings so the system auto-applies the right discount for each customer.

### 2.3 Customers and Discount Schemes

When you set a Discount Scheme on a customer, the system automatically applies it when you select that customer on a Sales Invoice:

- **Percentage scheme** → fills the Disc2% field automatically
- **Flat scheme** → fills the Spc Disc field automatically

The scheme only applies if the current date falls within the scheme's Valid From / Valid To dates. If expired, no discount is applied.

### 2.4 Posting Config — For Automatic Accounting

If you want the system to automatically create ledger entries when you save certain transactions, set up Posting Config (Settings → Posting Config). Map these accounts:

- **Accounts Receivable** — money customers owe you (e.g. account code 1101)
- **Accounts Payable** — money you owe vendors (e.g. account code 2001)
- **Sales Revenue** — your income account (e.g. account code 4001)
- **Purchase/COGS** — your purchase expense account (e.g. account code 5001)
- **Cash in Hand** — your petty cash account (e.g. account code 1001)
- **Default Bank Account** — your main bank account (e.g. account code 1002)
- **Chicken Product** — which product from your product list represents "live chickens sold" — used when Chicken Invoices auto-generate Sales Invoices

---

## Part 3 — Document Numbers

Every document the system saves gets a unique number automatically. You never type these — they are assigned the moment you click Save.

| Document type | Example number |
|---|---|
| Sales Invoice | `SI-0001` |
| Purchase Order | `PO-0001` |
| Purchase Invoice | `PI-0001` |
| Sales Return | `SR-0001` |
| Purchase Return | `PR-0001` |
| Stock Issue | `STI-0001` |
| Stock Return | `STR-0001` |
| Recovery Invoice | `REC-0001` |
| Cash Voucher (receiving) | `CRV-0001` |
| Cash Voucher (payment) | `DBV-0001` |
| Journal Voucher | `JRV-0001` |
| Bank Cheque | `CHQ-0001` |
| Bank Deposit | `DEP-0001` |
| Payment Promise | `PP-0001` |

Numbers are sequential per type and never reset. `SI-0001` is always the first sales invoice saved by this farm.

---

## Part 4 — Finding Any Old Record

The system is moving to a **list-first** pattern.

On migrated screens, you land on a records list first. Use the search box or filters, then:
- click **New** to open a create dialog
- click any row to open that record in a fixed-size edit/detail dialog

On older inline screens that have not yet been migrated, you can still use the bottom **Records** button to open the search browser.

**How to search:**
- Type `SI-0003` → finds that exact invoice
- Type `Al-Madina` → finds all records for that customer
- Type `2026-04` → finds all records from April 2026
- Toggle **Pending** → shows only draft records

Press any row to load it into the form or dialog. You can then edit it, print it, or delete it.

**There are no Firestore IDs, no internal codes, no database keys anywhere in the UI.** The only IDs you ever see or search by are the business numbers above.

---

## Part 5 — Common Buttons (Everywhere in the System)

| Button | What it does |
|---|---|
| **Save** | Finalizes and saves the document |
| **Pending** | Saves as a draft — use when you're not sure yet. Only some screens have this. |
| **Records** | Opens the search browser on older inline screens. On migrated screens, the full records list is already the default landing view. |
| **Clear** | Wipes the form clean for a new entry |
| **Remove** | Deletes the currently loaded document (asks for confirmation) |
| **Print** | Not yet implemented |
| **Close** | Closes the dialog on migrated screens. On older inline screens it behaves like leaving the current form state. |
| **Populate** | Recovery screens only — click after selecting salesman to load customer data |
| **Load** | List screens (confirmations, reconciliations) — apply filters and show results |

---

## Part 6 — Common Field Names

| Field name | What it means |
|---|---|
| `Entry Date` | The date you are entering this in the system |
| `Bill Date` | The date printed on the supplier's paper invoice |
| `Vendor Bill No` | The invoice number on the supplier's paper (not your number — their number) |
| `Prev Debit` | How much this customer already owed you before this sale |
| `Prev Credit` | How much you already owed this vendor before this purchase |
| `Disc2 %` | Extra invoice-level discount percentage, applied after all per-line discounts |
| `Spc Disc` | Special discount in rupees (flat amount) applied to the invoice total |
| `F.Tax` / `FTax %` | Further Tax — a government tax sometimes required on specific goods |
| `SED` | Special Excise Duty — a specific government tax |
| `Paid Amount` | How much was paid at the time of this document |
| `Narration` | A short note for your own reference |
| `To Main Store` | Returned goods go back into your main warehouse |
| `Post Dated` | This cheque is for a future date — don't cash it yet |
| `Qty (P)` | Quantity in full packs (e.g. number of 50kg bags) |
| `Qty (L)` | Quantity in loose units not filling a full pack (e.g. 15 extra kg) |

---

## Part 7 — The Invoicing Tab

---

### Purchase Order

**What it is:** You call your supplier and place an order before anything arrives. This records the order officially.

**Who uses it:** Owner or purchase manager.

**Tricky points:**
- This is NOT a bill — the goods haven't arrived yet
- When goods do arrive, you create a **Purchase Invoice** and link it back to this PO
- The PO can also be sent to the vendor via the **Send Purchase Order** screen

**Try it:**
1. Select vendor → enter line items (product, qty, price) → click **Add** after each
2. Click **Pending** → saves as a draft
3. Click **Records**, toggle Pending, tap your draft to reload it
4. Click **Save** → `PO-0001` badge appears

---

### Send Purchase Order

**What it is:** In Pakistani trade, large orders are often sent to the supplier with a bank draft (advance payment). This screen records that the PO was dispatched along with the payment instrument.

**Who receives it:** Your supplier/vendor.

**Tricky points:**
- You must save the Purchase Order first
- When you select the PO, the vendor name and all items fill automatically — you don't re-enter them
- The Draft No is the LC or demand draft number from your bank
- There is **no Pending button** — you either sent it or you didn't
- The app records this for your audit trail but does not actually email or WhatsApp the vendor — you do that separately

**Try it:**
1. Save a PO first
2. Select it from the dropdown (shows `PO-0001 • VendorName`)
3. Items and vendor fill automatically
4. Fill in Draft No, Draft Date, Draft Amount, Bank Account
5. Save

---

### Purchase Invoice

**What it is:** The supplier's truck arrived, they handed you a paper bill. This is where you enter that bill.

**Tricky points:**
- Link to the PO if you have one → vendor and items auto-fill from the PO
- Enter the supplier's bill number in Vendor Bill No (this is their number, not yours)
- Enter Paid Amount if you paid cash on delivery
- `PI-0001` is your internal tracking number; the supplier's bill number is stored separately

**Try it:**
1. Create a PO first if you have one
2. Select the PO → vendor and items fill
3. Enter Vendor Bill No, Bill Date, Paid Amount
4. Save → `PI-0001`

---

### Purchase Return (With Invoice)

**What it is:** Goods arrived, you entered the Purchase Invoice, but some goods were damaged or wrong. You're sending them back.

**Tricky points:**
- "With Invoice" means you link this return to a specific PI already in the system
- Select the PI → vendor and items fill automatically
- Reduce quantities to what you're actually returning
- The system validates that return qty ≤ original PI qty — you cannot return more than was received

---

### Purchase Return (Without Invoice)

**What it is:** Same — returning goods to a vendor — but without linking to a prior invoice.

**When to use:** Old stock, goods received outside this system, or when you just want a clean return entry without the linkage.

---

### Sales Invoice

**What it is:** You sold goods to a customer. This records the sale.

**Tricky points:**
- When you select a **customer**, the Town, Sector, and Salesman auto-fill from the customer's record
- If the customer has an active **Discount Scheme**, the discount auto-fills too (Disc2% for percentage schemes, Spc Disc for flat schemes)
- `Prev Debit` = what the customer already owed you. The system adds it to the Total Payable so you see the full picture
- `Paid Amount` = cash they paid now. The rest becomes their open balance
- **Pending** = save as a draft when you're not 100% sure of quantities or prices

**Line item entry:**
1. Select product → packing name, pack size, sale price, and tax % fill automatically from product settings
2. Enter Qty(P) and/or Qty(L)
3. Adjust price if needed
4. Click **Add**

**Try it:**
1. Select customer → town/sector/salesman/discount fill
2. Add line items
3. Enter Paid Amount
4. Click **Pending** to draft, or **Save** to finalize

---

### Sales Return (With Invoice)

**What it is:** Customer is returning goods, and you have the original Sales Invoice in the system.

**Tricky points:**
- Select the Sales Invoice → customer, salesman, and original quantities fill
- **Full Return button** → sets all return quantities to the full original sale minus previous returns. Use when customer is returning everything.
- The system validates: total returns (today + previous) cannot exceed original sale qty. If you already returned 5 bags from a 20-bag sale, the maximum for the next return is 15 bags.
- `To Main Store` → turn this on so returned stock goes back to your main inventory

---

### Sales Return (Without Invoice)

**What it is:** Customer returning goods, no original invoice to link.

---

### Stock Issue to Salesman

**What it is:** Your salesman is heading out on his route. You physically give him stock to sell. This records what you handed over.

**Tricky points:**
- Cost fills automatically from the product's purchase price in settings
- When salesman returns, create a **Stock Return from Salesman** to record what came back
- There is no automatic stock balance yet — these are document records

**Try it:**
1. Select salesman
2. Add items (product, packing, qty, cost auto-fills)
3. Save → `STI-0001`

---

### Stock Return from Salesman

**What it is:** Salesman returned from his route with unsold goods.

**Tricky points:**
- Link to the original Stock Issue using Original Issue ID (optional but recommended)
- **Return All button** → loads the latest issue for this salesman and fills all items automatically
- The system checks: return qty cannot exceed what was originally issued
- Adjust quantities down if salesman only returned some items

---

### Stock Expiry Invoice

**What it is:** Goods in your warehouse have expired or got damaged. You're writing them off.

**Tricky points:**
- `Exp Qty` = quantity that expired
- `Dam Qty` = quantity that was physically damaged
- Cost fills from the product's purchase price — this is the financial impact
- Use this when the goods cannot be sold and cannot be claimed from anyone

---

### Expiry Claim From Customer

**What it is:** A customer brings back expired/damaged goods and claims credit or replacement.

**Two sections:**
1. **Claim items** — what the customer returned (at what price you sold it to them)
2. **Reply section** — how you're settling it:
   - Toggle **Return Same Products** → add replacement items
   - Or enter **Replied Amount** → you're settling with cash/credit

---

### Expiry Claim To Vendor

**What it is:** You received a customer claim for expired goods. Now you pass that claim back to your supplier.

Same screen as above but select Vendor instead of Customer.

---

### Stock Wastage Invoice

**What it is:** Stock was wasted internally — spillage, breakage, used internally. Not claimable from anyone.

---

## Part 8 — The Transactions Tab

---

### Recovery Invoice

**What it is:** Your salesman collected cash from customers today. He's back with money and a list of who paid what. This is where you record that collection.

**Tricky points:**
- Select the salesman first
- For each customer entry: pick the customer, pick which Sales Invoice they're paying against
- **Sale Value fills automatically** from the actual invoice — the system verifies this server-side so it can never be entered wrong
- `Receivable` = what was still outstanding on that invoice
- `Received` = cash the salesman actually collected
- `Discount` = any discount given to settle the account
- `Final Credit` = Received + Discount (auto-calculated)
- The system validates: Total recovered against any invoice cannot exceed the invoice value

**Try it:**
1. Select salesman
2. In the entry row: pick customer → pick Sales Invoice → enter Received → click **Add**
3. Repeat for each customer
4. Check totals at the bottom
5. Save → `REC-0001`

---

### Recovery (Invoice Wise)

**What it is:** Detailed recovery tracking — shows each customer's individual invoices so you can record payment per invoice.

**Tricky point:** The screen is blank until you click **Populate**. Choose the salesman (and optionally filter by town/sector) then click Populate — the system loads all outstanding invoices for that salesman's customers.

---

### Recovery (Receivable Wise)

**What it is:** Simpler recovery — one row per customer showing their total outstanding balance. No invoice-level breakdown.

Same process — select salesman, click **Populate**, enter received amounts.

---

### Salesman Cash Reconciliation

**What it is:** End-of-day or end-of-week settlement with your salesman. Did the money he collected match what he deposited plus what he spent?

**The formula the system calculates:**
```
Opening Balance (cash he had at start)
+ Total Cash Collected (from his Recovery Invoices)
− His Expenses (petrol, food, etc.)
− Cash He Deposited to Bank
= Closing Balance (should be in his pocket right now)
```

**Tricky points:**
- Create the Recovery Invoices for this salesman first
- Link them in the Recovery Entries section (dropdown shows `REC-0001 • SalesmanName`)
- Add expense entries with descriptions and amounts
- Enter how much he deposited to bank
- Closing Balance calculates live — if it's negative, he deposited more than expected; positive means cash still with him

**Try it:**
1. Create Recovery Invoices first
2. Select salesman, set Opening Balance
3. Add recovery entries from dropdown
4. Add expense entries
5. Enter Cash Deposited
6. Check Closing Balance makes sense
7. Save → `SCR-0001`

---

### Cash Receiving Voucher

**What it is:** A formal bookkeeping entry for money coming into the business. This is proper double-entry accounting.

**Tricky points:**
- The Voucher No (`CRV-0001`) is auto-assigned and shown in a highlighted box — read-only
- To add a line: type the account code → account name fills automatically → enter Credit amount → click **Add**
- For a cash-receiving voucher, ALL lines must be Credit (no Debit allowed)
- Use account codes from your Chart of Accounts in Settings

**Example entry:**
- Credit `1001` (Cash in Hand) → Rs 45,000 "Cash received from recovery"

---

### Cash Payment Voucher

**What it is:** Formal bookkeeping entry for money going out.

All lines must be Debit. Voucher No starts with `DBV-`.

**Example entry:**
- Debit `2001` (Accounts Payable) → Rs 200,000 "Payment to NutriPak"

---

### Journal Voucher

**What it is:** A bookkeeping adjustment — neither purely cash in nor cash out. Moves amounts between accounts.

**Critical rule:** The total of all Debit lines **must exactly equal** the total of all Credit lines. The system checks this and will not let you save if they don't balance.

Voucher No starts with `JRV-`.

**Example entry (booking salaries):**
- Debit `5002` (Salary Expense) → Rs 65,000
- Credit `1001` (Cash in Hand) → Rs 65,000

---

### Bank Cheque Issuing

**What it is:** You wrote a physical cheque from your bank account to pay someone. This records the cheque.

**Payee Type:**
- **Vendor** → paying a supplier (pick from vendor list)
- **Account** → settling with an internal GL account (pick from accounts list)
- **Other** → payee is not in your system (type their name)

**Post Dated:** Turn on if the cheque date is in the future — you want the recipient to hold it, not cash it immediately.

**Try it:**
1. Enter Cheque No (the printed number on the physical cheque)
2. Select Bank Account → Account No fills automatically
3. Select Payee Type and fill the corresponding field
4. Enter Amount
5. Save → `CHQ-0001`

---

### Bank Cheques Reconciliation

**What it is:** Your bank statement arrived. Some cheques cleared, some bounced. Update their status here.

**Tricky point:** This is a list screen — no form to fill. Press **Load** first.

1. Select bank account and date range
2. Click **Load** → all issued cheques appear
3. Per cheque:
   - **Clear** = bank honored it, money left the account
   - **Bounce** = bank returned it, cheque failed
   - **Cancel** = cheque was cancelled

---

### Cash Deposit in Bank

**What it is:** Physical cash from your drawer going into your bank account.

**Fields:** Bank Account, Deposit Slip No (from bank counter), Amount, From Account (usually Cash in Hand)

---

### Cheque Deposit in Bank

**What it is:** A cheque you received from a customer, depositing it into your bank.

**Extra fields vs cash:** Cheque No, Cheque Date, Drawer Name (customer name), Drawer Bank Name.

---

### Deposit Confirmation

**What it is:** After you've deposited and your accounts team has verified it actually went through, they confirm it here.

**Tricky point:** Press **Load** first. Only unconfirmed deposits appear.

1. Set bank account, date range, deposit type
2. Click **Load**
3. Click **Confirm** per verified deposit

---

### Deposit Reconciliation

**What it is:** Matching your system deposits to your actual bank statement line-by-line.

**Tricky point:** Press **Load** first. Enter the bank statement reference in `Stmt Ref` column, then click **Reconcile** per row.

---

### Voucher Confirmation

**What it is:** A senior/manager reviews and officially approves vouchers created by junior staff.

**Tricky point:** Press **Load** first. Expand any row to see the account lines before confirming.

---

### Post Dated Recovery Promise

**What it is:** A customer gives you a post-dated cheque. You record the promise now and process it when the date arrives.

**Tricky points:**
- Promise Date = the date written on the cheque (in the future)
- You can link the promise to specific Sales Invoices to track which invoices this cheque covers
- The footer shows the total of linked invoices vs the promise amount — so you know if it covers everything or there's a shortfall
- Processing happens later in **Promises Processing**

**Try it:**
1. Select customer and salesman
2. Set Promise Date to cheque date
3. Enter Cheque No, Bank Name, Amount
4. Optionally add the Sales Invoices this covers
5. Save → `PP-0001`

---

### Post Dated Payment Promise

**What it is:** Your promise to pay a vendor by a future date.

Same as Recovery Promise but vendor-facing. Links to Purchase Invoices.

---

### Promises Processing

**What it is:** The promise date has arrived. You present the cheque to the bank. Now update the status.

**Tricky point:** Press **Load** first. Filter by type and due date.

- **Clear** = cheque went through, payment received/sent
- **Bounce** = cheque was returned by bank
- **Cancel** = promise cancelled for any reason

---

## Part 9 — The Poultry Tab

---

### Setup (Do This First)

Before placing a flock:

1. **Feed Schedules** — create a feeding schedule with stages (Pre-Starter, Starter, Grower, Finisher). Each stage has a day range and daily feed per bird.
2. **Vaccine Schedules** — create a vaccination protocol. Each vaccination has a day number and the vaccine product.

---

### Flocks

**What it is:** A batch of birds placed in a shed. This is the core of the Poultry module.

**Tricky points:**
- `Placement Date` = the day the chicks arrived in the shed
- `Initial Birds Count` = how many chicks you received
- `Current Birds Count` = automatically updated as birds are sold or lost to mortality
- Link to Feed and Vaccine Schedules to use those protocols
- Status changes from `active` → `sold` automatically when all birds are sold

---

### Flock Feeds

**What it is:** Daily feed consumption record for a flock.

The system compares your actual feed consumed against the standard from the Feed Schedule and shows the variance. If you consumed significantly more than standard, it flags it red.

---

### Flock Vaccines

**What it is:** Records of vaccinations given to a flock.

---

### Chicken Invoices

**What it is:** Selling live chickens from a flock to a customer.

**Tricky points:**
- `Birds Count` cannot exceed `Current Birds Count` in the flock — the system blocks this
- When you save, the flock's Current Birds Count automatically decreases
- When all birds are sold, the flock status changes to `sold` automatically
- `Sale Type`: live_weight (price per kg of live bird), dressed_weight (price per kg of dressed/cleaned bird), per_bird (flat price per bird)

**Accounting Integration toggles** (new feature):
- **Create Sales Invoice** → when enabled, the system automatically creates a Sales Invoice in the Invoicing module using your configured Chicken Product. Requires Posting Config to have a Chicken Product set.
- **Post to Ledger** → when enabled, the system automatically creates accounting ledger entries (Dr Accounts Receivable, Cr Sales Revenue, and Dr Cash if advance received). Requires Posting Config to have AR and Sales Revenue accounts set.

These toggles exist both in the flock detail view and in the standalone Chicken Invoices screen.

---

## Part 10 — Tricky Business Logic to Know

### 10.1 Return Quantity Cannot Exceed Original

When creating a Sales Return (With Invoice), the system queries all previous returns for that same sales invoice and product combination. If previous returns + current return would exceed the original sale quantity, the system rejects the save with an error message.

Example: Sold 20 bags. Already returned 5 bags last week. Maximum return today = 15 bags.

### 10.2 Recovery Cannot Exceed Invoice Value

When you select a Sales Invoice in a Recovery Invoice and try to recover more than the invoice total, the system rejects it. The sale value is server-verified — the system fetches the actual invoice from the database rather than trusting whatever was displayed on screen.

### 10.3 Discount Scheme Auto-Apply

When you select a customer on the Sales Invoice screen, the system reads their Discount Scheme and auto-fills:
- Percentage discount → fills Disc2% field
- Flat discount → fills Spc Disc field

This only happens if the scheme is currently active (within Valid From / Valid To dates). If the scheme has expired, no discount is applied and you'll need to enter it manually.

### 10.4 Product Auto-Populate

When you add a line item on any invoice:
- **Sales Invoice / Sales Return** → uses the product's Sale Packing and Sale Price 1
- **Purchase Order / Purchase Invoice / Purchase Return** → uses the product's Purchase Packing and Purchase Price

The packing quantity, packing name, unit name, and tax percentage all fill automatically.

### 10.5 Total Calculation

The system calculates totals on the server after save. On screen, you see a live preview that updates as you type, but the official stored values come from the server after saving.

```
Gross = sum of all (qty × price) per line
Line Discount = line gross × (disc% / 100) per line
Invoice Discounts = gross × (Disc2% / 100) + sum of all line discounts
Invoice Value = gross − all discounts
Sales Tax = sum of (line net × tax%) per line
Net Value = invoice value + sales tax + F.Tax + Expense + SED − Spc Disc
Total Payable = net value + Prev Debit (for sales) or Prev Credit (for purchases)
Remaining Balance = Total Payable − Paid Amount
```

### 10.6 Pending vs Saved

Any document saved as **Pending** is a draft. It appears in the Pending toggle inside the Records browser. Pending documents are real records — they're saved in the database — but they're marked as incomplete. When you're ready to finalize, reopen via Records and click **Save**.

### 10.7 Stock Issue Return Quantity Check

When creating a Stock Return from Salesman linked to an original Stock Issue, the system checks that the return quantities do not exceed what was originally issued per product. You cannot return 10 bags if only 8 were issued.

### 10.8 Town and Sector Must Exist

When saving a Sales Invoice, the Town and Sector fields are validated against your Settings. If you enter a town that doesn't exist in Settings, the save will be rejected. Always set up towns and sectors in Settings before creating invoices.

---

## Part 11 — Full Workflow from Purchase to Recovery

This is the real-world sequence for a complete sale cycle:

**Day 1 — Order and Payment:**
1. Create **Purchase Order** for feed from NutriPak
2. Create **Send Purchase Order** with your bank draft details

**Day 3 — Goods Arrive:**
3. Create **Purchase Invoice** (link to PO) — goods received and billed

**Day 5 — Salesman's Route Day:**
4. Create **Stock Issue to Salesman** — give Usman 10 bags + 5 vaccine bottles
5. Create **Sales Invoice** for each customer the salesman visits
   - Customer discount auto-applies if set up
   - Mark as Pending if uncertain, finalize at end of day

**Day 5 — Salesman Returns:**
6. Create **Stock Return from Salesman** for unsold items
7. Create **Recovery Invoice** — record what cash Usman collected from each customer
8. Create **Salesman Cash Reconciliation** — balance Usman's opening cash vs collections vs expenses vs deposit

**Day 6 — Banking:**
9. Create **Cash Deposit in Bank** — deposit Usman's collected cash
10. Create **Bank Cheque Issuing** — issue cheque to NutriPak for their bill
11. Create **Cash Receiving Voucher** — formal accounting entry for cash in
12. Create **Cash Payment Voucher** — formal accounting entry for vendor payment

**Day 7 — Bank Statement:**
13. **Deposit Confirmation** — confirm yesterday's deposit went through
14. **Deposit Reconciliation** — match deposit to bank statement line
15. **Bank Cheques Reconciliation** — mark NutriPak's cheque as cleared

**Month End:**
16. **Voucher Confirmation** — manager reviews and approves all vouchers
17. **Recovery (Invoice Wise)** — detailed monthly recovery report

**When a Customer Gives a Post-Dated Cheque:**
18. Create **Post Dated Recovery Promise**
19. On the cheque date: **Promises Processing** → mark as Clear when bank honors it

---

## Part 12 — Practical Tips

- **Always create source documents first.** Send Order needs a PO. Purchase Invoice can link to a PO. Sales Return links to a Sales Invoice. Recovery Invoice links to a Sales Invoice. If the source doesn't exist yet, create it first.

- **Use Pending liberally.** There is no penalty for saving as Pending. It's a draft you can always come back to. Use it whenever you're unsure about a quantity or price.

- **Records is always your friend.** On any form screen, press Records. Type anything — a number, a name, a date — and every matching record appears. You never need to remember codes or dates.

- **Filter-table screens need Load.** Bank Cheques Reconciliation, Deposit Confirmation, Deposit Reconciliation, Voucher Confirmation, and Promises Processing will show nothing until you set filters and press Load.

- **Totals preview live.** As you type quantities and prices, the totals at the bottom update immediately. This is a preview only — the official totals are confirmed by the server after you save.

- **Discount schemes expire.** If a customer had a 5% discount scheme that expired last month and you create an invoice today, the discount will NOT auto-fill. Check the scheme's Valid To date.

- **Chicken Invoice integration needs configuration.** The Create Sales Invoice and Post to Ledger toggles on Chicken Invoices only work if you've set up Posting Config in Settings. Without it, the toggles have no effect.

- **Two ID systems exist but you only see one.** The database has internal IDs (never shown to you). The app shows only business numbers like SI-0001. You search, open, print, and reference documents by their business numbers.
