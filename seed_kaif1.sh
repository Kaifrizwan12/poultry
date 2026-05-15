#!/bin/bash
# ============================================================
#  Farm Management System — Comprehensive Seed (kaif1@gmail.com)
#  Covers: Settings → Poultry → Invoicing (all 31 screens) → Accounts
#  Run with server on http://localhost:3000
# ============================================================
set -uo pipefail

BASE_URL="http://localhost:3000/api/v1"
EMAIL="${SEED_EMAIL:-kaka@gmail.com}"
PASSWORD="${SEED_PASSWORD:-Kaka125*}"
TODAY=$(date +%Y-%m-%d)

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
ok()     { echo -e "${GREEN}  ✔  $1${NC}" >&2; }
fail()   { echo -e "${RED}  ✘  $1${NC}" >&2; }
info()   { echo -e "${CYAN}  →  $1${NC}" >&2; }
banner() { echo -e "\n${YELLOW}${BOLD}══════  $1  ══════${NC}" >&2; }
skip()   { echo -e "  ·  $1 (skipped — empty ID)" >&2; }

# ── helpers ───────────────────────────────────────────────────────────────────
post() { curl -s -X POST "$BASE_URL$1" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "$2"; }

patch_req() { curl -s -X PATCH "$BASE_URL$1" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "$2"; }

id_of() { echo "$1" | jq -r '.data.id // .id // empty'; }

check() {
  local res="$1" label="$2"
  local id; id=$(id_of "$res")
  if [ -z "$id" ]; then
    fail "$label  ← $(echo "$res" | jq -r '.error // .message // "unknown error"' 2>/dev/null)"
  else
    ok "$label → $id"
  fi
  echo "$id"
}

# ── 0. REGISTER (first run only) ─────────────────────────────────────────────
banner "0. AUTH — Register + Login"

REG=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"farmType\":\"Poultry\"}")
if echo "$REG" | jq -e '.data.uid // .uid' >/dev/null 2>&1; then
  ok "Registered new user $EMAIL"
else
  info "Register skipped (user may already exist): $(echo "$REG" | jq -r '.error // empty' 2>/dev/null)"
fi

LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
TOKEN=$(echo "$LOGIN" | jq -r '.token // .data.accessToken // .accessToken // empty')
[ -z "$TOKEN" ] && { fail "Login failed: $LOGIN"; exit 1; }
ok "Logged in — token acquired"

# ═══════════════════════════════════════════════════════════════════════════════
banner "1. SETTINGS — Units"
# ═══════════════════════════════════════════════════════════════════════════════
R=$(post "/settings/units" '{"name":"Kilogram","abbreviation":"kg","description":"Weight"}')
UNIT_KG=$(check "$R" "Unit: Kilogram")

R=$(post "/settings/units" '{"name":"Piece","abbreviation":"pcs","description":"Per piece count"}')
UNIT_PCS=$(check "$R" "Unit: Piece")

R=$(post "/settings/units" '{"name":"Gram","abbreviation":"g","description":"Weight in grams"}')
UNIT_G=$(check "$R" "Unit: Gram")

R=$(post "/settings/units" '{"name":"Litre","abbreviation":"L","description":"Volume in litres"}')
UNIT_L=$(check "$R" "Unit: Litre")

R=$(post "/settings/units" '{"name":"Dozen","abbreviation":"dz","description":"12 units"}')
UNIT_DZ=$(check "$R" "Unit: Dozen")

# ═══════════════════════════════════════════════════════════════════════════════
banner "2. SETTINGS — Packings"
# ═══════════════════════════════════════════════════════════════════════════════
R=$(post "/settings/packings" "{\"name\":\"50kg Bag\",\"unitId\":\"$UNIT_KG\",\"quantity\":50,\"description\":\"50 kg feed bag — purchase packing\"}")
PACK_50KG=$(check "$R" "Packing: 50kg Bag")

R=$(post "/settings/packings" "{\"name\":\"5kg Bag\",\"unitId\":\"$UNIT_KG\",\"quantity\":5,\"description\":\"5 kg retail feed bag — sale packing\"}")
PACK_5KG=$(check "$R" "Packing: 5kg Bag")

R=$(post "/settings/packings" "{\"name\":\"25kg Bag\",\"unitId\":\"$UNIT_KG\",\"quantity\":25,\"description\":\"25 kg half-bag\"}")
PACK_25KG=$(check "$R" "Packing: 25kg Bag")

R=$(post "/settings/packings" "{\"name\":\"1L Bottle\",\"unitId\":\"$UNIT_L\",\"quantity\":1,\"description\":\"1 litre vaccine purchase bottle\"}")
PACK_1L=$(check "$R" "Packing: 1L Bottle")

R=$(post "/settings/packings" "{\"name\":\"500ml Bottle\",\"unitId\":\"$UNIT_L\",\"quantity\":0.5,\"description\":\"500 ml vaccine sale bottle\"}")
PACK_500ML=$(check "$R" "Packing: 500ml Bottle")

R=$(post "/settings/packings" "{\"name\":\"Carton/24\",\"unitId\":\"$UNIT_PCS\",\"quantity\":24,\"description\":\"Carton of 24 pieces\"}")
PACK_CTN=$(check "$R" "Packing: Carton/24")

# ═══════════════════════════════════════════════════════════════════════════════
banner "3. SETTINGS — Companies"
# ═══════════════════════════════════════════════════════════════════════════════
R=$(post "/settings/companies" '{"name":"AgriCore Supplies Ltd","address":"Plot 14, SITE Area, Karachi","phone":"021-32570001","email":"info@agricore.pk","ntn":"1234567-8","strn":"12-34-5678-001-00","contactPerson":"Mr. Saleem Ahmed","notes":"Primary feed & medicine supplier"}')
COMP_AGRI=$(check "$R" "Company: AgriCore Supplies")

R=$(post "/settings/companies" '{"name":"NutriPak Feeds","address":"G-10, Hyderabad Industrial Estate","phone":"022-2678900","email":"orders@nutripak.pk","ntn":"9876543-1","contactPerson":"Mrs. Nadia Khan","notes":"Specialist feed manufacturer"}')
COMP_NUTRI=$(check "$R" "Company: NutriPak Feeds")

R=$(post "/settings/companies" '{"name":"ZamZam Chick Hatchery","address":"Canal Road, Faisalabad","phone":"041-8720000","email":"sales@zamzam.pk","contactPerson":"Mr. Tariq Mehmood","notes":"Day-old chick hatchery"}')
COMP_ZAM=$(check "$R" "Company: ZamZam Hatchery")

# ═══════════════════════════════════════════════════════════════════════════════
banner "4. SETTINGS — Product Groups"
# ═══════════════════════════════════════════════════════════════════════════════
R=$(post "/settings/product-groups" '{"name":"Poultry Feed","description":"Broiler and layer feeds"}')
PG_FEED=$(check "$R" "ProductGroup: Poultry Feed")

R=$(post "/settings/product-groups" '{"name":"Vaccines & Medicines","description":"Poultry vaccines and veterinary medicines"}')
PG_VAX=$(check "$R" "ProductGroup: Vaccines & Medicines")

R=$(post "/settings/product-groups" '{"name":"General Merchandise","description":"Equipment, consumables, general goods"}')
PG_MERCH=$(check "$R" "ProductGroup: General Merchandise")

# ═══════════════════════════════════════════════════════════════════════════════
banner "5. SETTINGS — Product Sub-Groups"
# ═══════════════════════════════════════════════════════════════════════════════
R=$(post "/settings/product-sub-groups" "{\"name\":\"Broiler Feed\",\"groupId\":\"$PG_FEED\",\"description\":\"Broiler-specific feed formulations\"}")
PSG_BROILER=$(check "$R" "SubGroup: Broiler Feed")

R=$(post "/settings/product-sub-groups" "{\"name\":\"Layer Feed\",\"groupId\":\"$PG_FEED\",\"description\":\"Layer-specific feed formulations\"}")
PSG_LAYER=$(check "$R" "SubGroup: Layer Feed")

R=$(post "/settings/product-sub-groups" "{\"name\":\"Live Vaccines\",\"groupId\":\"$PG_VAX\",\"description\":\"Live attenuated vaccines\"}")
PSG_LIVEVAX=$(check "$R" "SubGroup: Live Vaccines")

R=$(post "/settings/product-sub-groups" "{\"name\":\"Medicines\",\"groupId\":\"$PG_VAX\",\"description\":\"Veterinary medicines and supplements\"}")
PSG_MED=$(check "$R" "SubGroup: Medicines")

R=$(post "/settings/product-sub-groups" "{\"name\":\"Miscellaneous\",\"groupId\":\"$PG_MERCH\",\"description\":\"Miscellaneous farm goods\"}")
PSG_MISC=$(check "$R" "SubGroup: Miscellaneous")

# ═══════════════════════════════════════════════════════════════════════════════
banner "6. SETTINGS — Products  (new schema: purPackingId, salePackingId, sale1Price)"
# ═══════════════════════════════════════════════════════════════════════════════
# Feed products — purPackingId=50kg, salePackingId=5kg, salesTaxPercent=0
R=$(post "/settings/products" "{
  \"name\":\"Broiler Pre-Starter Feed\",\"code\":\"BPSF-001\",
  \"groupId\":\"$PG_FEED\",\"subGroupId\":\"$PSG_BROILER\",\"unitId\":\"$UNIT_KG\",\"companyId\":\"$COMP_NUTRI\",
  \"purPackingId\":\"$PACK_50KG\",\"salePackingId\":\"$PACK_5KG\",
  \"purchasePrice\":450,\"purchaseDiscPercent\":2,
  \"sale1Price\":480,\"sale1DiscPercent\":0,
  \"sale2Price\":475,\"sale2DiscPercent\":0,
  \"sale3Price\":470,\"sale3DiscPercent\":2,
  \"salesTaxPercent\":0,\"sedValue\":0,\"retailPrice\":500,
  \"size\":50,\"displayOrder\":1,
  \"isPoultryItem\":true,\"isActive\":true,
  \"description\":\"High-protein pre-starter crumble (0-7 days)\"}")
PROD_PRESTARTER=$(check "$R" "Product: Pre-Starter Feed")

R=$(post "/settings/products" "{
  \"name\":\"Broiler Starter Feed\",\"code\":\"BSF-002\",
  \"groupId\":\"$PG_FEED\",\"subGroupId\":\"$PSG_BROILER\",\"unitId\":\"$UNIT_KG\",\"companyId\":\"$COMP_NUTRI\",
  \"purPackingId\":\"$PACK_50KG\",\"salePackingId\":\"$PACK_5KG\",
  \"purchasePrice\":430,\"purchaseDiscPercent\":2,
  \"sale1Price\":460,\"sale1DiscPercent\":0,
  \"sale2Price\":455,\"sale2DiscPercent\":0,
  \"sale3Price\":450,\"sale3DiscPercent\":2,
  \"salesTaxPercent\":0,\"sedValue\":0,\"retailPrice\":480,
  \"size\":50,\"displayOrder\":2,
  \"isPoultryItem\":true,\"isActive\":true,
  \"description\":\"Starter crumble (7-21 days)\"}")
PROD_STARTER=$(check "$R" "Product: Starter Feed")

R=$(post "/settings/products" "{
  \"name\":\"Broiler Grower Feed\",\"code\":\"BGF-003\",
  \"groupId\":\"$PG_FEED\",\"subGroupId\":\"$PSG_BROILER\",\"unitId\":\"$UNIT_KG\",\"companyId\":\"$COMP_NUTRI\",
  \"purPackingId\":\"$PACK_50KG\",\"salePackingId\":\"$PACK_5KG\",
  \"purchasePrice\":415,\"purchaseDiscPercent\":2,
  \"sale1Price\":455,\"sale1DiscPercent\":0,
  \"sale2Price\":450,\"sale2DiscPercent\":0,
  \"sale3Price\":445,\"sale3DiscPercent\":2,
  \"salesTaxPercent\":0,\"sedValue\":0,\"retailPrice\":470,
  \"size\":50,\"displayOrder\":3,
  \"isPoultryItem\":true,\"isActive\":true,
  \"description\":\"Grower pellet (21-35 days)\"}")
PROD_GROWER=$(check "$R" "Product: Grower Feed")

R=$(post "/settings/products" "{
  \"name\":\"Broiler Finisher Feed\",\"code\":\"BFF-004\",
  \"groupId\":\"$PG_FEED\",\"subGroupId\":\"$PSG_BROILER\",\"unitId\":\"$UNIT_KG\",\"companyId\":\"$COMP_NUTRI\",
  \"purPackingId\":\"$PACK_50KG\",\"salePackingId\":\"$PACK_5KG\",
  \"purchasePrice\":400,\"purchaseDiscPercent\":2,
  \"sale1Price\":435,\"sale1DiscPercent\":0,
  \"sale2Price\":430,\"sale2DiscPercent\":0,
  \"sale3Price\":425,\"sale3DiscPercent\":2,
  \"salesTaxPercent\":0,\"sedValue\":0,\"retailPrice\":450,
  \"size\":50,\"displayOrder\":4,
  \"isPoultryItem\":true,\"isActive\":true,
  \"description\":\"Finisher pellet (35+ days)\"}")
PROD_FINISHER=$(check "$R" "Product: Finisher Feed")

# Vaccine products — purPackingId=1L, salePackingId=500ml, salesTaxPercent=17
R=$(post "/settings/products" "{
  \"name\":\"Newcastle Disease Vaccine (La Sota)\",\"code\":\"NDV-001\",
  \"groupId\":\"$PG_VAX\",\"subGroupId\":\"$PSG_LIVEVAX\",\"unitId\":\"$UNIT_L\",\"companyId\":\"$COMP_AGRI\",
  \"purPackingId\":\"$PACK_1L\",\"salePackingId\":\"$PACK_500ML\",
  \"purchasePrice\":700,\"purchaseDiscPercent\":0,
  \"sale1Price\":850,\"sale1DiscPercent\":0,
  \"sale2Price\":840,\"sale2DiscPercent\":0,
  \"sale3Price\":830,\"sale3DiscPercent\":0,
  \"salesTaxPercent\":17,\"sedValue\":0,\"retailPrice\":900,
  \"size\":1,\"displayOrder\":10,
  \"isPoultryItem\":true,\"isActive\":true,
  \"description\":\"La Sota strain, 1000 dose/bottle\"}")
PROD_NDV=$(check "$R" "Product: NDV Vaccine")

R=$(post "/settings/products" "{
  \"name\":\"Gumboro IBD Vaccine\",\"code\":\"IBD-001\",
  \"groupId\":\"$PG_VAX\",\"subGroupId\":\"$PSG_LIVEVAX\",\"unitId\":\"$UNIT_L\",\"companyId\":\"$COMP_AGRI\",
  \"purPackingId\":\"$PACK_1L\",\"salePackingId\":\"$PACK_500ML\",
  \"purchasePrice\":800,\"purchaseDiscPercent\":0,
  \"sale1Price\":950,\"sale1DiscPercent\":0,
  \"sale2Price\":940,\"sale2DiscPercent\":0,
  \"sale3Price\":930,\"sale3DiscPercent\":0,
  \"salesTaxPercent\":17,\"sedValue\":0,\"retailPrice\":1000,
  \"size\":1,\"displayOrder\":11,
  \"isPoultryItem\":true,\"isActive\":true,
  \"description\":\"IBD live vaccine, 1000 dose/bottle\"}")
PROD_IBD=$(check "$R" "Product: IBD Vaccine")

R=$(post "/settings/products" "{
  \"name\":\"Vitamin-E & Electrolyte Supplement\",\"code\":\"VES-001\",
  \"groupId\":\"$PG_VAX\",\"subGroupId\":\"$PSG_MED\",\"unitId\":\"$UNIT_KG\",\"companyId\":\"$COMP_AGRI\",
  \"purPackingId\":\"$PACK_25KG\",\"salePackingId\":\"$PACK_25KG\",
  \"purchasePrice\":2800,\"purchaseDiscPercent\":0,
  \"sale1Price\":3200,\"sale1DiscPercent\":0,
  \"sale2Price\":3100,\"sale2DiscPercent\":0,
  \"sale3Price\":3000,\"sale3DiscPercent\":0,
  \"salesTaxPercent\":0,\"sedValue\":0,\"retailPrice\":3500,
  \"size\":25,\"displayOrder\":20,
  \"isPoultryItem\":true,\"isActive\":true,
  \"description\":\"Multi-vitamin electrolyte powder\"}")
PROD_VIT=$(check "$R" "Product: Vit-E Supplement")

R=$(post "/settings/products" "{
  \"name\":\"Disinfectant Spray (1L)\",\"code\":\"DIS-001\",
  \"groupId\":\"$PG_MERCH\",\"subGroupId\":\"$PSG_MISC\",\"unitId\":\"$UNIT_L\",\"companyId\":\"$COMP_AGRI\",
  \"purPackingId\":\"$PACK_1L\",\"salePackingId\":\"$PACK_1L\",
  \"purchasePrice\":380,\"purchaseDiscPercent\":0,
  \"sale1Price\":450,\"sale1DiscPercent\":0,
  \"sale2Price\":440,\"sale2DiscPercent\":0,
  \"sale3Price\":430,\"sale3DiscPercent\":0,
  \"salesTaxPercent\":17,\"sedValue\":0,\"retailPrice\":480,
  \"size\":1,\"displayOrder\":30,
  \"isPoultryItem\":false,\"isActive\":true,
  \"description\":\"Broad-spectrum poultry shed disinfectant\"}")
PROD_DISINFECT=$(check "$R" "Product: Disinfectant Spray")

# ═══════════════════════════════════════════════════════════════════════════════
banner "7. SETTINGS — Discount Schemes"
# ═══════════════════════════════════════════════════════════════════════════════
R=$(post "/settings/discount-schemes" '{"name":"Bulk Buyer 5%","type":"percentage","value":5,"applicableTo":"all","validFrom":"2026-01-01","validTo":"2026-12-31","notes":"5% off for bulk buyers"}')
DS_BULK=$(check "$R" "DiscountScheme: Bulk 5%")

R=$(post "/settings/discount-schemes" '{"name":"Seasonal Flat 500","type":"flat","value":500,"applicableTo":"all","validFrom":"2026-04-01","validTo":"2026-06-30","notes":"Rs 500 flat off per invoice"}')
DS_FLAT=$(check "$R" "DiscountScheme: Flat 500")

# ═══════════════════════════════════════════════════════════════════════════════
banner "8. SETTINGS — Towns"
# ═══════════════════════════════════════════════════════════════════════════════
R=$(post "/settings/towns" '{"name":"Karachi","district":"Karachi","province":"Sindh"}')
TOWN_KHI=$(check "$R" "Town: Karachi")

R=$(post "/settings/towns" '{"name":"Hyderabad","district":"Hyderabad","province":"Sindh"}')
TOWN_HYD=$(check "$R" "Town: Hyderabad")

R=$(post "/settings/towns" '{"name":"Lahore","district":"Lahore","province":"Punjab"}')
TOWN_LHR=$(check "$R" "Town: Lahore")

R=$(post "/settings/towns" '{"name":"Quetta","district":"Quetta","province":"Balochistan"}')
TOWN_QTA=$(check "$R" "Town: Quetta")

# ═══════════════════════════════════════════════════════════════════════════════
banner "9. SETTINGS — Sectors"
# ═══════════════════════════════════════════════════════════════════════════════
R=$(post "/settings/sectors" "{\"name\":\"Korangi Industrial\",\"townId\":\"$TOWN_KHI\",\"description\":\"Korangi industrial zone\"}")
SEC_KORANGI=$(check "$R" "Sector: Korangi")

R=$(post "/settings/sectors" "{\"name\":\"Landhi\",\"townId\":\"$TOWN_KHI\",\"description\":\"Landhi township\"}")
SEC_LANDHI=$(check "$R" "Sector: Landhi")

R=$(post "/settings/sectors" "{\"name\":\"Latifabad\",\"townId\":\"$TOWN_HYD\",\"description\":\"Latifabad Unit 10\"}")
SEC_LAT=$(check "$R" "Sector: Latifabad")

R=$(post "/settings/sectors" "{\"name\":\"Gulberg III\",\"townId\":\"$TOWN_LHR\",\"description\":\"Gulberg commercial area\"}")
SEC_GLB=$(check "$R" "Sector: Gulberg")

# ═══════════════════════════════════════════════════════════════════════════════
banner "10. SETTINGS — Salesmen"
# ═══════════════════════════════════════════════════════════════════════════════
R=$(post "/settings/salesmen" "{
  \"name\":\"Usman Ghani\",\"code\":\"SM-001\",\"phone\":\"03001234567\",
  \"email\":\"usman@kaiffarm.pk\",\"address\":\"Karachi\",
  \"joiningDate\":\"2024-01-15\",\"baseSalary\":35000,
  \"commissionType\":\"percentage\",\"commissionValue\":1.5,
  \"assignedTowns\":[\"$TOWN_KHI\"],\"isActive\":true,
  \"notes\":\"Senior salesman — Karachi region\"}")
SALES_USM=$(check "$R" "Salesman: Usman Ghani")

R=$(post "/settings/salesmen" "{
  \"name\":\"Rizwan Akhtar\",\"code\":\"SM-002\",\"phone\":\"03119876543\",
  \"email\":\"rizwan@kaiffarm.pk\",\"address\":\"Hyderabad\",
  \"joiningDate\":\"2024-03-01\",\"baseSalary\":30000,
  \"commissionType\":\"percentage\",\"commissionValue\":1.2,
  \"assignedTowns\":[\"$TOWN_HYD\",\"$TOWN_LHR\"],\"isActive\":true,
  \"notes\":\"Interior Sindh & Punjab region\"}")
SALES_RIZ=$(check "$R" "Salesman: Rizwan Akhtar")

# ═══════════════════════════════════════════════════════════════════════════════
banner "11. SETTINGS — Vendors"
# ═══════════════════════════════════════════════════════════════════════════════
R=$(post "/settings/vendors" "{
  \"name\":\"AgriCore Feed Depot\",\"companyId\":\"$COMP_AGRI\",
  \"phone\":\"021-32570001\",\"email\":\"depot@agricore.pk\",
  \"address\":\"Plot 14, SITE Area, Karachi\",\"town\":\"Karachi\",
  \"openingBalance\":150000,\"balanceType\":\"credit\",
  \"notes\":\"Main feed and medicine vendor\"}")
VEND_AGRI=$(check "$R" "Vendor: AgriCore Feed Depot")

R=$(post "/settings/vendors" "{
  \"name\":\"NutriPak Direct\",\"companyId\":\"$COMP_NUTRI\",
  \"phone\":\"022-2678900\",\"email\":\"direct@nutripak.pk\",
  \"address\":\"G-10, Hyderabad Industrial Estate\",\"town\":\"Hyderabad\",
  \"openingBalance\":80000,\"balanceType\":\"credit\",
  \"notes\":\"Feed manufacturer — direct supply\"}")
VEND_NUTRI=$(check "$R" "Vendor: NutriPak Direct")

R=$(post "/settings/vendors" "{
  \"name\":\"ZamZam Chick Supply\",\"companyId\":\"$COMP_ZAM\",
  \"phone\":\"041-8720000\",\"email\":\"supply@zamzam.pk\",
  \"address\":\"Canal Road, Faisalabad\",\"town\":\"Faisalabad\",
  \"openingBalance\":0,\"balanceType\":\"credit\",
  \"notes\":\"Day-old chick supplier\"}")
VEND_ZAM=$(check "$R" "Vendor: ZamZam Chick Supply")

# ═══════════════════════════════════════════════════════════════════════════════
banner "12. SETTINGS — Customers"
# ═══════════════════════════════════════════════════════════════════════════════
R=$(post "/settings/customers" "{
  \"name\":\"Al-Madina Poultry Shop\",\"code\":\"C-001\",\"phone\":\"03212345678\",
  \"email\":\"almadina@poultry.pk\",\"address\":\"Shop 5, Korangi Market\",
  \"townId\":\"$TOWN_KHI\",\"sectorId\":\"$SEC_KORANGI\",\"salesmanId\":\"$SALES_USM\",
  \"discountSchemeId\":\"$DS_BULK\",
  \"creditLimit\":500000,\"openingBalance\":25000,\"balanceType\":\"debit\",
  \"isActive\":true,\"notes\":\"Regular bulk buyer — Karachi\"}")
CUST_MADINA=$(check "$R" "Customer: Al-Madina Poultry")

R=$(post "/settings/customers" "{
  \"name\":\"Bismillah Murgh Centre\",\"code\":\"C-002\",\"phone\":\"03331122334\",
  \"email\":\"bismillah@murgh.pk\",\"address\":\"Landhi Colony, Block 5\",
  \"townId\":\"$TOWN_KHI\",\"sectorId\":\"$SEC_LANDHI\",\"salesmanId\":\"$SALES_USM\",
  \"discountSchemeId\":\"$DS_FLAT\",
  \"creditLimit\":300000,\"openingBalance\":0,\"balanceType\":\"credit\",
  \"isActive\":true,\"notes\":\"Retail chicken shop\"}")
CUST_BISMILLAH=$(check "$R" "Customer: Bismillah Murgh")

R=$(post "/settings/customers" "{
  \"name\":\"Hassan Poultry Farm\",\"code\":\"C-003\",\"phone\":\"03009988776\",
  \"email\":\"hassan@farm.pk\",\"address\":\"Latifabad Unit 10\",
  \"townId\":\"$TOWN_HYD\",\"sectorId\":\"$SEC_LAT\",\"salesmanId\":\"$SALES_RIZ\",
  \"creditLimit\":200000,\"openingBalance\":10000,\"balanceType\":\"debit\",
  \"isActive\":true,\"notes\":\"Hyderabad wholesale buyer\"}")
CUST_HASSAN=$(check "$R" "Customer: Hassan Poultry Farm")

R=$(post "/settings/customers" "{
  \"name\":\"Gulberg Live Chicken\",\"code\":\"C-004\",\"phone\":\"04211223344\",
  \"email\":\"gulberg@live.pk\",\"address\":\"Main Boulevard, Gulberg\",
  \"townId\":\"$TOWN_LHR\",\"sectorId\":\"$SEC_GLB\",\"salesmanId\":\"$SALES_RIZ\",
  \"creditLimit\":400000,\"openingBalance\":0,\"balanceType\":\"credit\",
  \"isActive\":true,\"notes\":\"Lahore wholesale buyer\"}")
CUST_GULBERG=$(check "$R" "Customer: Gulberg Live Chicken")

# ═══════════════════════════════════════════════════════════════════════════════
banner "13. SETTINGS — Chart of Accounts"
# ═══════════════════════════════════════════════════════════════════════════════
R=$(post "/settings/accounts" '{"accountName":"Cash in Hand","accountCode":"1001","accountType":"asset","openingBalance":250000,"balanceType":"debit","isActive":true,"description":"Petty cash and daily cash transactions"}')
ACC_CASH=$(check "$R" "Account: 1001 Cash in Hand")

R=$(post "/settings/accounts" '{"accountName":"Bank — HBL Current","accountCode":"1002","accountType":"asset","openingBalance":1500000,"balanceType":"debit","isActive":true,"description":"HBL main current account"}')
ACC_HBL=$(check "$R" "Account: 1002 Bank HBL")

R=$(post "/settings/accounts" '{"accountName":"Bank — MCB Savings","accountCode":"1003","accountType":"asset","openingBalance":500000,"balanceType":"debit","isActive":true,"description":"MCB savings account"}')
ACC_MCB=$(check "$R" "Account: 1003 Bank MCB")

R=$(post "/settings/accounts" '{"accountName":"Accounts Receivable","accountCode":"1101","accountType":"asset","openingBalance":35000,"balanceType":"debit","isActive":true,"description":"Trade debtors"}')
ACC_RECV=$(check "$R" "Account: 1101 Accounts Receivable")

R=$(post "/settings/accounts" '{"accountName":"Inventory — Feed","accountCode":"1201","accountType":"asset","openingBalance":800000,"balanceType":"debit","isActive":true,"description":"Feed stock on hand"}')
ACC_INV_FEED=$(check "$R" "Account: 1201 Inventory Feed")

R=$(post "/settings/accounts" '{"accountName":"Accounts Payable","accountCode":"2001","accountType":"liability","openingBalance":230000,"balanceType":"credit","isActive":true,"description":"Trade creditors"}')
ACC_PAY=$(check "$R" "Account: 2001 Accounts Payable")

R=$(post "/settings/accounts" '{"accountName":"Sales Revenue","accountCode":"4001","accountType":"income","openingBalance":0,"balanceType":"credit","isActive":true,"description":"Chicken and feed sales revenue"}')
ACC_SALES=$(check "$R" "Account: 4001 Sales Revenue")

R=$(post "/settings/accounts" '{"accountName":"Feed Purchase Expense","accountCode":"5001","accountType":"expense","openingBalance":0,"balanceType":"debit","isActive":true,"description":"Poultry feed purchase costs"}')
ACC_FEED_EXP=$(check "$R" "Account: 5001 Feed Expense")

R=$(post "/settings/accounts" '{"accountName":"Salary Expense","accountCode":"5002","accountType":"expense","openingBalance":0,"balanceType":"debit","isActive":true,"description":"Staff salaries"}')
ACC_SAL_EXP=$(check "$R" "Account: 5002 Salary Expense")

R=$(post "/settings/accounts" '{"accountName":"Medicine & Vaccine Expense","accountCode":"5003","accountType":"expense","openingBalance":0,"balanceType":"debit","isActive":true,"description":"Vaccine and medicine costs"}')
ACC_MED_EXP=$(check "$R" "Account: 5003 Medicine Expense")

# ═══════════════════════════════════════════════════════════════════════════════
banner "14. SETTINGS — Opening Stock, Receivables, Payables"
# ═══════════════════════════════════════════════════════════════════════════════
R=$(post "/settings/openings/stock" "{\"productId\":\"$PROD_STARTER\",\"quantity\":500,\"rate\":430,\"date\":\"2026-04-01\"}")
ok "Opening Stock: Starter Feed 500 kg → $(id_of "$R")"

R=$(post "/settings/openings/stock" "{\"productId\":\"$PROD_FINISHER\",\"quantity\":300,\"rate\":400,\"date\":\"2026-04-01\"}")
ok "Opening Stock: Finisher Feed 300 kg → $(id_of "$R")"

R=$(post "/settings/openings/stock" "{\"productId\":\"$PROD_NDV\",\"quantity\":20,\"rate\":700,\"date\":\"2026-04-01\"}")
ok "Opening Stock: NDV Vaccine 20 L → $(id_of "$R")"

R=$(post "/settings/openings/receivables" "{\"customerId\":\"$CUST_MADINA\",\"amount\":25000,\"date\":\"2026-04-01\",\"notes\":\"Opening debit balance\"}")
ok "Opening Receivable: Al-Madina 25000 → $(id_of "$R")"

R=$(post "/settings/openings/receivables" "{\"customerId\":\"$CUST_HASSAN\",\"amount\":10000,\"date\":\"2026-04-01\",\"notes\":\"Prior season balance\"}")
ok "Opening Receivable: Hassan 10000 → $(id_of "$R")"

R=$(post "/settings/openings/payables" "{\"vendorId\":\"$VEND_AGRI\",\"amount\":150000,\"date\":\"2026-04-01\",\"notes\":\"Feed purchase outstanding\"}")
ok "Opening Payable: AgriCore 150000 → $(id_of "$R")"

R=$(post "/settings/openings/payables" "{\"vendorId\":\"$VEND_NUTRI\",\"amount\":80000,\"date\":\"2026-04-01\",\"notes\":\"NutriPak supply outstanding\"}")
ok "Opening Payable: NutriPak 80000 → $(id_of "$R")"

# ═══════════════════════════════════════════════════════════════════════════════
banner "15. POULTRY — Feed Schedules"
# ═══════════════════════════════════════════════════════════════════════════════
R=$(post "/poultry/feed-schedules" "{
  \"name\":\"Broiler Standard Pre-Starter\",
  \"ageFromDays\":1,\"ageToDays\":7,\"feedType\":\"pre_starter\",
  \"dailyFeedPerBirdGrams\":25,\"productId\":\"$PROD_PRESTARTER\",
  \"description\":\"Standard 42-day broiler program\"}")
FS_STD_1=$(check "$R" "FeedSchedule: Standard Pre-Starter")

R=$(post "/poultry/feed-schedules" "{
  \"name\":\"Broiler Standard Starter\",
  \"ageFromDays\":8,\"ageToDays\":21,\"feedType\":\"starter\",
  \"dailyFeedPerBirdGrams\":55,\"productId\":\"$PROD_STARTER\",
  \"description\":\"Standard 42-day broiler program\"}")
FS_STD_2=$(check "$R" "FeedSchedule: Standard Starter")

R=$(post "/poultry/feed-schedules" "{
  \"name\":\"Broiler Standard Grower\",
  \"ageFromDays\":22,\"ageToDays\":35,\"feedType\":\"grower\",
  \"dailyFeedPerBirdGrams\":110,\"productId\":\"$PROD_GROWER\",
  \"description\":\"Standard 42-day broiler program\"}")
FS_STD_3=$(check "$R" "FeedSchedule: Standard Grower")

R=$(post "/poultry/feed-schedules" "{
  \"name\":\"Broiler Standard Finisher\",
  \"ageFromDays\":36,\"ageToDays\":42,\"feedType\":\"finisher\",
  \"dailyFeedPerBirdGrams\":150,\"productId\":\"$PROD_FINISHER\",
  \"description\":\"Standard 42-day broiler program\"}")
FS_STD_4=$(check "$R" "FeedSchedule: Standard Finisher")

R=$(post "/poultry/feed-schedules" "{
  \"name\":\"Broiler Intensive Pre-Starter\",
  \"ageFromDays\":1,\"ageToDays\":5,\"feedType\":\"pre_starter\",
  \"dailyFeedPerBirdGrams\":30,\"productId\":\"$PROD_PRESTARTER\",
  \"description\":\"Intensive 35-day short-cycle program\"}")
FS_INT_1=$(check "$R" "FeedSchedule: Intensive Pre-Starter")

R=$(post "/poultry/feed-schedules" "{
  \"name\":\"Broiler Intensive Starter\",
  \"ageFromDays\":6,\"ageToDays\":18,\"feedType\":\"starter\",
  \"dailyFeedPerBirdGrams\":60,\"productId\":\"$PROD_STARTER\",
  \"description\":\"Intensive 35-day short-cycle program\"}")
FS_INT_2=$(check "$R" "FeedSchedule: Intensive Starter")

R=$(post "/poultry/feed-schedules" "{
  \"name\":\"Broiler Intensive Finisher\",
  \"ageFromDays\":19,\"ageToDays\":35,\"feedType\":\"finisher\",
  \"dailyFeedPerBirdGrams\":160,\"productId\":\"$PROD_FINISHER\",
  \"description\":\"Intensive 35-day short-cycle program\"}")
FS_INT_3=$(check "$R" "FeedSchedule: Intensive Finisher")

# ═══════════════════════════════════════════════════════════════════════════════
banner "16. POULTRY — Vaccine Schedules"
# ═══════════════════════════════════════════════════════════════════════════════
R=$(post "/poultry/vaccine-schedules" "{
  \"name\":\"Broiler Core NDV Day 7\",
  \"vaccineType\":\"newcastle\",\"targetAgeDays\":7,
  \"administrationRoute\":\"drinking_water\",\"dosePerBird\":1,
  \"productId\":\"$PROD_NDV\",\"description\":\"Core broiler vaccination protocol\"}")
VS_CORE_1=$(check "$R" "VaccineSchedule: Core NDV Day 7")

R=$(post "/poultry/vaccine-schedules" "{
  \"name\":\"Broiler Core IBD Day 14\",
  \"vaccineType\":\"gumboro\",\"targetAgeDays\":14,
  \"administrationRoute\":\"drinking_water\",\"dosePerBird\":1,
  \"productId\":\"$PROD_IBD\",\"description\":\"Core broiler vaccination protocol\"}")
VS_CORE_2=$(check "$R" "VaccineSchedule: Core IBD Day 14")

R=$(post "/poultry/vaccine-schedules" "{
  \"name\":\"Broiler Core NDV Booster Day 21\",
  \"vaccineType\":\"newcastle\",\"targetAgeDays\":21,
  \"administrationRoute\":\"drinking_water\",\"dosePerBird\":1,
  \"productId\":\"$PROD_NDV\",\"description\":\"Core broiler vaccination protocol\"}")
VS_CORE_3=$(check "$R" "VaccineSchedule: Core NDV Booster Day 21")

R=$(post "/poultry/vaccine-schedules" "{
  \"name\":\"Extended NDV Day 5\",
  \"vaccineType\":\"newcastle\",\"targetAgeDays\":5,
  \"administrationRoute\":\"eye_drop\",\"dosePerBird\":1,
  \"productId\":\"$PROD_NDV\",\"description\":\"Extended protocol for higher biosecurity areas\"}")
VS_EXT_1=$(check "$R" "VaccineSchedule: Extended NDV Day 5")

R=$(post "/poultry/vaccine-schedules" "{
  \"name\":\"Extended IBD Day 12\",
  \"vaccineType\":\"gumboro\",\"targetAgeDays\":12,
  \"administrationRoute\":\"drinking_water\",\"dosePerBird\":1,
  \"productId\":\"$PROD_IBD\",\"description\":\"Extended protocol for higher biosecurity areas\"}")
VS_EXT_2=$(check "$R" "VaccineSchedule: Extended IBD Day 12")

R=$(post "/poultry/vaccine-schedules" "{
  \"name\":\"Extended IBD Booster Day 18\",
  \"vaccineType\":\"gumboro\",\"targetAgeDays\":18,
  \"administrationRoute\":\"drinking_water\",\"dosePerBird\":1,
  \"productId\":\"$PROD_IBD\",\"description\":\"Extended protocol for higher biosecurity areas\"}")
VS_EXT_3=$(check "$R" "VaccineSchedule: Extended IBD Booster Day 18")

R=$(post "/poultry/vaccine-schedules" "{
  \"name\":\"Extended NDV Day 24\",
  \"vaccineType\":\"newcastle\",\"targetAgeDays\":24,
  \"administrationRoute\":\"drinking_water\",\"dosePerBird\":1,
  \"productId\":\"$PROD_NDV\",\"description\":\"Extended protocol for higher biosecurity areas\"}")
VS_EXT_4=$(check "$R" "VaccineSchedule: Extended NDV Day 24")

# ═══════════════════════════════════════════════════════════════════════════════
banner "17. POULTRY — Flocks"
# ═══════════════════════════════════════════════════════════════════════════════
R=$(post "/poultry/flocks" "{
  \"flockNo\":\"F-2026-001\",\"flockName\":\"Shed A Spring Batch\",
  \"birdType\":\"broiler\",\"breed\":\"Ross-308\",
  \"placementDate\":\"2026-04-01\",\"initialBirdsCount\":10000,
  \"shedNo\":\"Shed-A\",\"vendorId\":\"$VEND_ZAM\",
  \"placementWeightKg\":0.042,\"targetWeightKg\":2.3,\"targetAgeDays\":42,
  \"feedScheduleIds\":[\"$FS_STD_1\",\"$FS_STD_2\",\"$FS_STD_3\",\"$FS_STD_4\"],
  \"vaccineScheduleIds\":[\"$VS_CORE_1\",\"$VS_CORE_2\",\"$VS_CORE_3\"],
  \"status\":\"active\",\"notes\":\"Spring 2026 batch — Shed A\"}")
FLOCK_A=$(check "$R" "Flock: Shed A Spring Batch")

R=$(post "/poultry/flocks" "{
  \"flockNo\":\"F-2026-002\",\"flockName\":\"Shed B Winter Batch\",
  \"birdType\":\"broiler\",\"breed\":\"Cobb-500\",
  \"placementDate\":\"2026-02-15\",\"initialBirdsCount\":8000,
  \"shedNo\":\"Shed-B\",\"vendorId\":\"$VEND_ZAM\",
  \"placementWeightKg\":0.040,\"targetWeightKg\":2.1,\"targetAgeDays\":38,
  \"feedScheduleIds\":[\"$FS_INT_1\",\"$FS_INT_2\",\"$FS_INT_3\"],
  \"vaccineScheduleIds\":[\"$VS_EXT_1\",\"$VS_EXT_2\",\"$VS_EXT_3\",\"$VS_EXT_4\"],
  \"status\":\"active\",\"notes\":\"Winter batch — Shed B\"}")
FLOCK_B=$(check "$R" "Flock: Shed B Winter Batch")

# ═══════════════════════════════════════════════════════════════════════════════
banner "18. POULTRY — Flock Feeds"
# ═══════════════════════════════════════════════════════════════════════════════
post "/poultry/flock-feeds" "{\"flockId\":\"$FLOCK_A\",\"date\":\"2026-04-01\",\"feedType\":\"pre_starter\",\"quantityKg\":250,\"totalBirds\":10000,\"notes\":\"Day 1 pre-starter\"}" >/dev/null
post "/poultry/flock-feeds" "{\"flockId\":\"$FLOCK_A\",\"date\":\"2026-04-08\",\"feedType\":\"starter\",\"quantityKg\":550,\"totalBirds\":9980,\"notes\":\"Day 8 starter\"}" >/dev/null
post "/poultry/flock-feeds" "{\"flockId\":\"$FLOCK_A\",\"date\":\"2026-04-15\",\"feedType\":\"starter\",\"quantityKg\":1100,\"totalBirds\":9950,\"notes\":\"Day 15\"}" >/dev/null
post "/poultry/flock-feeds" "{\"flockId\":\"$FLOCK_A\",\"date\":\"2026-04-22\",\"feedType\":\"grower\",\"quantityKg\":2100,\"totalBirds\":9920,\"notes\":\"Day 22 grower\"}" >/dev/null
post "/poultry/flock-feeds" "{\"flockId\":\"$FLOCK_B\",\"date\":\"2026-02-15\",\"feedType\":\"pre_starter\",\"quantityKg\":200,\"totalBirds\":8000,\"notes\":\"Day 1\"}" >/dev/null
post "/poultry/flock-feeds" "{\"flockId\":\"$FLOCK_B\",\"date\":\"2026-02-22\",\"feedType\":\"starter\",\"quantityKg\":480,\"totalBirds\":7990,\"notes\":\"Day 8\"}" >/dev/null
post "/poultry/flock-feeds" "{\"flockId\":\"$FLOCK_B\",\"date\":\"2026-03-05\",\"feedType\":\"grower\",\"quantityKg\":1800,\"totalBirds\":7960,\"notes\":\"Day 19 grower\"}" >/dev/null
post "/poultry/flock-feeds" "{\"flockId\":\"$FLOCK_B\",\"date\":\"2026-03-15\",\"feedType\":\"finisher\",\"quantityKg\":2500,\"totalBirds\":7920,\"notes\":\"Day 29 finisher\"}" >/dev/null
ok "Flock Feeds: 8 feed records across Flock A & B"

# ═══════════════════════════════════════════════════════════════════════════════
banner "19. POULTRY — Flock Vaccines"
# ═══════════════════════════════════════════════════════════════════════════════
post "/poultry/flock-vaccines" "{\"flockId\":\"$FLOCK_A\",\"date\":\"2026-04-08\",\"vaccineType\":\"newcastle\",\"productId\":\"$PROD_NDV\",\"route\":\"drinking_water\",\"dosesAdministered\":10000,\"notes\":\"NDV Day 7\"}" >/dev/null
post "/poultry/flock-vaccines" "{\"flockId\":\"$FLOCK_A\",\"date\":\"2026-04-15\",\"vaccineType\":\"gumboro\",\"productId\":\"$PROD_IBD\",\"route\":\"drinking_water\",\"dosesAdministered\":9980,\"notes\":\"Gumboro Day 14\"}" >/dev/null
post "/poultry/flock-vaccines" "{\"flockId\":\"$FLOCK_B\",\"date\":\"2026-02-20\",\"vaccineType\":\"newcastle\",\"productId\":\"$PROD_NDV\",\"route\":\"eye_drop\",\"dosesAdministered\":8000,\"notes\":\"NDV Day 5\"}" >/dev/null
post "/poultry/flock-vaccines" "{\"flockId\":\"$FLOCK_B\",\"date\":\"2026-02-27\",\"vaccineType\":\"gumboro\",\"productId\":\"$PROD_IBD\",\"route\":\"drinking_water\",\"dosesAdministered\":7990,\"notes\":\"IBD Day 12\"}" >/dev/null
ok "Flock Vaccines: 4 vaccination records"

# ═══════════════════════════════════════════════════════════════════════════════
banner "20. POULTRY — Chicken Invoices"
# ═══════════════════════════════════════════════════════════════════════════════
R=$(post "/poultry/chicken-invoices" "{
  \"flockId\":\"$FLOCK_B\",\"invoiceDate\":\"2026-03-25\",
  \"customerId\":\"$CUST_MADINA\",\"salesmanId\":\"$SALES_USM\",
  \"saleType\":\"live_weight\",
  \"birdsCount\":4000,\"totalLiveWeightKg\":8200,\"pricePerKg\":285,
  \"advanceReceived\":1500000,
  \"invoiceNo\":\"CI-2026-001\",\"paymentStatus\":\"partial\",
  \"notes\":\"First batch sale — Shed B partial\"}")
CHICKEN_INV_1=$(check "$R" "ChickenInvoice: Shed B first sale")

R=$(post "/poultry/chicken-invoices" "{
  \"flockId\":\"$FLOCK_B\",\"invoiceDate\":\"2026-03-28\",
  \"customerId\":\"$CUST_BISMILLAH\",\"salesmanId\":\"$SALES_USM\",
  \"saleType\":\"live_weight\",
  \"birdsCount\":3920,\"totalLiveWeightKg\":8024,\"pricePerKg\":290,
  \"advanceReceived\":2326960,
  \"invoiceNo\":\"CI-2026-002\",\"paymentStatus\":\"paid\",
  \"notes\":\"Second batch — Shed B final sale\"}")
CHICKEN_INV_2=$(check "$R" "ChickenInvoice: Shed B final sale")

# ═══════════════════════════════════════════════════════════════════════════════
banner "═══  INVOICING MODULE  ═══"
# ═══════════════════════════════════════════════════════════════════════════════

# ── 21. PURCHASE ORDER ────────────────────────────────────────────────────────
banner "21. INVOICING — Purchase Order (PO)"
R=$(post "/invoicing/purchase-orders" "{
  \"entryDate\":\"2026-04-02\",
  \"vendorId\":\"$VEND_NUTRI\",\"vendorName\":\"NutriPak Direct\",
  \"city\":\"Hyderabad\",\"status\":\"saved\",
  \"items\":[
    {\"sNo\":1,\"productId\":\"$PROD_STARTER\",\"productName\":\"Broiler Starter Feed\",
     \"packingName\":\"50kg Bag\",\"pack\":50,\"size\":50,\"unit\":\"kg\",
     \"qtyPacks\":20,\"qtyLoose\":0,\"bonus\":0,
     \"price\":430,\"discPercent\":2,\"salesTaxPercent\":0},
    {\"sNo\":2,\"productId\":\"$PROD_GROWER\",\"productName\":\"Broiler Grower Feed\",
     \"packingName\":\"50kg Bag\",\"pack\":50,\"size\":50,\"unit\":\"kg\",
     \"qtyPacks\":15,\"qtyLoose\":0,\"bonus\":0,
     \"price\":415,\"discPercent\":2,\"salesTaxPercent\":0},
    {\"sNo\":3,\"productId\":\"$PROD_FINISHER\",\"productName\":\"Broiler Finisher Feed\",
     \"packingName\":\"50kg Bag\",\"pack\":50,\"size\":50,\"unit\":\"kg\",
     \"qtyPacks\":30,\"qtyLoose\":0,\"bonus\":0,
     \"price\":400,\"discPercent\":2,\"salesTaxPercent\":0}
  ],
  \"disc2Percent\":0,\"fTaxPercent\":0}")
PO_1=$(check "$R" "PurchaseOrder PO-0001")
info "PO totals: $(echo "$R" | jq -r '.data.netValue // "n/a"') net"

# ── 22. SEND ORDER ────────────────────────────────────────────────────────────
banner "22. INVOICING — Send Purchase Order (SO)"
R=$(post "/invoicing/send-orders" "{
  \"orderId\":\"$PO_1\",
  \"vendorId\":\"$VEND_NUTRI\",\"vendorName\":\"NutriPak Direct\",
  \"draftNo\":\"HBL-2026-4521\",\"draftDate\":\"2026-04-03\",
  \"draftAmount\":500000,
  \"bankAccountId\":\"$ACC_HBL\",\"bankAcNo\":\"1002\",\"bankAccountName\":\"Bank — HBL Current\",
  \"description\":\"LC against PO-0001 — NutriPak feed batch\",
  \"includeAllProductsWhenPrinting\":false,
  \"items\":[
    {\"sNo\":1,\"productId\":\"$PROD_STARTER\",\"productName\":\"Broiler Starter Feed\",
     \"packingName\":\"50kg Bag\",\"pack\":50,\"size\":50,\"unit\":\"kg\",
     \"qtyPacks\":20,\"qtyLoose\":0,\"bonus\":0,
     \"price\":430,\"discPercent\":2,\"salesTaxPercent\":0},
    {\"sNo\":2,\"productId\":\"$PROD_GROWER\",\"productName\":\"Broiler Grower Feed\",
     \"packingName\":\"50kg Bag\",\"pack\":50,\"size\":50,\"unit\":\"kg\",
     \"qtyPacks\":15,\"qtyLoose\":0,\"bonus\":0,
     \"price\":415,\"discPercent\":2,\"salesTaxPercent\":0},
    {\"sNo\":3,\"productId\":\"$PROD_FINISHER\",\"productName\":\"Broiler Finisher Feed\",
     \"packingName\":\"50kg Bag\",\"pack\":50,\"size\":50,\"unit\":\"kg\",
     \"qtyPacks\":30,\"qtyLoose\":0,\"bonus\":0,
     \"price\":400,\"discPercent\":2,\"salesTaxPercent\":0}
  ]}")
SO_1=$(check "$R" "SendOrder SO-0001")

# ── 23. PURCHASE INVOICE ──────────────────────────────────────────────────────
banner "23. INVOICING — Purchase Invoice (PI)"
R=$(post "/invoicing/purchase-invoices" "{
  \"entryDate\":\"2026-04-07\",
  \"vendorBillNo\":\"NP-INV-78432\",\"billDate\":\"2026-04-06\",
  \"orderId\":\"$PO_1\",\"orderDate\":\"2026-04-02\",
  \"vendorId\":\"$VEND_NUTRI\",\"vendorName\":\"NutriPak Direct\",
  \"city\":\"Hyderabad\",\"status\":\"saved\",
  \"items\":[
    {\"sNo\":1,\"productId\":\"$PROD_STARTER\",\"productName\":\"Broiler Starter Feed\",
     \"packingName\":\"50kg Bag\",\"pack\":50,\"size\":50,\"unit\":\"kg\",
     \"qtyPacks\":20,\"qtyLoose\":0,\"bonus\":0,
     \"price\":430,\"discPercent\":2,\"salesTaxPercent\":0},
    {\"sNo\":2,\"productId\":\"$PROD_GROWER\",\"productName\":\"Broiler Grower Feed\",
     \"packingName\":\"50kg Bag\",\"pack\":50,\"size\":50,\"unit\":\"kg\",
     \"qtyPacks\":15,\"qtyLoose\":0,\"bonus\":0,
     \"price\":415,\"discPercent\":2,\"salesTaxPercent\":0},
    {\"sNo\":3,\"productId\":\"$PROD_FINISHER\",\"productName\":\"Broiler Finisher Feed\",
     \"packingName\":\"50kg Bag\",\"pack\":50,\"size\":50,\"unit\":\"kg\",
     \"qtyPacks\":30,\"qtyLoose\":0,\"bonus\":0,
     \"price\":400,\"discPercent\":2,\"salesTaxPercent\":0}
  ],
  \"disc2Percent\":0,\"fTax\":0,\"totalSED\":0,\"spcDisc\":0,
  \"prevCredit\":80000,\"paidAmount\":500000}")
PI_1=$(check "$R" "PurchaseInvoice PI-0001")
PI_1_NET=$(echo "$R" | jq -r '.data.netValue // 0')
info "PI-0001 netValue: $PI_1_NET"

# ── 24. PURCHASE RETURN (with invoice) ────────────────────────────────────────
banner "24. INVOICING — Purchase Return With Invoice (PR)"
R=$(post "/invoicing/purchase-returns" "{
  \"returnType\":\"with_invoice\",
  \"returnDate\":\"2026-04-10\",
  \"purchaseInvoiceId\":\"$PI_1\",
  \"vendorId\":\"$VEND_NUTRI\",\"vendorName\":\"NutriPak Direct\",
  \"items\":[
    {\"sNo\":1,\"productId\":\"$PROD_STARTER\",\"productName\":\"Broiler Starter Feed\",
     \"packingName\":\"50kg Bag\",\"pack\":50,\"size\":50,\"unit\":\"kg\",
     \"qtyPacks\":2,\"qtyLoose\":0,\"bonus\":0,
     \"price\":430,\"discPercent\":2,\"salesTaxPercent\":0}
  ],
  \"disc2Percent\":0,\"fTaxPercent\":0}")
PR_1=$(check "$R" "PurchaseReturn PR-0001 (with invoice)")

R=$(post "/invoicing/purchase-returns" "{
  \"returnType\":\"without_invoice\",
  \"returnDate\":\"2026-04-12\",
  \"vendorId\":\"$VEND_AGRI\",\"vendorName\":\"AgriCore Feed Depot\",
  \"items\":[
    {\"sNo\":1,\"productId\":\"$PROD_NDV\",\"productName\":\"NDV Vaccine (La Sota)\",
     \"packingName\":\"1L Bottle\",\"pack\":1,\"unit\":\"L\",
     \"qtyPacks\":1,\"qtyLoose\":0,\"bonus\":0,
     \"price\":700,\"discPercent\":0,\"salesTaxPercent\":17}
  ],
  \"disc2Percent\":0,\"fTaxPercent\":0}")
PR_2=$(check "$R" "PurchaseReturn PR-0002 (without invoice)")

# ── 25. SALES INVOICES ────────────────────────────────────────────────────────
banner "25. INVOICING — Sales Invoices (SI)"
# SI-0001: Al-Madina, Usman, Feed + Supplement
R=$(post "/invoicing/sales-invoices" "{
  \"entryDate\":\"2026-04-10\",
  \"customerId\":\"$CUST_MADINA\",\"customerName\":\"Al-Madina Poultry Shop\",
  \"townId\":\"$TOWN_KHI\",\"sectorId\":\"$SEC_KORANGI\",
  \"salesmanId\":\"$SALES_USM\",\"salesmanName\":\"Usman Ghani\",
  \"prevDebit\":25000,\"status\":\"saved\",
  \"items\":[
    {\"sNo\":1,\"productId\":\"$PROD_FINISHER\",\"productName\":\"Broiler Finisher Feed\",
     \"packingName\":\"5kg Bag\",\"pack\":5,\"unit\":\"kg\",
     \"qtyPacks\":100,\"qtyLoose\":0,\"bonus\":0,
     \"price\":435,\"discPercent\":0,\"salesTaxPercent\":0},
    {\"sNo\":2,\"productId\":\"$PROD_VIT\",\"productName\":\"Vitamin-E & Electrolyte\",
     \"packingName\":\"25kg Bag\",\"pack\":25,\"unit\":\"kg\",
     \"qtyPacks\":2,\"qtyLoose\":0,\"bonus\":0,
     \"price\":3200,\"discPercent\":0,\"salesTaxPercent\":0}
  ],
  \"disc2Percent\":0,\"fTax\":0,\"expense\":0,\"totalSED\":0,\"spcDisc\":0,
  \"paidAmount\":20000,\"description\":\"April batch supply\"}")
SI_1=$(check "$R" "SalesInvoice SI-0001")
SI_1_TOTAL=$(echo "$R" | jq -r '.data.totalPayable // 0')
info "SI-0001 totalPayable: $SI_1_TOTAL"

# SI-0002: Bismillah, Usman, Feed only
R=$(post "/invoicing/sales-invoices" "{
  \"entryDate\":\"2026-04-12\",
  \"customerId\":\"$CUST_BISMILLAH\",\"customerName\":\"Bismillah Murgh Centre\",
  \"townId\":\"$TOWN_KHI\",\"sectorId\":\"$SEC_LANDHI\",
  \"salesmanId\":\"$SALES_USM\",\"salesmanName\":\"Usman Ghani\",
  \"prevDebit\":0,\"status\":\"saved\",
  \"items\":[
    {\"sNo\":1,\"productId\":\"$PROD_GROWER\",\"productName\":\"Broiler Grower Feed\",
     \"packingName\":\"5kg Bag\",\"pack\":5,\"unit\":\"kg\",
     \"qtyPacks\":60,\"qtyLoose\":0,\"bonus\":0,
     \"price\":455,\"discPercent\":0,\"salesTaxPercent\":0},
    {\"sNo\":2,\"productId\":\"$PROD_NDV\",\"productName\":\"NDV Vaccine (La Sota)\",
     \"packingName\":\"500ml Bottle\",\"pack\":0.5,\"unit\":\"L\",
     \"qtyPacks\":4,\"qtyLoose\":0,\"bonus\":0,
     \"price\":850,\"discPercent\":0,\"salesTaxPercent\":17}
  ],
  \"disc2Percent\":0,\"fTax\":0,\"expense\":0,\"totalSED\":0,\"spcDisc\":0,
  \"paidAmount\":0,\"description\":\"Landhi Colony supply\"}")
SI_2=$(check "$R" "SalesInvoice SI-0002")
SI_2_TOTAL=$(echo "$R" | jq -r '.data.totalPayable // 0')
info "SI-0002 totalPayable: $SI_2_TOTAL"

# SI-0003: Hassan, Rizwan — PENDING
R=$(post "/invoicing/sales-invoices" "{
  \"entryDate\":\"2026-04-15\",
  \"customerId\":\"$CUST_HASSAN\",\"customerName\":\"Hassan Poultry Farm\",
  \"townId\":\"$TOWN_HYD\",\"sectorId\":\"$SEC_LAT\",
  \"salesmanId\":\"$SALES_RIZ\",\"salesmanName\":\"Rizwan Akhtar\",
  \"prevDebit\":10000,\"status\":\"pending\",
  \"items\":[
    {\"sNo\":1,\"productId\":\"$PROD_STARTER\",\"productName\":\"Broiler Starter Feed\",
     \"packingName\":\"5kg Bag\",\"pack\":5,\"unit\":\"kg\",
     \"qtyPacks\":40,\"qtyLoose\":0,\"bonus\":0,
     \"price\":460,\"discPercent\":0,\"salesTaxPercent\":0}
  ],
  \"disc2Percent\":0,\"fTax\":0,\"expense\":0,\"totalSED\":0,\"spcDisc\":0,
  \"paidAmount\":0}")
SI_3=$(check "$R" "SalesInvoice SI-0003 (pending)")

# ── 26. SALES RETURNS ─────────────────────────────────────────────────────────
banner "26. INVOICING — Sales Returns (SR)"
R=$(post "/invoicing/sales-returns" "{
  \"returnType\":\"with_invoice\",
  \"returnDate\":\"2026-04-14\",
  \"saleId\":\"$SI_1\",\"saleDate\":\"2026-04-10\",
  \"isFullReturn\":false,
  \"customerId\":\"$CUST_MADINA\",\"customerName\":\"Al-Madina Poultry Shop\",
  \"townId\":\"$TOWN_KHI\",\"sectorId\":\"$SEC_KORANGI\",
  \"salesmanId\":\"$SALES_USM\",\"salesmanName\":\"Usman Ghani\",
  \"toMainStore\":true,
  \"items\":[
    {\"sNo\":1,\"productId\":\"$PROD_FINISHER\",\"productName\":\"Broiler Finisher Feed\",
     \"packingName\":\"5kg Bag\",\"pack\":5,
     \"saleQtyPacks\":100,\"saleQtyLoose\":0,\"saleBns\":0,
     \"prevReturnedQtyPacks\":0,\"prevReturnedQtyLoose\":0,
     \"currentReturnQtyPacks\":5,\"currentReturnQtyLoose\":0,
     \"price\":435,\"discPercent\":0,\"salesTaxPercent\":0}
  ],
  \"disc2Percent\":0,\"fTaxPercent\":0,\"sed\":0,\"specialDiscount\":0,
  \"prevCredit\":0,\"paidAmount\":0,\"description\":\"Damaged bags — partial return\"}")
SR_1=$(check "$R" "SalesReturn SR-0001 (with invoice)")

R=$(post "/invoicing/sales-returns" "{
  \"returnType\":\"without_invoice\",
  \"returnDate\":\"2026-04-16\",
  \"customerId\":\"$CUST_GULBERG\",\"customerName\":\"Gulberg Live Chicken\",
  \"townId\":\"$TOWN_LHR\",\"sectorId\":\"$SEC_GLB\",
  \"salesmanId\":\"$SALES_RIZ\",\"salesmanName\":\"Rizwan Akhtar\",
  \"toMainStore\":true,
  \"items\":[
    {\"sNo\":1,\"productId\":\"$PROD_GROWER\",\"productName\":\"Broiler Grower Feed\",
     \"packingName\":\"5kg Bag\",\"pack\":5,\"unit\":\"kg\",
     \"qtyPacks\":3,\"qtyLoose\":0,\"bonus\":0,
     \"price\":455,\"discPercent\":0,\"salesTaxPercent\":0}
  ],
  \"disc2Percent\":0,\"fTaxPercent\":0,\"sed\":0,\"specialDiscount\":0,
  \"prevCredit\":0,\"paidAmount\":0}")
SR_2=$(check "$R" "SalesReturn SR-0002 (without invoice)")

# ── 27. STOCK ISSUE ───────────────────────────────────────────────────────────
banner "27. INVOICING — Stock Issue to Salesman (STI)"
R=$(post "/invoicing/stock-issues" "{
  \"issueType\":\"issue\",
  \"date\":\"2026-04-08\",
  \"salesmanId\":\"$SALES_USM\",\"salesmanName\":\"Usman Ghani\",
  \"returnAll\":false,
  \"items\":[
    {\"productId\":\"$PROD_FINISHER\",\"productName\":\"Broiler Finisher Feed\",
     \"packingId\":\"$PACK_5KG\",\"packingName\":\"5kg Bag\",\"pack\":5,
     \"qtyPacks\":10,\"qtyLoose\":0,\"cost\":400},
    {\"productId\":\"$PROD_NDV\",\"productName\":\"NDV Vaccine (La Sota)\",
     \"packingId\":\"$PACK_500ML\",\"packingName\":\"500ml Bottle\",\"pack\":0.5,
     \"qtyPacks\":5,\"qtyLoose\":0,\"cost\":700}
  ]}")
STI_1=$(check "$R" "StockIssue STI-0001 (issue)")

R=$(post "/invoicing/stock-issues" "{
  \"issueType\":\"return\",
  \"date\":\"2026-04-18\",
  \"salesmanId\":\"$SALES_USM\",\"salesmanName\":\"Usman Ghani\",
  \"originalIssueId\":\"$STI_1\",\"returnAll\":false,
  \"items\":[
    {\"productId\":\"$PROD_FINISHER\",\"productName\":\"Broiler Finisher Feed\",
     \"packingId\":\"$PACK_5KG\",\"packingName\":\"5kg Bag\",\"pack\":5,
     \"qtyPacks\":2,\"qtyLoose\":0,\"cost\":400}
  ]}")
STR_1=$(check "$R" "StockReturn STR-0001 (return from salesman)")

# ── 28. STOCK EXPIRY ──────────────────────────────────────────────────────────
banner "28. INVOICING — Stock Expiry Invoice (EXP)"
R=$(post "/invoicing/stock-expiries" "{
  \"date\":\"2026-04-20\",
  \"items\":[
    {\"productId\":\"$PROD_NDV\",\"productName\":\"NDV Vaccine (La Sota)\",
     \"packingName\":\"500ml Bottle\",\"pack\":0.5,
     \"expQtyPacks\":2,\"expQtyLoose\":0,
     \"damQtyPacks\":1,\"damQtyLoose\":0,
     \"cost\":700},
    {\"productId\":\"$PROD_IBD\",\"productName\":\"Gumboro IBD Vaccine\",
     \"packingName\":\"500ml Bottle\",\"pack\":0.5,
     \"expQtyPacks\":1,\"expQtyLoose\":0,
     \"damQtyPacks\":0,\"damQtyLoose\":0,
     \"cost\":800}
  ]}")
EXP_1=$(check "$R" "StockExpiry EXP-0001")

# ── 29. EXPIRY CLAIMS ─────────────────────────────────────────────────────────
banner "29. INVOICING — Expiry Claims (EC)"
R=$(post "/invoicing/expiry-claims" "{
  \"direction\":\"from_customer\",
  \"claimDate\":\"2026-04-22\",
  \"customerId\":\"$CUST_MADINA\",\"customerName\":\"Al-Madina Poultry Shop\",
  \"items\":[
    {\"productId\":\"$PROD_NDV\",\"productName\":\"NDV Vaccine (La Sota)\",
     \"packingName\":\"500ml Bottle\",\"pack\":0.5,
     \"expQtyPacks\":1,\"expQtyLoose\":0,
     \"damQtyPacks\":0,\"damQtyLoose\":0,
     \"costPerUnit\":700,\"price\":850}
  ],
  \"replyDate\":\"\",\"returnSameProducts\":true,
  \"replyItems\":[
    {\"productId\":\"$PROD_NDV\",\"productName\":\"NDV Vaccine (La Sota)\",
     \"packingName\":\"500ml Bottle\",\"pack\":0.5,
     \"qtyPacks\":1,\"qtyLoose\":0,\"price\":850}
  ],
  \"repliedAmount\":0}")
EC_1=$(check "$R" "ExpiryClaim EC-0001 (from customer)")

R=$(post "/invoicing/expiry-claims" "{
  \"direction\":\"to_vendor\",
  \"claimDate\":\"2026-04-23\",
  \"vendorId\":\"$VEND_AGRI\",\"vendorName\":\"AgriCore Feed Depot\",
  \"items\":[
    {\"productId\":\"$PROD_IBD\",\"productName\":\"Gumboro IBD Vaccine\",
     \"packingName\":\"1L Bottle\",\"pack\":1,
     \"expQtyPacks\":1,\"expQtyLoose\":0,
     \"damQtyPacks\":0,\"damQtyLoose\":0,
     \"costPerUnit\":800,\"price\":800}
  ],
  \"replyDate\":\"\",\"returnSameProducts\":false,
  \"replyItems\":[],
  \"repliedAmount\":0}")
EC_2=$(check "$R" "ExpiryClaim EC-0002 (to vendor)")

# ── 30. STOCK WASTAGE ─────────────────────────────────────────────────────────
banner "30. INVOICING — Stock Wastage Invoice (WAS)"
R=$(post "/invoicing/stock-wastages" "{
  \"date\":\"2026-04-21\",
  \"items\":[
    {\"productId\":\"$PROD_FINISHER\",\"productName\":\"Broiler Finisher Feed\",
     \"packingName\":\"5kg Bag\",\"pack\":5,
     \"expQtyPacks\":0,\"expQtyLoose\":0,
     \"damQtyPacks\":1,\"damQtyLoose\":3,
     \"cost\":400},
    {\"productId\":\"$PROD_VIT\",\"productName\":\"Vitamin-E & Electrolyte\",
     \"packingName\":\"25kg Bag\",\"pack\":25,
     \"expQtyPacks\":0,\"expQtyLoose\":0,
     \"damQtyPacks\":0,\"damQtyLoose\":1,
     \"cost\":2800}
  ]}")
WAS_1=$(check "$R" "StockWastage WAS-0001")

# ── 31. RECOVERY INVOICE ──────────────────────────────────────────────────────
banner "31. INVOICING — Recovery Invoice (REC)"
SI_1_RECV=$(echo "$SI_1_TOTAL" | jq -r '.')
R=$(post "/invoicing/recovery-invoices" "{
  \"date\":\"2026-04-20\",
  \"salesmanId\":\"$SALES_USM\",\"salesmanName\":\"Usman Ghani\",
  \"customerRecoveries\":[
    {\"customerId\":\"$CUST_MADINA\",\"customerName\":\"Al-Madina Poultry Shop\",
     \"saleId\":\"$SI_1\",
     \"saleValue\":$SI_1_TOTAL,
     \"adjusted\":0,\"receivable\":$SI_1_TOTAL,
     \"received\":30000,\"discount\":0,
     \"finalCredit\":30000,\"narration\":\"April 20 cash collection\"},
    {\"customerId\":\"$CUST_BISMILLAH\",\"customerName\":\"Bismillah Murgh Centre\",
     \"saleId\":\"$SI_2\",
     \"saleValue\":$SI_2_TOTAL,
     \"adjusted\":0,\"receivable\":$SI_2_TOTAL,
     \"received\":15000,\"discount\":500,
     \"finalCredit\":15500,\"narration\":\"Partial + discount given\"}
  ]}")
REC_1=$(check "$R" "RecoveryInvoice REC-0001")
info "Recovery: collected from Al-Madina + Bismillah"

# ── 32. RECOVERY INVOICE WISE ─────────────────────────────────────────────────
banner "32. INVOICING — Recovery Invoice Wise (RIW)"
R=$(post "/invoicing/recovery-invoices-wise" "{
  \"recoveryDate\":\"2026-04-22\",
  \"salesmanId\":\"$SALES_USM\",\"salesmanName\":\"Usman Ghani\",
  \"townId\":\"$TOWN_KHI\",\"sectorId\":\"\",
  \"showSalesmanInNarration\":true,
  \"customerRecoveries\":[
    {\"customerId\":\"$CUST_BISMILLAH\",\"customerName\":\"Bismillah Murgh Centre\",
     \"sector\":\"Landhi\",
     \"invoices\":[
       {\"saleId\":\"$SI_2\",\"date\":\"2026-04-12\",
        \"invoiceValue\":$SI_2_TOTAL,
        \"adjusted\":15500,\"receivable\":$SI_2_TOTAL,
        \"received\":20000,\"discount\":0,
        \"balance\":0,\"narration\":\"Usman Ghani — balance cleared\"}
     ]}
  ]}")
RIW_1=$(check "$R" "RecoveryInvoiceWise RIW-0001")

# ── 33. RECOVERY RECEIVABLE WISE ─────────────────────────────────────────────
banner "33. INVOICING — Recovery Receivable Wise (RRW)"
R=$(post "/invoicing/recovery-receivable-wise" "{
  \"recoveryDate\":\"2026-04-24\",
  \"salesmanId\":\"$SALES_RIZ\",\"salesmanName\":\"Rizwan Akhtar\",
  \"townId\":\"$TOWN_HYD\",\"sectorId\":\"\",
  \"showSalesmanInNarration\":false,
  \"customerRecoveries\":[
    {\"customerId\":\"$CUST_HASSAN\",\"customerName\":\"Hassan Poultry Farm\",
     \"sector\":\"Latifabad\",
     \"receivable\":10000,\"received\":5000,\"discount\":0,
     \"balance\":5000,\"narration\":\"Partial — remainder next visit\"}
  ]}")
RRW_1=$(check "$R" "RecoveryReceivableWise RRW-0001")

# ── 34. SALESMAN CASH RECONCILIATION ─────────────────────────────────────────
banner "34. INVOICING — Salesman Cash Reconciliation (SCR)"
R=$(post "/invoicing/salesman-cash-reconciliations" "{
  \"date\":\"2026-04-25\",
  \"salesmanId\":\"$SALES_USM\",\"salesmanName\":\"Usman Ghani\",
  \"openingBalance\":5000,
  \"recoveryEntries\":[
    {\"recoveryId\":\"$REC_1\",\"recoveryDate\":\"2026-04-20\",
     \"cashReceived\":45000,\"discountGiven\":500,
     \"narration\":\"Combined recovery Apr 20\"}
  ],
  \"expenseEntries\":[
    {\"description\":\"Petrol & travel\",\"amount\":1500},
    {\"description\":\"Customer entertainment\",\"amount\":800}
  ],
  \"cashDeposited\":40000,\"status\":\"saved\"}")
SCR_1=$(check "$R" "SalesmanCashReconciliation SCR-0001")

# ── 35. CASH VOUCHERS ────────────────────────────────────────────────────────
banner "35. INVOICING — Cash Vouchers (CRV, DBV, JRV)"
# Credit voucher (cash received from customer)
R=$(post "/invoicing/cash-vouchers" "{
  \"voucherType\":\"credit\",
  \"voucherDate\":\"2026-04-20\",
  \"lines\":[
    {\"accountId\":\"$ACC_CASH\",\"accountNo\":\"1001\",\"accountName\":\"Cash in Hand\",
     \"debit\":0,\"credit\":45000,\"narration\":\"Cash from Al-Madina collection\"},
    {\"accountId\":\"$ACC_RECV\",\"accountNo\":\"1101\",\"accountName\":\"Accounts Receivable\",
     \"debit\":0,\"credit\":0,\"narration\":\"Trade debt settled\"}
  ]}")
CRV_1=$(check "$R" "CashVoucher CRV-0001 (credit)")

# Debit voucher (payment to vendor)
R=$(post "/invoicing/cash-vouchers" "{
  \"voucherType\":\"debit\",
  \"voucherDate\":\"2026-04-18\",
  \"lines\":[
    {\"accountId\":\"$ACC_HBL\",\"accountNo\":\"1002\",\"accountName\":\"Bank — HBL Current\",
     \"debit\":200000,\"credit\":0,\"narration\":\"Payment to NutriPak via HBL\"},
    {\"accountId\":\"$ACC_PAY\",\"accountNo\":\"2001\",\"accountName\":\"Accounts Payable\",
     \"debit\":200000,\"credit\":0,\"narration\":\"NutriPak outstanding reduced\"}
  ]}")
DBV_1=$(check "$R" "CashVoucher DBV-0001 (debit)")

# Journal voucher (salary expense)
R=$(post "/invoicing/cash-vouchers" "{
  \"voucherType\":\"journal\",
  \"voucherDate\":\"2026-04-30\",
  \"lines\":[
    {\"accountId\":\"$ACC_SAL_EXP\",\"accountNo\":\"5002\",\"accountName\":\"Salary Expense\",
     \"debit\":65000,\"credit\":0,\"narration\":\"April salaries — Usman + Rizwan\"},
    {\"accountId\":\"$ACC_CASH\",\"accountNo\":\"1001\",\"accountName\":\"Cash in Hand\",
     \"debit\":0,\"credit\":65000,\"narration\":\"Cash paid for salaries\"}
  ]}")
JRV_1=$(check "$R" "CashVoucher JRV-0001 (journal)")

# ── 36. BANK CHEQUE ISSUING ───────────────────────────────────────────────────
banner "36. INVOICING — Bank Cheque Issuing (CHQ)"
R=$(post "/invoicing/bank-cheques" "{
  \"chequeNo\":\"HBL-345221\",\"chequeDate\":\"2026-04-19\",
  \"bankAccountId\":\"$ACC_HBL\",\"bankAcNo\":\"1002\",
  \"bankAccountName\":\"Bank — HBL Current\",
  \"payeeType\":\"vendor\",
  \"vendorId\":\"$VEND_NUTRI\",\"vendorName\":\"NutriPak Direct\",
  \"amount\":500000,
  \"narration\":\"PI-0001 payment — NutriPak feed batch\",
  \"isPostDated\":false,\"status\":\"issued\"}")
CHQ_1=$(check "$R" "BankCheque CHQ-0001")

R=$(post "/invoicing/bank-cheques" "{
  \"chequeNo\":\"HBL-345222\",\"chequeDate\":\"2026-05-05\",
  \"bankAccountId\":\"$ACC_HBL\",\"bankAcNo\":\"1002\",
  \"bankAccountName\":\"Bank — HBL Current\",
  \"payeeType\":\"vendor\",
  \"vendorId\":\"$VEND_AGRI\",\"vendorName\":\"AgriCore Feed Depot\",
  \"amount\":150000,
  \"narration\":\"AgriCore outstanding balance payment\",
  \"isPostDated\":true,\"status\":\"issued\"}")
CHQ_2=$(check "$R" "BankCheque CHQ-0002 (post-dated)")

# ── 37. BANK DEPOSITS ─────────────────────────────────────────────────────────
banner "37. INVOICING — Bank Deposits (DEP)"
R=$(post "/invoicing/bank-deposits" "{
  \"depositType\":\"cash\",
  \"depositDate\":\"2026-04-21\",
  \"bankAccountId\":\"$ACC_HBL\",\"bankAccountName\":\"Bank — HBL Current\",
  \"depositSlipNo\":\"HBL-SLIP-00342\",
  \"amount\":40000,
  \"fromAccountId\":\"$ACC_CASH\",\"fromAccountName\":\"Cash in Hand\",
  \"narration\":\"Salesman Usman daily cash deposit\"}")
DEP_1=$(check "$R" "BankDeposit DEP-0001 (cash)")

R=$(post "/invoicing/bank-deposits" "{
  \"depositType\":\"cheque\",
  \"depositDate\":\"2026-04-23\",
  \"bankAccountId\":\"$ACC_MCB\",\"bankAccountName\":\"Bank — MCB Savings\",
  \"depositSlipNo\":\"MCB-DEP-00128\",
  \"amount\":50000,
  \"narration\":\"Customer cheque deposit\",
  \"chequeNo\":\"UBL-78821\",\"chequeDate\":\"2026-04-22\",
  \"drawerName\":\"Gulberg Live Chicken\",\"drawerBankName\":\"UBL\"}")
DEP_2=$(check "$R" "BankDeposit DEP-0002 (cheque)")

# ── 38. PAYMENT PROMISES ──────────────────────────────────────────────────────
banner "38. INVOICING — Payment Promises (PP)"
R=$(post "/invoicing/payment-promises" "{
  \"promiseType\":\"recovery\",
  \"entryDate\":\"2026-04-25\",\"promiseDate\":\"2026-05-05\",
  \"customerId\":\"$CUST_HASSAN\",\"customerName\":\"Hassan Poultry Farm\",
  \"salesmanId\":\"$SALES_RIZ\",\"salesmanName\":\"Rizwan Akhtar\",
  \"chequeNo\":\"HBL-CUST-4521\",\"bankName\":\"HBL\",
  \"amount\":92000,
  \"narration\":\"Post-dated cheque for SI-0003 dues\",
  \"linkedSaleIds\":[\"$SI_3\"],
  \"status\":\"pending\"}")
PP_1=$(check "$R" "PaymentPromise PP-0001 (recovery)")

R=$(post "/invoicing/payment-promises" "{
  \"promiseType\":\"payment\",
  \"entryDate\":\"2026-04-26\",\"promiseDate\":\"2026-05-10\",
  \"vendorId\":\"$VEND_ZAM\",\"vendorName\":\"ZamZam Chick Supply\",
  \"chequeNo\":\"HBL-345280\",\"bankName\":\"HBL\",
  \"amount\":120000,
  \"narration\":\"Chick supply advance payment promise\",
  \"linkedPurchaseIds\":[],
  \"status\":\"pending\"}")
PP_2=$(check "$R" "PaymentPromise PP-0002 (payment)")

# ═══════════════════════════════════════════════════════════════════════════════
banner "39. INVOICING — PATCH: Confirm, Clear, Reconcile"
# ═══════════════════════════════════════════════════════════════════════════════

# Confirm DEP-0001 cash deposit
R=$(patch_req "/invoicing/bank-deposits/$DEP_1/confirm" '{}')
ok "BankDeposit DEP-0001 confirmed → $(echo "$R" | jq -r '.data.isConfirmed // "?"')"

# Reconcile DEP-0001 (bank statement matched)
R=$(patch_req "/invoicing/bank-deposits/$DEP_1/reconcile" '{"bankStatementRef":"HBL-STMT-APR26-LINE-42"}')
ok "BankDeposit DEP-0001 reconciled → $(echo "$R" | jq -r '.data.isReconciled // "?"')"

# Mark CHQ-0001 as cleared
R=$(patch_req "/invoicing/bank-cheques/$CHQ_1/status" "{\"status\":\"cleared\",\"clearedDate\":\"2026-04-25\"}")
ok "BankCheque CHQ-0001 cleared → $(echo "$R" | jq -r '.data.status // "?"')"

# Confirm CRV-0001 voucher
R=$(patch_req "/invoicing/cash-vouchers/$CRV_1/confirm" '{}')
ok "CashVoucher CRV-0001 confirmed → $(echo "$R" | jq -r '.data.isConfirmed // "?"')"

# Confirm JRV-0001 voucher
R=$(patch_req "/invoicing/cash-vouchers/$JRV_1/confirm" '{}')
ok "CashVoucher JRV-0001 confirmed → $(echo "$R" | jq -r '.data.isConfirmed // "?"')"

# Mark PP-0001 recovery promise as cleared
R=$(patch_req "/invoicing/payment-promises/$PP_1/status" "{\"status\":\"cleared\",\"processedDate\":\"2026-05-05\"}")
ok "PaymentPromise PP-0001 cleared → $(echo "$R" | jq -r '.data.status // "?"')"

# ═══════════════════════════════════════════════════════════════════════════════
banner "40. ACCOUNTS — Ledger Entries"
# ═══════════════════════════════════════════════════════════════════════════════
# Opening balance entries
R=$(post "/accounts/ledger" "{
  \"entryNo\":\"JV-0001\",\"entryDate\":\"2026-04-01\",
  \"accountId\":\"$ACC_CASH\",\"entryType\":\"debit\",\"amount\":250000,
  \"description\":\"Opening balance — Cash in Hand\",
  \"referenceType\":\"manual\",\"isReconciled\":false}")
ok "Ledger JV-0001: Cash opening → $(id_of "$R")"

R=$(post "/accounts/ledger" "{
  \"entryNo\":\"JV-0002\",\"entryDate\":\"2026-04-01\",
  \"accountId\":\"$ACC_HBL\",\"entryType\":\"debit\",\"amount\":1500000,
  \"description\":\"Opening balance — HBL Current Account\",
  \"referenceType\":\"manual\",\"isReconciled\":true,
  \"notes\":\"Confirmed against Apr bank statement\"}")
ok "Ledger JV-0002: HBL opening → $(id_of "$R")"

R=$(post "/accounts/ledger" "{
  \"entryNo\":\"JV-0003\",\"entryDate\":\"2026-04-10\",
  \"accountId\":\"$ACC_SALES\",\"entryType\":\"credit\",\"amount\":43500,
  \"description\":\"Sales Revenue — SI-0001 Al-Madina Poultry\",
  \"referenceType\":\"other\",\"referenceNo\":\"SI-0001\",\"isReconciled\":false}")
ok "Ledger JV-0003: Sales revenue SI-0001 → $(id_of "$R")"

R=$(post "/accounts/ledger" "{
  \"entryNo\":\"JV-0004\",\"entryDate\":\"2026-04-10\",
  \"accountId\":\"$ACC_RECV\",\"entryType\":\"debit\",\"amount\":23500,
  \"description\":\"Trade receivable — SI-0001 balance due\",
  \"referenceType\":\"other\",\"referenceNo\":\"SI-0001\",\"isReconciled\":false}")
ok "Ledger JV-0004: Receivable SI-0001 → $(id_of "$R")"

R=$(post "/accounts/ledger" "{
  \"entryNo\":\"JV-0005\",\"entryDate\":\"2026-04-12\",
  \"accountId\":\"$ACC_SALES\",\"entryType\":\"credit\",\"amount\":15098,
  \"description\":\"Sales Revenue — SI-0002 Bismillah Murgh\",
  \"referenceType\":\"other\",\"referenceNo\":\"SI-0002\",\"isReconciled\":false}")
ok "Ledger JV-0005: Sales revenue SI-0002 → $(id_of "$R")"

R=$(post "/accounts/ledger" "{
  \"entryNo\":\"JV-0006\",\"entryDate\":\"2026-04-07\",
  \"accountId\":\"$ACC_FEED_EXP\",\"entryType\":\"debit\",\"amount\":1475400,
  \"description\":\"Feed purchase — PI-0001 NutriPak\",
  \"referenceType\":\"other\",\"referenceNo\":\"PI-0001\",\"isReconciled\":false}")
ok "Ledger JV-0006: Feed purchase PI-0001 → $(id_of "$R")"

R=$(post "/accounts/ledger" "{
  \"entryNo\":\"JV-0007\",\"entryDate\":\"2026-04-07\",
  \"accountId\":\"$ACC_PAY\",\"entryType\":\"credit\",\"amount\":1475400,
  \"description\":\"Payable to NutriPak — PI-0001\",
  \"referenceType\":\"other\",\"referenceNo\":\"PI-0001\",\"isReconciled\":false}")
ok "Ledger JV-0007: Payable NutriPak → $(id_of "$R")"

R=$(post "/accounts/ledger" "{
  \"entryNo\":\"JV-0008\",\"entryDate\":\"2026-04-18\",
  \"accountId\":\"$ACC_PAY\",\"entryType\":\"debit\",\"amount\":200000,
  \"description\":\"Payment to NutriPak — DBV-0001\",
  \"referenceType\":\"other\",\"referenceNo\":\"DBV-0001\",\"isReconciled\":true}")
ok "Ledger JV-0008: Vendor payment → $(id_of "$R")"

R=$(post "/accounts/ledger" "{
  \"entryNo\":\"JV-0009\",\"entryDate\":\"2026-04-18\",
  \"accountId\":\"$ACC_HBL\",\"entryType\":\"credit\",\"amount\":200000,
  \"description\":\"HBL debit for NutriPak payment\",
  \"referenceType\":\"other\",\"referenceNo\":\"DBV-0001\",\"isReconciled\":true}")
ok "Ledger JV-0009: HBL debit → $(id_of "$R")"

R=$(post "/accounts/ledger" "{
  \"entryNo\":\"JV-0010\",\"entryDate\":\"2026-04-20\",
  \"accountId\":\"$ACC_CASH\",\"entryType\":\"debit\",\"amount\":45000,
  \"description\":\"Cash received via REC-0001 — Usman Ghani\",
  \"referenceType\":\"other\",\"referenceNo\":\"REC-0001\",\"isReconciled\":false}")
ok "Ledger JV-0010: Cash receipt REC-0001 → $(id_of "$R")"

R=$(post "/accounts/ledger" "{
  \"entryNo\":\"JV-0011\",\"entryDate\":\"2026-04-20\",
  \"accountId\":\"$ACC_RECV\",\"entryType\":\"credit\",\"amount\":45500,
  \"description\":\"Receivable reduced — REC-0001 + discount 500\",
  \"referenceType\":\"other\",\"referenceNo\":\"REC-0001\",\"isReconciled\":false}")
ok "Ledger JV-0011: Receivable cleared → $(id_of "$R")"

R=$(post "/accounts/ledger" "{
  \"entryNo\":\"JV-0012\",\"entryDate\":\"2026-04-21\",
  \"accountId\":\"$ACC_HBL\",\"entryType\":\"debit\",\"amount\":40000,
  \"description\":\"Cash deposit DEP-0001 — HBL slip HBL-SLIP-00342\",
  \"referenceType\":\"other\",\"referenceNo\":\"DEP-0001\",\"isReconciled\":true}")
ok "Ledger JV-0012: Cash deposit to HBL → $(id_of "$R")"

R=$(post "/accounts/ledger" "{
  \"entryNo\":\"JV-0013\",\"entryDate\":\"2026-04-21\",
  \"accountId\":\"$ACC_CASH\",\"entryType\":\"credit\",\"amount\":40000,
  \"description\":\"Cash deposited to bank from DEP-0001\",
  \"referenceType\":\"other\",\"referenceNo\":\"DEP-0001\",\"isReconciled\":true}")
ok "Ledger JV-0013: Cash out to bank → $(id_of "$R")"

R=$(post "/accounts/ledger" "{
  \"entryNo\":\"JV-0014\",\"entryDate\":\"2026-04-30\",
  \"accountId\":\"$ACC_SAL_EXP\",\"entryType\":\"debit\",\"amount\":65000,
  \"description\":\"Salaries April — Usman 35k + Rizwan 30k\",
  \"referenceType\":\"other\",\"referenceNo\":\"JRV-0001\",\"isReconciled\":false}")
ok "Ledger JV-0014: Salary expense → $(id_of "$R")"

R=$(post "/accounts/ledger" "{
  \"entryNo\":\"JV-0015\",\"entryDate\":\"2026-04-30\",
  \"accountId\":\"$ACC_CASH\",\"entryType\":\"credit\",\"amount\":65000,
  \"description\":\"Cash paid for April salaries\",
  \"referenceType\":\"other\",\"referenceNo\":\"JRV-0001\",\"isReconciled\":false}")
ok "Ledger JV-0015: Cash out salaries → $(id_of "$R")"

R=$(post "/accounts/ledger" "{
  \"entryNo\":\"JV-0016\",\"entryDate\":\"2026-04-25\",
  \"accountId\":\"$ACC_HBL\",\"entryType\":\"credit\",\"amount\":500000,
  \"description\":\"Cheque CHQ-0001 cleared — NutriPak payment\",
  \"referenceType\":\"other\",\"referenceNo\":\"CHQ-0001\",\"isReconciled\":true}")
ok "Ledger JV-0016: Cheque cleared HBL → $(id_of "$R")"

R=$(post "/accounts/ledger" "{
  \"entryNo\":\"JV-0017\",\"entryDate\":\"2026-04-25\",
  \"accountId\":\"$ACC_PAY\",\"entryType\":\"debit\",\"amount\":500000,
  \"description\":\"NutriPak payable cleared — CHQ-0001\",
  \"referenceType\":\"other\",\"referenceNo\":\"CHQ-0001\",\"isReconciled\":true}")
ok "Ledger JV-0017: Payable cleared CHQ-0001 → $(id_of "$R")"

R=$(post "/accounts/ledger" "{
  \"entryNo\":\"JV-0018\",\"entryDate\":\"2026-04-23\",
  \"accountId\":\"$ACC_MCB\",\"entryType\":\"debit\",\"amount\":50000,
  \"description\":\"Cheque deposit DEP-0002 — Gulberg Live\",
  \"referenceType\":\"other\",\"referenceNo\":\"DEP-0002\",\"isReconciled\":false}")
ok "Ledger JV-0018: Cheque deposit MCB → $(id_of "$R")"

# ═══════════════════════════════════════════════════════════════════════════════
banner "41. SETTINGS — Live Chickens Product (for ChickenInvoice → SalesInvoice integration)"
# ═══════════════════════════════════════════════════════════════════════════════
R=$(post "/settings/products" "{
  \"name\":\"Live Chickens (per kg)\",\"code\":\"CHK-001\",
  \"groupId\":\"$PG_MERCH\",\"subGroupId\":\"$PSG_MISC\",\"unitId\":\"$UNIT_KG\",\"companyId\":\"\",
  \"purPackingId\":\"\",\"salePackingId\":\"\",
  \"purchasePrice\":260,\"purchaseDiscPercent\":0,
  \"sale1Price\":285,\"sale1DiscPercent\":0,
  \"sale2Price\":280,\"sale2DiscPercent\":0,
  \"sale3Price\":275,\"sale3DiscPercent\":0,
  \"salesTaxPercent\":0,\"sedValue\":0,\"retailPrice\":295,
  \"size\":0,\"displayOrder\":50,
  \"isPoultryItem\":true,\"isActive\":true,
  \"description\":\"Live broiler chicken — used for auto-generating Sales Invoices from Chicken Invoice\"}")
PROD_CHICKEN=$(check "$R" "Product: Live Chickens (CHK-001)")

# ═══════════════════════════════════════════════════════════════════════════════
banner "42. SETTINGS — Posting Configuration"
# ═══════════════════════════════════════════════════════════════════════════════
R=$(curl -s -X PUT "$BASE_URL/settings/posting-config" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"arAccountId\":\"$ACC_RECV\",
    \"apAccountId\":\"$ACC_PAY\",
    \"salesRevenueAccountId\":\"$ACC_SALES\",
    \"purchaseExpenseAccountId\":\"$ACC_FEED_EXP\",
    \"cashAccountId\":\"$ACC_CASH\",
    \"defaultBankAccountId\":\"$ACC_HBL\",
    \"chickenProductId\":\"$PROD_CHICKEN\",
    \"notes\":\"Auto-configured by seed script — adjust accounts as needed\"
  }")
ok "PostingConfig saved → AR=$ACC_RECV  Sales=$ACC_SALES  Cash=$ACC_CASH  ChickenProduct=$PROD_CHICKEN"

# ═══════════════════════════════════════════════════════════════════════════════
banner "══  SEED COMPLETE  ══"
# ═══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}${GREEN}Summary of seeded records:${NC}"
echo -e "${CYAN}  Settings  →  Units:4  Packings:6  Companies:3  ProductGroups:3  SubGroups:5"
echo -e "              Products:9 (incl. Live Chickens)  DiscountSchemes:2  Towns:4  Sectors:4"
echo -e "              Salesmen:2  Vendors:3  Customers:4  Accounts:10"
echo -e "              OpeningStock:3  OpeningReceivables:2  OpeningPayables:2"
echo -e "              PostingConfig: 1 (AR, AP, Sales Revenue, Cash, Bank, Chicken Product)${NC}"
echo ""
echo -e "${CYAN}  Poultry   →  FeedSchedules:7  VaccineSchedules:7  Flocks:2"
echo -e "              FlockFeeds:8  FlockVaccines:4  ChickenInvoices:2${NC}"
echo ""
echo -e "${CYAN}  Invoicing →  PurchaseOrder:1  SendOrder:1  PurchaseInvoice:1"
echo -e "              PurchaseReturns:2  SalesInvoices:3  SalesReturns:2"
echo -e "              StockIssue:1  StockReturn:1  StockExpiry:1"
echo -e "              ExpiryClaims:2  StockWastage:1"
echo -e "              RecoveryInvoice:1  RecoveryInvoiceWise:1  RecoveryReceivableWise:1"
echo -e "              SalesmanCashRecon:1  CashVouchers:3  BankCheques:2"
echo -e "              BankDeposits:2  PaymentPromises:2${NC}"
echo ""
echo -e "${CYAN}  Accounts  →  LedgerEntries:18${NC}"
echo ""
echo -e "${GREEN}${BOLD}All 31 invoicing screens, all poultry screens, all settings pages${NC}"
echo -e "and the accounts ledger have seed data for kaif1@gmail.com${NC}"
