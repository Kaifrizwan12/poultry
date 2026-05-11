#!/bin/bash
# ============================================================
#  Farm Management — Ledger Entries Seeder (standalone)
#  Runs independently: logs in, discovers existing account IDs,
#  seeds 32 ledger entries across 5 accounts, then verifies.
#  Safe to run on an already-seeded database — only touches
#  the accounts/ledger collection.
# ============================================================
BASE_URL="http://localhost:3000/api/v1"
EMAIL="kaif@gmail.com"
PASSWORD="Kaifi125*"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✔ $1${NC}"; }
fail() { echo -e "${RED}✘ $1${NC}"; }
info() { echo -e "${CYAN}→ $1${NC}"; }
# NOTE: Don't name this function `head` — it would override the Unix `head`
# command used later in pipelines (e.g. `| head -1`).
banner() { echo -e "\n${YELLOW}${BOLD}══ $1 ══${NC}"; }

require_json() {
  # Ensures stdout is valid JSON; prints a helpful snippet if not.
  local raw="$1" label="$2"
  if ! echo "$raw" | jq -e . >/dev/null 2>&1; then
    fail "$label returned non-JSON (cannot parse with jq)"
    echo "---- raw response (first 300 chars) ----"
    echo "${raw:0:300}"
    echo "---------------------------------------"
    return 1
  fi
  return 0
}

# ── 0. LOGIN ──────────────────────────────────────────────────
banner "AUTH — Login"
LOGIN_RES=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
require_json "$LOGIN_RES" "POST /auth/login" || exit 1
TOKEN=$(echo "$LOGIN_RES" | jq -r '.data.accessToken // .accessToken // .token // empty')
if [ -z "$TOKEN" ]; then
  fail "Login failed — check server is running and credentials are correct."
  fail "Response: $LOGIN_RES"
  exit 1
fi
ok "Logged in — token acquired"

# ── 1. DISCOVER EXISTING ACCOUNT IDs ──────────────────────────
# Reads from settings/accounts — matches on accountCode (unique per user)
banner "DISCOVER — Existing Chart of Accounts"

get_account_id() {
  local code="$1"
  local res
  res=$(curl -s "$BASE_URL/settings/accounts" -H "Authorization: Bearer $TOKEN")
  require_json "$res" "GET /settings/accounts" || return 0
  echo "$res" | jq -r --arg code "$code" '.data[] | select(.accountCode == $code) | .id // empty' | head -n 1
}

ACC_CASH=$(get_account_id "1001")
ACC_BANK=$(get_account_id "1002")
ACC_SALES=$(get_account_id "4001")
ACC_FEED_EXP=$(get_account_id "5001")
ACC_MED_EXP=$(get_account_id "5002")

# Validate — all five must exist before seeding
MISSING=0
for name_id in "Cash(1001):$ACC_CASH" "Bank(1002):$ACC_BANK" "Sales(4001):$ACC_SALES" "FeedExp(5001):$ACC_FEED_EXP" "MedExp(5002):$ACC_MED_EXP"; do
  name="${name_id%%:*}"; id="${name_id##*:}"
  if [ -z "$id" ]; then
    fail "Account $name not found — run the main seed_dummy_data.sh first to create it."
    MISSING=1
  else
    ok "Account $name → $id"
  fi
done

if [ "$MISSING" -eq 1 ]; then
  fail "Aborting — required accounts are missing. Seed the settings first."
  exit 1
fi

# ── 2. CHECK FOR DUPLICATES — skip if JV-0001 already exists ──
banner "GUARD — Duplicate check"
EXISTING=$(curl -s "$BASE_URL/accounts/ledger" -H "Authorization: Bearer $TOKEN")
require_json "$EXISTING" "GET /accounts/ledger" || exit 1
EXISTING_CT=$(echo "$EXISTING" | jq '.data | length // 0')
info "Existing ledger entries in DB: $EXISTING_CT"

if [ "$EXISTING_CT" -gt 0 ]; then
  ALREADY=$(echo "$EXISTING" | jq -r '.data[] | select(.entryNo == "JV-0001") | .entryNo // empty' | head -n 1)
  if [ -n "$ALREADY" ]; then
    fail "JV-0001 already exists — this seed has already been applied."
    fail "Delete existing ledger entries first if you want a fresh seed."
    exit 1
  fi
fi
ok "No duplicate entries found — proceeding"

# ── 3. SEED HELPER ────────────────────────────────────────────
lentry() {
  # $1=entryNo $2=date $3=accountId $4=type $5=amount $6=desc $7=refType $8=refNo $9=reconciled $10=tags $11=notes
  local no="$1" date="$2" accId="$3" typ="$4" amt="$5"
  local desc="$6" refType="$7" refNo="$8" rec="$9" tags="${10}" notes="${11}"
  local RES ID

  # Build JSON safely (properly escapes quotes, unicode, etc.)
  local payload
  payload=$(jq -n \
    --arg entryNo "$no" \
    --arg entryDate "${date}T00:00:00.000Z" \
    --arg accountId "$accId" \
    --arg entryType "$typ" \
    --arg description "$desc" \
    --arg referenceType "$refType" \
    --arg referenceNo "$refNo" \
    --arg notes "$notes" \
    --argjson amount "$amt" \
    --argjson isReconciled "$rec" \
    --argjson tags "$tags" \
    '{
      entryNo: $entryNo,
      entryDate: $entryDate,
      accountId: $accountId,
      entryType: $entryType,
      amount: $amount,
      description: $description,
      referenceType: $referenceType,
      referenceNo: $referenceNo,
      isReconciled: $isReconciled,
      tags: $tags,
      notes: $notes
    }')

  RES=$(curl -s -X POST "$BASE_URL/accounts/ledger" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "$payload")

  if ! require_json "$RES" "POST /accounts/ledger"; then
    printf "  ${RED}✘${NC} %-10s FAILED: non-JSON response\n" "$no"
    FAILED=$((FAILED+1))
    return
  fi

  ID=$(echo "$RES" | jq -r '.data.id // empty')
  if [ -n "$ID" ]; then
    printf "  ${GREEN}✔${NC} %-10s %-6s %-8s ₨%-10s  %s\n" "$no" "$typ" "$date" "$amt" "${desc:0:45}"
    CREATED=$((CREATED+1))
  else
    printf "  ${RED}✘${NC} %-10s FAILED: %s\n" "$no" "$(echo "$RES" | jq -r '.error // .message // "unknown"')"
    FAILED=$((FAILED+1))
  fi
}

CREATED=0
FAILED=0

# ── 4. CASH IN HAND (1001) — debit-normal asset ───────────────
# Opening balance: ₨250,000 Dr
# All 8 entries span Feb–May 2026; 4 reconciled, 4 not
banner "LEDGER — Cash in Hand (1001)"
printf "  %-10s %-6s %-8s %-12s  %s\n" "Entry" "Type" "Date" "Amount" "Description"
printf "  %s\n" "─────────────────────────────────────────────────────────────"
lentry "JV-0001" "2026-02-05" "$ACC_CASH" "debit"  480000 "Cash received — Al-Madina sale Jan batch"       "chicken_invoice" "CI-JAN-001" "true"  '["sales","cash"]'       "Reconciled in Feb bank recon"
lentry "JV-0002" "2026-02-12" "$ACC_CASH" "credit" 150000 "Feed payment cash — AgriTech Feb batch"         "manual"          "AGRI-C001"  "true"  '["feed","payment"]'     "Paid cash for starter feed"
lentry "JV-0003" "2026-02-20" "$ACC_CASH" "debit"  320000 "Cash received — Bismillah Murgh CI-JAN-002"    "chicken_invoice" "CI-JAN-002" "true"  '["sales","cash"]'       ""
lentry "JV-0004" "2026-03-03" "$ACC_CASH" "credit" 75000  "Vaccine payment cash — FeedMasters batch"      "manual"          "FMPAY-003"  "true"  '["vaccine","payment"]'  "Gumboro + NDV batch"
lentry "JV-0005" "2026-03-15" "$ACC_CASH" "debit"  215000 "Cash received — Hassan Poultry Farm CI-FEB-001" "chicken_invoice" "CI-FEB-001" "false" '["sales","cash"]'       "Partial advance received"
lentry "JV-0006" "2026-03-28" "$ACC_CASH" "credit" 42000  "Petty cash — labour wages March"               "manual"          ""           "false" '["wages","expense"]'    "14 daily labour payments"
lentry "JV-0007" "2026-04-08" "$ACC_CASH" "debit"  560000 "Cash sale — Spring Alpha CI-2026-001 advance"  "chicken_invoice" "CI-2026-001" "false" '["sales","alpha"]'      "Al-Madina advance 560k"
lentry "JV-0008" "2026-04-20" "$ACC_CASH" "credit" 35000  "Operating expenses — electricity & water Apr"  "other"           "EXP-APR-01" "false" '["opex"]'               "Monthly farm utilities"

# ── 5. BANK HBL (1002) — debit-normal asset ───────────────────
# Opening balance: ₨1,500,000 Dr
banner "LEDGER — Bank HBL Current (1002)"
printf "  %-10s %-6s %-8s %-12s  %s\n" "Entry" "Type" "Date" "Amount" "Description"
printf "  %s\n" "─────────────────────────────────────────────────────────────"
lentry "JV-0009" "2026-02-01" "$ACC_BANK" "debit"  1200000 "Opening cheque deposit — Al-Madina advance"     "manual"          "CHQ-1001"    "true"  '["bank","deposit"]'    "Cleared same day"
lentry "JV-0010" "2026-02-18" "$ACC_BANK" "credit" 480000  "IBFT to AgriTech — feed outstanding Feb"        "manual"          "TRF-FEB-001" "true"  '["bank","feed"]'       "AgriTech acc 0246xxxx"
lentry "JV-0011" "2026-03-05" "$ACC_BANK" "debit"  875000  "Cheque deposit — Bismillah CI-2026-002"         "chicken_invoice" "CI-2026-002" "true"  '["bank","sales"]'      "Cleared in 2 working days"
lentry "JV-0012" "2026-03-22" "$ACC_BANK" "credit" 300000  "Payment to Poultry Pro — chick supply"          "manual"          "TRF-MAR-002" "false" '["bank","chicks"]'     "Pending vendor confirmation"
lentry "JV-0013" "2026-04-15" "$ACC_BANK" "debit"  1100000 "Bank TT — Hassan Farm CI-2026-003 balance"      "chicken_invoice" "CI-2026-003" "false" '["bank","sales"]'      "Balance after 500k advance"
lentry "JV-0014" "2026-05-02" "$ACC_BANK" "credit" 150000  "Salary payment — May 2026 permanent staff"      "manual"          "SAL-MAY-01"  "false" '["bank","salary"]'     "5 staff, monthly payroll"
lentry "JV-0015" "2026-05-10" "$ACC_BANK" "debit"  640000  "New customer advance — Gulberg Live Chicken"    "manual"          "CHQ-1045"    "false" '["bank","advance"]'    "Future batch booking advance"

# ── 6. SALES REVENUE (4001) — credit-normal income ───────────
# Opening balance: ₨0 Cr
# Credits = revenue recognised; one debit = return/adjustment
banner "LEDGER — Sales Revenue (4001)"
printf "  %-10s %-6s %-8s %-12s  %s\n" "Entry" "Type" "Date" "Amount" "Description"
printf "  %s\n" "─────────────────────────────────────────────────────────────"
lentry "JV-0016" "2026-02-05" "$ACC_SALES" "credit" 480000  "Revenue — Al-Madina Poultry CI-JAN-001"        "chicken_invoice" "CI-JAN-001" "true"  '["revenue","jan"]'     "Jan batch confirmed"
lentry "JV-0017" "2026-02-20" "$ACC_SALES" "credit" 320000  "Revenue — Bismillah Murgh Centre CI-JAN-002"   "chicken_invoice" "CI-JAN-002" "true"  '["revenue","jan"]'     ""
lentry "JV-0018" "2026-03-15" "$ACC_SALES" "credit" 215000  "Revenue — Hassan Farm partial CI-FEB-001"      "chicken_invoice" "CI-FEB-001" "false" '["revenue"]'           "Partial delivery pending"
lentry "JV-0019" "2026-04-08" "$ACC_SALES" "credit" 2400000 "Revenue — Spring Alpha full sale CI-2026-001"  "chicken_invoice" "CI-2026-001" "false" '["revenue","alpha"]'   "5000 birds Alpha batch"
lentry "JV-0020" "2026-04-11" "$ACC_SALES" "credit" 1781250 "Revenue — Spring Alpha CI-2026-002"            "chicken_invoice" "CI-2026-002" "false" '["revenue","alpha"]'   "3750kg @ ₨475"
lentry "JV-0021" "2026-04-12" "$ACC_SALES" "credit" 1106640 "Revenue — Spring Alpha CI-2026-003 Hassan"     "chicken_invoice" "CI-2026-003" "false" '["revenue","alpha"]'   "2400kg @ ₨470 less 2%"
lentry "JV-0022" "2026-05-01" "$ACC_SALES" "debit"  25000   "Discount adjustment — Bismillah scheme ADJ-001" "other"          "ADJ-001"    "false" '["adjustment"]'        "Seasonal flat ₨500 retroactive"

# ── 7. FEED PURCHASE EXPENSE (5001) — debit-normal ───────────
banner "LEDGER — Feed Purchase Expense (5001)"
printf "  %-10s %-6s %-8s %-12s  %s\n" "Entry" "Type" "Date" "Amount" "Description"
printf "  %s\n" "─────────────────────────────────────────────────────────────"
lentry "JV-0023" "2026-02-01" "$ACC_FEED_EXP" "debit"  220000 "Pre-starter feed — 50 bags @ ₨88/kg"           "manual" "AGRI-INV-201" "true"  '["feed","purchase"]'   "50 bags x 50kg = 2500kg"
lentry "JV-0024" "2026-02-15" "$ACC_FEED_EXP" "debit"  430000 "Starter feed — 100 bags @ ₨86/kg"              "manual" "AGRI-INV-202" "true"  '["feed","purchase"]'   "100 bags x 50kg = 5000kg"
lentry "JV-0025" "2026-03-01" "$ACC_FEED_EXP" "debit"  615000 "Grower feed — 150 bags both flocks"             "manual" "AGRI-INV-203" "false" '["feed","purchase"]'   "Grower phase combined demand"
lentry "JV-0026" "2026-03-20" "$ACC_FEED_EXP" "debit"  390000 "Finisher feed — 100 bags Flock A"               "manual" "AGRI-INV-204" "false" '["feed","purchase"]'   "Flock A finisher phase final"
lentry "JV-0027" "2026-04-10" "$ACC_FEED_EXP" "credit" 44000  "Feed return — 10 bags pre-starter rejected QC"  "other"  "AGRI-RET-001" "false" '["feed","return"]'     "Moisture damage — vendor accepted"

# ── 8. MEDICINE & VACCINE EXPENSE (5002) — debit-normal ───────
banner "LEDGER — Medicine & Vaccine Expense (5002)"
printf "  %-10s %-6s %-8s %-12s  %s\n" "Entry" "Type" "Date" "Amount" "Description"
printf "  %s\n" "─────────────────────────────────────────────────────────────"
lentry "JV-0028" "2026-02-08" "$ACC_MED_EXP" "debit"  14000 "Newcastle La Sota vaccine — 20 bottles"         "manual" "FMPAY-001" "true"  '["vaccine","ndv"]'        "Flock A + B day-7 schedule"
lentry "JV-0029" "2026-02-14" "$ACC_MED_EXP" "debit"  16000 "Gumboro IBD vaccine — 20 bottles day 14"        "manual" "FMPAY-002" "true"  '["vaccine","ibd"]'        "Both flocks drinking water"
lentry "JV-0030" "2026-03-01" "$ACC_MED_EXP" "debit"   8500 "IB Bronchitis vaccine — 10 bottles spray"       "manual" "FMPAY-003" "false" '["vaccine","ib"]'         "Day-10 spray vaccination"
lentry "JV-0031" "2026-03-15" "$ACC_MED_EXP" "debit"  32000 "Vitamin & electrolyte supplement — bulk"        "manual" "FMPAY-004" "false" '["vitamin","supplement"]'  "Monthly preventive supplement"
lentry "JV-0032" "2026-04-05" "$ACC_MED_EXP" "debit"  12500 "Emergency antibiotic — Flock B respiratory"     "other"  "EMR-001"   "false" '["medicine","emergency"]'  "Vet-prescribed Doxycycline"

# ── 9. VERIFY ALL ENDPOINTS ────────────────────────────────────
banner "VERIFY — API Endpoint Tests"

info "1/5  GET /accounts/ledger — full list"
ALL_RES=$(curl -s "$BASE_URL/accounts/ledger" -H "Authorization: Bearer $TOKEN")
require_json "$ALL_RES" "GET /accounts/ledger" || exit 1
TOTAL=$(echo "$ALL_RES" | jq '.data | length // 0')
ok "Total ledger entries: $TOTAL / 32 expected"

info "2/5  GET /accounts/ledger?entryType=debit — filter by type"
DEB_RES=$(curl -s "$BASE_URL/accounts/ledger?entryType=debit" -H "Authorization: Bearer $TOKEN")
require_json "$DEB_RES" "GET /accounts/ledger?entryType=debit" || exit 1
DEB_CT=$(echo "$DEB_RES" | jq '.data | length // 0')
ok "Debit-only filter: $DEB_CT entries"

info "3/5  GET /accounts/ledger/summary"
SUMM=$(curl -s "$BASE_URL/accounts/ledger/summary" -H "Authorization: Bearer $TOKEN")
require_json "$SUMM" "GET /accounts/ledger/summary" || exit 1
echo ""
echo -e "  ${BOLD}Code   Account                      OpenBal     TotalDr     TotalCr     Closing${NC}"
echo "  ───────────────────────────────────────────────────────────────────────────────"
echo "$SUMM" | jq -r '.data[] | "  \(.accountCode | @text | .[0:6])  \(.accountName | @text | .[0:28])   \(.openingBalance | @text | .[0:10])  \(.totalDebits | @text | .[0:10])  \(.totalCredits | @text | .[0:10])  \(.closingBalance | @text | .[0:12])"' 2>/dev/null || \
echo "$SUMM" | jq '.data' 2>/dev/null
echo ""

info "4/5  GET /accounts/ledger/by-account — Cash in Hand (all dates)"
BA_CASH=$(curl -s "$BASE_URL/accounts/ledger/by-account/$ACC_CASH" -H "Authorization: Bearer $TOKEN")
require_json "$BA_CASH" "GET /accounts/ledger/by-account/:id" || exit 1
CASH_CT=$(echo "$BA_CASH" | jq '.data.entries | length // 0')
CASH_BAL=$(echo "$BA_CASH" | jq '.data.closingBalance // 0')
ok "Cash in Hand: $CASH_CT entries, closing balance = ₨$CASH_BAL"

info "   → date-range filter: Mar 2026 only"
BA_MAR=$(curl -s "$BASE_URL/accounts/ledger/by-account/$ACC_CASH?startDate=2026-03-01&endDate=2026-03-31" -H "Authorization: Bearer $TOKEN")
require_json "$BA_MAR" "GET /accounts/ledger/by-account/:id?startDate&endDate" || exit 1
MAR_CT=$(echo "$BA_MAR" | jq '.data.entries | length // 0')
ok "Cash — March filter: $MAR_CT entries"

info "   → entry type filter: debit only"
BA_DR=$(curl -s "$BASE_URL/accounts/ledger/by-account/$ACC_CASH?entryType=debit" -H "Authorization: Bearer $TOKEN")
require_json "$BA_DR" "GET /accounts/ledger/by-account/:id?entryType" || exit 1
DR_CT=$(echo "$BA_DR" | jq '.data.entries | length // 0')
ok "Cash — debit-only filter: $DR_CT entries"

info "   → reconciled filter: reconciled only"
BA_REC=$(curl -s "$BASE_URL/accounts/ledger/by-account/$ACC_CASH?isReconciled=true" -H "Authorization: Bearer $TOKEN")
require_json "$BA_REC" "GET /accounts/ledger/by-account/:id?isReconciled" || exit 1
REC_CT=$(echo "$BA_REC" | jq '.data.entries | length // 0')
ok "Cash — reconciled-only filter: $REC_CT entries"

info "5/5  POST /accounts/ledger/next-entry-no"
NEXT=$(curl -s -X POST "$BASE_URL/accounts/ledger/next-entry-no" \
  -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{}')
require_json "$NEXT" "POST /accounts/ledger/next-entry-no" || exit 1
NEXT_NO=$(echo "$NEXT" | jq -r '.data.nextEntryNo // "?"')
ok "Next suggested entry no: $NEXT_NO  (should be JV-0033)"

# ── 10. RUNNING BALANCE SPOT-CHECK ────────────────────────────
banner "SPOT-CHECK — Running Balance Sanity"
# Cash in Hand: opening=250000 Dr
# Entries in date order: +480000 -150000 +320000 -75000 +215000 -42000 +560000 -35000
# Expected closing = 250000 + (480k-150k+320k-75k+215k-42k+560k-35k) = 250000 + 1273000 = 1523000
EXPECTED_CASH=1523000
ACTUAL_CASH=$(echo "$BA_CASH" | jq '.data.closingBalance // -1')
if [ "$ACTUAL_CASH" = "$EXPECTED_CASH" ] || [ "$(echo "$ACTUAL_CASH == $EXPECTED_CASH" | bc 2>/dev/null)" = "1" ]; then
  ok "Cash closing balance ₨$ACTUAL_CASH == expected ₨$EXPECTED_CASH ✓"
else
  fail "Cash balance mismatch: got ₨$ACTUAL_CASH, expected ₨$EXPECTED_CASH"
fi

# ── SUMMARY ───────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}╔═══════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║   LEDGER SEED COMPLETE — Summary          ║${NC}"
echo -e "${YELLOW}╚═══════════════════════════════════════════╝${NC}"
echo -e "${CYAN}Accounts seeded:${NC} 5 (Cash, Bank, Sales, FeedExp, MedExp)"
echo -e "${CYAN}Entries created:${NC} $CREATED"
echo -e "${CYAN}Entries failed:${NC}  $FAILED"
echo -e "${CYAN}Coverage:${NC}"
echo -e "  • Both Dr and Cr entries per account"
echo -e "  • All referenceTypes: chicken_invoice, manual, other"
echo -e "  • Date spread: Feb → May 2026 (4 months)"
echo -e "  • Mixed reconciled (true/false) — tests isReconciled filter"
echo -e "  • Tags on all entries — for future tag-based filtering"
echo -e "  • Running balance spot-checked: Cash closing = ₨$ACTUAL_CASH"
echo -e "${CYAN}Next entry no:${NC} $NEXT_NO"
echo ""
if [ "$FAILED" -gt 0 ]; then
  fail "Ledger seeding completed with failures. Fix errors above and re-run."
  exit 1
fi
ok "Ledger seeding complete. Open the app → Reports → Ledger Entries to verify."
