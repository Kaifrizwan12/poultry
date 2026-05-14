# Invoicing & Transactions — Plain English Guide

This is written for the farm owner, accountant, or data entry person who will actually use this app every day. No accounting jargon. No guessing.

---

## First — What Are These Two Tabs?

**Invoicing tab** = buying and selling goods. When you order feed from your supplier, when your goods arrive, when you sell to your customers, when something gets returned — all of that lives here.

**Transactions tab** = money movement and bookkeeping. When your salesman collects cash from customers, when you deposit that cash in the bank, when you issue a cheque to a vendor, when you confirm or reconcile — all of that is here.

---

## Document Numbers — The Only IDs You'll Ever See

When you save any document, the app automatically gives it a number like `SI-0001`, `PO-0002`, `REC-0005`. That number is yours. It prints on your documents. You search by it. You never need to know or type anything else.

The database has its own internal IDs but you will never see them, never need them, and never have to type them anywhere.

---

## How to Open Any Old Record

Every screen has a **Records** button at the bottom. Click it and a search box opens showing all saved records for that screen.

- Type `SI-0003` → finds that exact invoice
- Type `Al-Madina` → finds all records for that customer
- Type `2026-04` → finds all records from April 2026
- Click **Pending** toggle → shows only drafts you haven't finalized yet

Click any row → it loads into the form. Done. No need to memorize any codes.

---

## Buttons You'll See on Almost Every Screen

| Button | What it actually does |
|---|---|
| **Save** | Finalizes the document. Done. Can still be opened and edited later via Records. |
| **Pending** | Saves a rough draft. Use this when you're not sure yet and want to come back. Only some screens have this. |
| **Records** | Opens the search browser — find any saved or pending document by name, number, or date |
| **Clear** | Wipes the form clean so you can start a new one |
| **Remove** | Deletes the document that's currently loaded. Asks for confirmation first. |
| **Print** | Not ready yet |
| **Close** | Same as Clear on most screens |
| **Populate** | Used on recovery screens — click this after choosing your salesman and it pulls in the customer data automatically |
| **Load** | Used on list screens (confirmations, reconciliations) — click this after setting your filters and it shows the matching records |

---

## Field Names in Plain English

| What the app calls it | What it actually means in real life |
|---|---|
| `Entry Date` | The date you are entering this record in the system |
| `Bill Date` / `Vendor Bill No` | The date and number written on the supplier's paper invoice that came with the goods |
| `Return Date` | The date the goods were physically returned |
| `Prev Debit` | How much this customer already owed you before this sale. The app adds this to the invoice total so you know the full picture. |
| `Prev Credit` | How much you already owed this vendor before this purchase. |
| `Disc2 %` | An extra discount you want to apply to the whole invoice, on top of any per-product discounts you already gave |
| `F.Tax` / `FTax %` | Further tax that the government sometimes requires on certain goods |
| `SED` | Special Excise Duty — a specific government tax on some products |
| `Spc Disc` | A one-off special discount on the whole invoice, in rupees (not a percentage) |
| `Paid Amount` | How much the customer paid you right now at the time of this sale, or how much you paid the vendor at the time of purchase |
| `Narration` | A short note explaining the transaction — for your own reference |
| `To Main Store` | When a customer returns goods, this means the returned stock goes back into your main warehouse |
| `Post Dated` | A cheque you've written but the bank should not cash it until a future date |
| `Qty (P)` | Quantity in full packs (e.g. number of 50kg bags) |
| `Qty (L)` | Quantity in loose units that don't fill a full pack (e.g. 15 kg extra outside the bags) |

---

## Invoicing Tab — Screen by Screen

---

### 1. Purchase Order

**What is this?**
You call your feed supplier and say "I want 20 bags of Starter Feed and 15 bags of Grower." Before anything arrives or is billed, you record this intention. That's a Purchase Order — it's your official request.

**Who uses it:** The owner or purchase manager.

**When:** Before the goods have arrived. You're just placing the order.

**What happens next:** When the supplier actually delivers and sends you their bill, you create a Purchase Invoice (screen 3) and link it back to this Purchase Order.

**Key fields:**
- Vendor: which supplier are you ordering from
- Line items: which products, how many packs, at what price
- City: the vendor's city (for your records)

**Try it:**
1. Pick your feed supplier from the Vendor dropdown
2. In the line entry row, pick a product, enter Qty(P) = 20, Price = 430, click **Add**
3. Add another product the same way
4. Click **Pending** to save as a draft
5. Click **Records**, toggle Pending, tap your draft — it loads back
6. Click **Save** — you'll see an Order ID badge like `PO-0001`

---

### 2. Send Purchase Order

**What is this?**
In Pakistani trade, when you place a large order you often send a bank draft (cheque drawn on your bank) to the supplier as advance payment or security before they dispatch the goods. This screen is where you record that you've sent the order along with the payment instrument.

Think of it as: "We have a PO. Now we are officially sending it to the supplier together with our draft/LC details."

**Who uses it:** Accounts staff or owner when large orders are dispatched with advance payment.

**Who receives it:** The supplier/vendor you are ordering from.

**When:** After you've saved the Purchase Order, and when you're ready to formally dispatch it with payment details.

**Key fields:**
- Purchase Order: pick which PO you're sending (dropdown shows `PO-0001 • VendorName`)
- Draft No: the demand draft or LC number from your bank
- Draft Date: when you got the draft from the bank
- Draft Amount: how much the draft is for
- Bank Account: which of your bank accounts the draft is drawn on
- Include All Products When Printing: a print setting only

**What happens automatically:** When you select the Purchase Order, the vendor's name and all the ordered items fill in automatically. You don't need to re-enter them.

**Try it:**
1. Save a Purchase Order first (screen 1)
2. Open Send Purchase Order
3. Click the Purchase Order dropdown and pick your PO — items fill automatically
4. Fill in the draft details your bank gave you
5. Click **Save**

> There is no **Pending** button here. You either send the PO or you don't.

---

### 3. Purchase Invoice

**What is this?**
The supplier's goods have arrived. They hand you a paper bill. This is where you enter that bill into the system.

**Who uses it:** Accounts staff or data entry person.

**When:** When the supplier's truck arrives and they hand over the paper invoice along with the goods.

**Why link to the PO?**
If you made a Purchase Order for this delivery, link it here. The vendor, city, and all items will fill in automatically from the PO. You just need to verify the quantities match what actually arrived and enter the vendor's bill number and date.

**If there was no PO:** Just enter the vendor manually and type in the items. Some deliveries happen without a prior PO.

**Key fields:**
- Vendor Bill No: the invoice number printed on the supplier's paper bill (e.g. `NP-INV-78432`)
- Bill Date: the date printed on the supplier's paper bill
- Prev Credit: if the supplier already had a credit balance in their account with you
- Paid Amount: if you paid the vendor on the spot
- Disc2%, F.Tax, SED, Spc Disc: only if applicable to this specific bill

**Try it:**
1. Create a Purchase Order first if you have one
2. Open Purchase Invoice
3. Optional: pick the PO from the dropdown → vendor and items fill automatically
4. Enter the Vendor Bill No from the paper invoice
5. Set Paid Amount if you paid anything right now
6. Click **Save** — you'll see `PI-0001`

---

### 4. Purchase Return (With Invoice)

**What is this?**
You received goods from a vendor, entered a Purchase Invoice, but some goods were damaged or wrong. You want to send them back and get credit.

"With Invoice" means you're linking this return directly to a specific Purchase Invoice you already have in the system.

**Who uses it:** Accounts staff.

**When:** After a Purchase Invoice has been saved and you discover a problem with the goods.

**What happens automatically:** When you select the Purchase Invoice, the vendor and items fill in. You reduce the quantities to what you're actually returning.

**Try it:**
1. Save a Purchase Invoice first
2. Open Purchase Return (With Invoice)
3. Pick the Purchase Invoice from the dropdown
4. Adjust the quantities to what you're returning (e.g., 2 bags instead of 20)
5. Save

---

### 5. Purchase Return (Without Invoice)

**What is this?**
Same idea as above — you're returning goods to a vendor — but this time you don't have or don't want to link it to a specific previous invoice. Maybe it's old stock, maybe the original invoice wasn't in this system.

**Try it:**
1. Select the vendor
2. Manually add the return items
3. Save

---

### 6. Sales Invoice

**What is this?**
You're selling goods to a customer. A shopkeeper comes to your farm or orders from your salesman. You create this record to document the sale.

**Who uses it:** Data entry person, salesman, or owner.

**When:** When a sale happens — either at the farm gate or when your salesman returns with orders from his route.

**Key fields:**
- Customer: who are you selling to
- Town / Sector: where the customer is located
- Salesman: which of your salesmen made this sale
- Prev Debit: how much this customer already owed you before this sale. The system adds it to the total so you can see the full outstanding balance.
- Paid Amount: how much the customer paid right now (the rest becomes their balance)
- Line items: what products, how many packs, at what price

**Try it:**
1. Pick the customer
2. Pick the salesman
3. Add items in the line entry row — pick a product, enter Qty(P), click **Add**
4. Enter Paid Amount if they paid something now
5. Click **Pending** to save as a draft
6. Click **Records**, toggle Pending, tap it — loads back
7. Click **Save** → see `SI-0001` badge and the totals

---

### 7. Sales Return (With Invoice)

**What is this?**
A customer is bringing back goods they bought from you. You have the original Sales Invoice in the system. You use "With Invoice" when you know exactly which sale to link the return against.

**Who uses it:** Data entry person when a customer returns goods.

**Key fields:**
- Sales Invoice: pick which of your Sales Invoices the customer is returning from
- Full Return button: click this if the customer is returning everything from that invoice — quantities fill automatically
- To Main Store: turn this on if the returned goods go back to your main stock

**What fills automatically:** When you pick the Sales Invoice, the customer name, salesman, and original quantities appear. You can adjust quantities if it's a partial return.

**Try it:**
1. Save a Sales Invoice first
2. Open Sales Return (With Invoice)
3. Pick the Sales Invoice from the dropdown
4. If partial return: reduce the return quantities
5. If full return: click **Full Return**
6. Save

---

### 8. Sales Return (Without Invoice)

**What is this?**
A customer is returning goods but you're not linking it to a specific old invoice. Maybe the sale was done outside the system, or you just want a simple return entry.

**Try it:**
1. Select the customer and salesman
2. Add the returned products manually
3. Toggle **To Main Store** if the stock goes back
4. Save

---

### 9. Stock Issue to Salesman

**What is this?**
Your salesman is going out on his route to sell. Before he leaves, you hand over physical stock to him — bags of feed, bottles of medicine, etc. This screen records what stock you gave him.

**Who uses it:** Warehouse or store person when salesman picks up stock.

**When:** Before the salesman leaves for his route.

**Real-world example:** Usman Ghani is going to Korangi today. You give him 10 bags of Finisher Feed and 5 bottles of NDV vaccine. You enter this here.

**Key fields:**
- Salesman: who are you issuing stock to
- Items: which products, what packing, how many, at what cost (cost fills automatically from product settings)
- Value: auto-calculated = quantity × cost

**Try it:**
1. Select salesman
2. In the line entry row: pick a product, pick a packing, enter quantities, click **Add**
3. Check that cost filled automatically
4. Save → `STI-0001`

---

### 10. Stock Return from Salesman

**What is this?**
The salesman is back from his route. He sold some things, but not everything. The unsold stock comes back to your warehouse. This screen records what he returned.

**Who uses it:** Warehouse person when salesman returns.

**Key behavior:** If you know which Stock Issue this return relates to, you can link it with "Original Issue ID". There is also a **Return All** button — it fetches the most recent stock issue for this salesman and fills in all items automatically so you just reduce quantities.

**Try it:**
1. Select the salesman
2. Optionally select the original issue from the dropdown (or click Return All)
3. Adjust quantities to what actually came back
4. Save → `STR-0001`

---

### 11. Stock Expiry Invoice

**What is this?**
Some goods in your warehouse have expired or got physically damaged. They're no longer sellable. This screen is how you write them off — recording that this stock is gone.

**Who uses it:** Warehouse person or owner doing a stock check.

**Real-world example:** You find 3 bottles of vaccine that expired last month and 2 bags of feed that got wet and can't be sold. You record them here.

**Line fields:**
- Exp Qty (P/L): quantity that expired
- Dam Qty (P/L): quantity that was damaged
- Cost: auto-fills from the product's purchase price — this is the value you're writing off

**Try it:**
1. Enter date
2. Add products with their expired/damaged quantities
3. Cost fills automatically — check the netValue at the bottom
4. Save → `EXP-0001`

---

### 12. Expiry Claim From Customer

**What is this?**
A customer comes back to you saying "the vaccines you sold me have expired, I want credit or replacement." This screen handles that claim from the customer's side.

**Who uses it:** Accounts staff or owner when a customer complains about expired goods.

**Two parts:**
1. **Claim section:** what the customer is returning and claiming against (product, quantities, price)
2. **Reply section (optional):** how you're settling it — either giving them replacement products or settling with a cash amount

**Try it:**
1. Select direction: "From Customer"
2. Select the customer
3. Add the claimed items (what they returned, at what price)
4. If you're replacing the goods: toggle Return Same Products and add replacement items in the Reply section
5. If you're settling by cash: enter the amount in Replied Amount
6. Save → `EC-0001`

---

### 13. Expiry Claim To Vendor

**What is this?**
Now you've received a claim from your customer for expired goods. You go back to your supplier and make the same claim against them — "you sold me expired goods, I want credit."

Same screen as above but you select Vendor instead of Customer.

---

### 14. Stock Wastage Invoice

**What is this?**
Stock got damaged or wasted internally — not because of a customer complaint and not something you can claim back from the vendor. It's just gone. Spillage, breakage, internal usage, etc.

**Real-world example:** A bag of feed fell off the truck and split open. 2 litres of medicine were used for farm sanitization. You record this here so your stock numbers stay accurate.

Same layout as Stock Expiry. Save → `WAS-0001`

---

## Transactions Tab — Screen by Screen

---

### 1. Recovery Invoice

**What is this?**
Your salesman collected cash from customers during his route. He comes back to you with money and a list of which customers paid what. This screen is where you record that.

**Who uses it:** Salesman or accounts person when recording daily collections.

**Real-world flow:** Usman Ghani collected Rs 30,000 from Al-Madina Poultry against their Sales Invoice SI-0001, and Rs 15,000 from Bismillah Murgh against SI-0002. He also gave Bismillah a Rs 500 discount. You record all of this here in one Recovery Invoice.

**Key fields per customer row:**
- Customer: who paid
- Sale ID: which of their sales invoices they are paying against
- Sale Value: the full amount on that invoice (fills automatically when you pick the SI)
- Receivable: how much was still outstanding on that invoice
- Received: how much cash the salesman actually collected today
- Discount: any discount you agreed to give
- Final Credit: Received + Discount (auto-calculated)
- Narration: a note if needed

**Try it:**
1. Select the salesman
2. In the entry row: pick a customer, pick their Sales Invoice, enter Received amount, click **Add**
3. Repeat for each customer who paid
4. Check the totals at the bottom
5. Save → `REC-0001`

---

### 2. Recovery (Invoice Wise)

**What is this?**
Same idea as Recovery Invoice but with a more detailed breakdown. Instead of just one row per customer, this screen shows each customer's individual invoices so you can record payments against specific invoices.

**Who uses it:** Accounts person for detailed monthly recovery tracking.

**The Populate button is how you start.** Choose the salesman and click **Populate**. The system loads all customers assigned to that salesman along with their outstanding invoices. You then go through each one and enter what was received and any discounts.

**Try it:**
1. Select salesman, optionally filter by Town or Sector
2. Click **Populate** — customer rows appear with invoice sub-tables
3. For each invoice, enter Received amount and any Discount
4. Save

---

### 3. Recovery (Receivable Wise)

**What is this?**
Similar to Invoice Wise but simpler — instead of showing individual invoices, it shows one row per customer with their total outstanding balance. You record the total collected from each customer without specifying which invoice.

**Use this when:** You want a quick overview rather than an invoice-by-invoice breakdown.

**Try it:**
1. Select salesman, click **Populate**
2. For each customer row, enter how much was received
3. Save

---

### 4. Salesman Cash Reconciliation

**What is this?**
At the end of the day (or week), you sit with your salesman and reconcile his cash. He collected X amount, spent Y on expenses (petrol, food), and deposited Z in the bank. This tells you exactly what should be in his pocket right now.

**Who uses it:** Owner or accounts person at day-end or week-end.

**Closing Balance formula:**
```
Opening Balance
+ Cash collected from customers (from his Recovery Invoices)
− His expenses (petrol, meals, etc.)
− Cash he deposited to bank
= What should be in his pocket right now
```

**Sections:**
- **Opening Balance:** how much cash he had at the start
- **Recovery Entries:** link to the Recovery Invoices from this period. Dropdown shows `REC-0001 • SalesmanName`
- **Expense Entries:** petrol, tea, lunch, etc. with amounts
- **Cash Deposited:** how much he deposited in the bank
- **Closing Balance:** calculated automatically

**Try it:**
1. Create Recovery Invoices for this salesman first
2. Select salesman
3. Enter opening balance
4. Add recovery entries from the dropdown
5. Add expense entries (description + amount)
6. Enter cash deposited
7. Verify closing balance makes sense
8. Save → `SCR-0001`

---

### 5. Cash Receiving Voucher

**What is this?**
A formal accounting record of money coming in to your business. This is the proper double-entry bookkeeping record for cash received — as opposed to a Recovery Invoice which is more operational.

**Who uses it:** Accountant.

**Real-world example:** You received Rs 45,000 cash. In proper accounting you debit Cash (money came in) and credit Accounts Receivable (the customer's balance went down).

**How account entry works:**
1. Type the account code (e.g. `1001` for Cash in Hand)
2. The account name fills automatically
3. Enter the Credit amount (for a cash receiving voucher, all lines are Credit)
4. Add narration if needed
5. Click **Add**
6. Repeat for each account line

**The Voucher No** (`CRV-0001`) is auto-assigned and shown in yellow at the top. It's read-only.

**Try it:**
1. Enter today's date
2. In the line entry row: type account code → name fills → enter Credit amount → click **Add**
3. Add as many lines as needed
4. Save → `CRV-0001`

---

### 6. Cash Payment Voucher

**What is this?**
Formal record of money going out from your business. You paid a vendor, paid a salary, paid an expense. Same screen as Cash Receiving Voucher but all lines are Debit (money going out).

**Real-world example:** You paid NutriPak Rs 200,000 against their invoice. Debit Accounts Payable (vendor balance goes down), Credit Bank Account (bank balance goes down).

---

### 7. Journal Voucher

**What is this?**
A bookkeeping adjustment that isn't a simple cash-in or cash-out. You need to move amounts between accounts, book a salary expense, or make a correction.

**Real-world example:** Booking April salaries. You debit Salary Expense (Rs 65,000) and credit Cash (Rs 65,000 goes out). The debit total must exactly equal the credit total — the app checks this and won't let you save if they don't match.

---

### 8. Bank Cheque Issuing

**What is this?**
You wrote a cheque from your bank account to pay someone. This screen records the cheque details.

**Who uses it:** Owner or accounts person when issuing payment cheques.

**Payee Type — who is the cheque for:**
- **Vendor:** you're paying a supplier. Pick the vendor from the dropdown.
- **Account:** you're transferring to or settling with an internal account (e.g. director's account). Pick the account.
- **Other:** the payee is not in your system — type their name as free text.

**Post Dated:** turn this on if the cheque date is in the future and you don't want it cashed immediately.

**Try it:**
1. Enter Cheque No (the printed number on the physical cheque)
2. Enter Cheque Date
3. Select your Bank Account from the dropdown → Bank Account No fills automatically
4. Select Payee Type → fill the matching field
5. Enter Amount
6. Save → `CHQ-0001`

---

### 9. Bank Cheques Reconciliation

**What is this?**
Weeks later, you get your bank statement. Some cheques you issued have been cleared by the bank (cashed by the recipient). Some may have bounced. Some you cancelled. This screen lets you update the status of each cheque.

**Who uses it:** Accounts person during bank statement reconciliation.

**This is a list screen — there is no form to fill. Just filters and actions.**

**Try it:**
1. Select your bank account
2. Set date range to when you issued the cheques
3. Click **Load** — all issued cheques appear in a table
4. For each cheque, click:
   - **Clear** = bank honored it, money left the account
   - **Bounce** = bank returned it, payment failed
   - **Cancel** = you cancelled the cheque before it was used

---

### 10. Cash Deposit in Bank

**What is this?**
You're taking physical cash from your drawer/safe and depositing it at the bank. You fill in a deposit slip at the bank counter and record it here.

**Fields:**
- Bank Account: which of your bank accounts you're depositing into
- Deposit Slip No: the slip number the bank gives you
- Amount: how much you're depositing
- From Account: which internal account the cash is coming from (usually "Cash in Hand")

---

### 11. Cheque Deposit in Bank

**What is this?**
A customer gave you a cheque and you're depositing it in your bank account. Same as cash deposit but for a cheque, so you also need to record the cheque details.

**Extra fields:**
- Cheque No: the number on the customer's cheque
- Cheque Date: the date written on the cheque
- Drawer Name: whose cheque it is (usually the customer's name)
- Drawer Bank Name: which bank issued the cheque

---

### 12. Deposit Confirmation

**What is this?**
After your bank processes the deposit, your accounts team confirms it in the system — meaning "yes, we verified this deposit actually went through."

**This is a list screen, not a form.**

**Try it:**
1. Create some deposits first (cash or cheque)
2. Select the bank account and date range
3. Click **Load** → unconfirmed deposits appear
4. Click **Confirm** on each one that has been verified

---

### 13. Deposit Reconciliation

**What is this?**
You're looking at your bank statement. Each line on the statement has a reference number. You match each deposit in the system to a line on the bank statement. This is how you confirm the books match the bank.

**This is a list screen, not a form.**

**Try it:**
1. Confirm deposits first (screen 12)
2. Select bank account and type the year-month (e.g. `2026-04` for April 2026)
3. Click **Load** → all deposits for that month appear
4. For each deposit, type the bank statement reference in the `Stmt Ref` column
5. Click **Reconcile** for that row
6. Click **Save Changes** when done

---

### 14. Voucher Confirmation

**What is this?**
A manager or senior accounts person reviews vouchers that were entered by a junior and officially confirms them. This is a control step so that not every voucher automatically becomes final without review.

**This is a list screen, not a form.**

**Try it:**
1. Create and save some vouchers first
2. Select voucher type and date range
3. Click **Load** → unconfirmed vouchers appear
4. Click any row to expand and see the account lines
5. Click **Confirm** for each voucher you approve

---

### 15. Post Dated Recovery Promise

**What is this?**
A customer tells you "I'll pay you on May 5th — here's my cheque." The cheque date is in the future. You record this promise now so you don't forget and so you can track it.

**Who uses it:** Salesman or accounts person.

**Real-world example:** Hassan Poultry gives your salesman a cheque for Rs 92,000 dated May 5th. You record it here. On or after May 5th, you present the cheque to the bank. When it clears, you process it in Promises Processing (screen 17).

**Linked invoices section:** You can link this promise to specific Sales Invoices it's meant to cover. The footer shows the total of the linked invoices vs. the promise amount so you know if it covers everything.

**Try it:**
1. Select customer and salesman
2. Set Promise Date to when the cheque is dated
3. Enter Cheque No, Bank Name, Amount
4. Optionally: add the Sales Invoices this cheque is meant to pay
5. Save → `PP-0001`

---

### 16. Post Dated Payment Promise

**What is this?**
Your commitment to pay a vendor in the future. You tell the vendor "I'll give you a cheque for Rs 120,000 next Thursday." This records your promise.

Same screen as Recovery Promise but for vendors instead of customers. Links to Purchase Invoices instead of Sales Invoices.

---

### 17. Promises Processing

**What is this?**
The promises are due. Cheques were presented to the bank. Now you update the status of each promise.

**This is a list screen, not a form.**

**Try it:**
1. Create some promises first
2. Set Type = Recovery, set Due Date = today (or a past date), Status = Pending
3. Click **Load** → all due promises appear
4. For each one:
   - **Clear** = cheque went through, payment received
   - **Bounce** = cheque was returned by bank, payment failed
   - **Cancel** = the promise was cancelled for any reason

---

## Full Workflow — Start to Finish

If you want to test the full cycle of a sale from purchase to recovery, do it in this order:

1. **Purchase Order** — you order 20 bags of feed from your supplier
2. **Send Purchase Order** — you send the PO to the supplier with your bank draft
3. **Purchase Invoice** — goods arrive, you enter the supplier's bill
4. **Sales Invoice** — you sell feed to your customer, salesman collects partial payment
5. **Stock Issue to Salesman** — salesman takes some products out to sell on his route
6. **Recovery Invoice** — salesman comes back, you record what he collected
7. **Salesman Cash Reconciliation** — you reconcile his cash at day end
8. **Cash Receiving Voucher** — formal accounting entry for the cash received
9. **Bank Cheque Issuing** — you issue a cheque to the supplier for their payment
10. **Cash Deposit in Bank** — you deposit the collected cash
11. **Deposit Confirmation** — accounts team confirms the deposit went through
12. **Deposit Reconciliation** — you match it against your bank statement
13. **Bank Cheques Reconciliation** — supplier's cheque cleared, you mark it cleared
14. **Post Dated Recovery Promise** — customer gives you a cheque for next month
15. **Promises Processing** — next month, cheque clears, you mark it done

---

## Practical Tips

- **When a screen opens blank** — that's normal. Every screen starts fresh. Use **Records** to open existing ones.
- **The Records button is your friend** — on any form screen, click Records and search. Type the customer name, the document number, or a date. Every saved record is findable.
- **Filter-table screens need Load first** — screens like Bank Cheques Reconciliation, Deposit Confirmation, Deposit Reconciliation, Voucher Confirmation, and Promises Processing will be blank until you set filters and click **Load**.
- **Linked documents** — screens like Send Order, Purchase Invoice, Purchase Return, and Sales Return let you link to a previously saved document. When you pick that linked document from the dropdown, the relevant fields fill automatically. Always create the source document first.
- **Pending = draft** — use Pending when you're not sure yet. You can find it via Records and save it final later.
- **Totals calculate live** — as you add line items or change discount/tax fields, the totals at the bottom update immediately so you can see the effect before saving.
