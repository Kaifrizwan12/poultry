#!/bin/bash
# ============================================================
#  Farm Management System — Full Dummy Data Seeder
# ============================================================
BASE_URL="http://localhost:3000/api/v1"
EMAIL="kaif@gmail.com"
PASSWORD="Kaifi125*"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✔ $1${NC}"; }
fail() { echo -e "${RED}✘ $1${NC}"; }
info() { echo -e "${CYAN}→ $1${NC}"; }
head() { echo -e "\n${YELLOW}══ $1 ══${NC}"; }

post() {
  local path="$1"; local body="$2"
  curl -s -X POST "$BASE_URL$path" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "$body"
}

# ── 0. LOGIN ─────────────────────────────────────────────────
head "AUTH — Login"
LOGIN_RES=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
TOKEN=$(echo "$LOGIN_RES" | jq -r '.data.accessToken // .accessToken // .token // empty')
if [ -z "$TOKEN" ]; then
  fail "Login failed. Response: $LOGIN_RES"
  exit 1
fi
ok "Logged in — token acquired"

# ── 1. UNITS ─────────────────────────────────────────────────
head "SETTINGS — Units"
RES=$(post "/settings/units" '{"name":"Kilogram","abbreviation":"kg","description":"Weight in kilograms"}')
UNIT_KG=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Unit: Kilogram → $UNIT_KG"

RES=$(post "/settings/units" '{"name":"Piece","abbreviation":"pcs","description":"Count per piece"}')
UNIT_PCS=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Unit: Piece → $UNIT_PCS"

RES=$(post "/settings/units" '{"name":"Gram","abbreviation":"g","description":"Weight in grams"}')
UNIT_G=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Unit: Gram → $UNIT_G"

RES=$(post "/settings/units" '{"name":"Litre","abbreviation":"L","description":"Volume in litres"}')
UNIT_L=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Unit: Litre → $UNIT_L"

# ── 2. PACKINGS ───────────────────────────────────────────────
head "SETTINGS — Packings"
RES=$(post "/settings/packings" "{\"name\":\"50kg Bag\",\"unitId\":\"$UNIT_KG\",\"quantity\":50,\"description\":\"Standard 50 kg feed bag\"}")
PACK_50KG=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Packing: 50kg Bag → $PACK_50KG"

RES=$(post "/settings/packings" "{\"name\":\"25kg Bag\",\"unitId\":\"$UNIT_KG\",\"quantity\":25,\"description\":\"Half bag 25 kg\"}")
PACK_25KG=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Packing: 25kg Bag → $PACK_25KG"

RES=$(post "/settings/packings" "{\"name\":\"1L Bottle\",\"unitId\":\"$UNIT_L\",\"quantity\":1,\"description\":\"1 litre vaccine bottle\"}")
PACK_1L=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Packing: 1L Bottle → $PACK_1L"

RES=$(post "/settings/packings" "{\"name\":\"500ml Bottle\",\"unitId\":\"$UNIT_L\",\"quantity\":0.5,\"description\":\"500ml bottle\"}")
PACK_500ML=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Packing: 500ml Bottle → $PACK_500ML"

# ── 3. COMPANIES ──────────────────────────────────────────────
head "SETTINGS — Companies"
RES=$(post "/settings/companies" '{"name":"AgriTech Supplies Pvt Ltd","address":"Plot 12, SITE Area, Karachi","phone":"021-32570001","email":"info@agritech.pk","ntn":"1234567-8","strn":"12-34-5678-001-00","contactPerson":"Mr. Saleem Ahmed","notes":"Primary feed supplier"}')
COMP_AGRI=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Company: AgriTech Supplies → $COMP_AGRI"

RES=$(post "/settings/companies" '{"name":"FeedMasters International","address":"G-10, Hyderabad Industrial Estate","phone":"022-2678900","email":"orders@feedmasters.pk","contactPerson":"Mrs. Nadia Khan","notes":"Vaccine & medicine supplier"}')
COMP_FEED=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Company: FeedMasters → $COMP_FEED"

RES=$(post "/settings/companies" '{"name":"Poultry Pro Corp","address":"Lahore Road, Faisalabad","phone":"041-8720000","email":"sales@poultrpro.pk","contactPerson":"Mr. Tariq Mehmood","notes":"Chick supplier"}')
COMP_PRO=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Company: Poultry Pro Corp → $COMP_PRO"

# ── 4. PRODUCT GROUPS ─────────────────────────────────────────
head "SETTINGS — Product Groups"
RES=$(post "/settings/product-groups" '{"name":"Poultry Feed","description":"All types of poultry feed"}')
PG_FEED=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Product Group: Poultry Feed → $PG_FEED"

RES=$(post "/settings/product-groups" '{"name":"Vaccines & Medicine","description":"Poultry vaccines and veterinary medicines"}')
PG_VAX=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Product Group: Vaccines & Medicine → $PG_VAX"

RES=$(post "/settings/product-groups" '{"name":"Equipment & Supplies","description":"Farm equipment and consumable supplies"}')
PG_EQP=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Product Group: Equipment & Supplies → $PG_EQP"

# ── 5. PRODUCT SUB-GROUPS ─────────────────────────────────────
head "SETTINGS — Product Sub-Groups"
RES=$(post "/settings/product-sub-groups" "{\"name\":\"Broiler Feed\",\"groupId\":\"$PG_FEED\",\"description\":\"Feed formulations for broiler birds\"}")
PSG_BROILER=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Sub-Group: Broiler Feed → $PSG_BROILER"

RES=$(post "/settings/product-sub-groups" "{\"name\":\"Layer Feed\",\"groupId\":\"$PG_FEED\",\"description\":\"Feed formulations for layer birds\"}")
PSG_LAYER=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Sub-Group: Layer Feed → $PSG_LAYER"

RES=$(post "/settings/product-sub-groups" "{\"name\":\"Live Vaccines\",\"groupId\":\"$PG_VAX\",\"description\":\"Live attenuated poultry vaccines\"}")
PSG_LIVEVAX=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Sub-Group: Live Vaccines → $PSG_LIVEVAX"

RES=$(post "/settings/product-sub-groups" "{\"name\":\"Inactivated Vaccines\",\"groupId\":\"$PG_VAX\",\"description\":\"Killed/inactivated vaccines\"}")
PSG_INACVAX=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Sub-Group: Inactivated Vaccines → $PSG_INACVAX"

# ── 6. PRODUCTS ───────────────────────────────────────────────
head "SETTINGS — Products"
RES=$(post "/settings/products" "{\"name\":\"Broiler Pre-Starter Feed\",\"groupId\":\"$PG_FEED\",\"subGroupId\":\"$PSG_BROILER\",\"unitId\":\"$UNIT_KG\",\"packingId\":\"$PACK_50KG\",\"code\":\"BPSF-001\",\"salePrice\":4800,\"purchasePrice\":4500,\"taxPercent\":0,\"isActive\":true,\"description\":\"High protein pre-starter crumble 0-7 days\"}")
PROD_PRESTARTER=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Product: Pre-Starter Feed → $PROD_PRESTARTER"

RES=$(post "/settings/products" "{\"name\":\"Broiler Starter Feed\",\"groupId\":\"$PG_FEED\",\"subGroupId\":\"$PSG_BROILER\",\"unitId\":\"$UNIT_KG\",\"packingId\":\"$PACK_50KG\",\"code\":\"BSF-002\",\"salePrice\":4600,\"purchasePrice\":4300,\"taxPercent\":0,\"isActive\":true,\"description\":\"Starter crumble 7-21 days\"}")
PROD_STARTER=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Product: Starter Feed → $PROD_STARTER"

RES=$(post "/settings/products" "{\"name\":\"Broiler Grower Feed\",\"groupId\":\"$PG_FEED\",\"subGroupId\":\"$PSG_BROILER\",\"unitId\":\"$UNIT_KG\",\"packingId\":\"$PACK_50KG\",\"code\":\"BGF-003\",\"salePrice\":4400,\"purchasePrice\":4100,\"taxPercent\":0,\"isActive\":true,\"description\":\"Grower pellet 21-35 days\"}")
PROD_GROWER=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Product: Grower Feed → $PROD_GROWER"

RES=$(post "/settings/products" "{\"name\":\"Broiler Finisher Feed\",\"groupId\":\"$PG_FEED\",\"subGroupId\":\"$PSG_BROILER\",\"unitId\":\"$UNIT_KG\",\"packingId\":\"$PACK_50KG\",\"code\":\"BFF-004\",\"salePrice\":4200,\"purchasePrice\":3900,\"taxPercent\":0,\"isActive\":true,\"description\":\"Finisher pellet 35+ days\"}")
PROD_FINISHER=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Product: Finisher Feed → $PROD_FINISHER"

RES=$(post "/settings/products" "{\"name\":\"Newcastle Disease Vaccine (La Sota)\",\"groupId\":\"$PG_VAX\",\"subGroupId\":\"$PSG_LIVEVAX\",\"unitId\":\"$UNIT_L\",\"packingId\":\"$PACK_500ML\",\"code\":\"NDV-001\",\"salePrice\":850,\"purchasePrice\":700,\"taxPercent\":5,\"isActive\":true,\"description\":\"La Sota strain, 1000 dose/bottle\"}")
PROD_NDV=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Product: Newcastle Vaccine → $PROD_NDV"

RES=$(post "/settings/products" "{\"name\":\"Infectious Bursal Disease Vaccine (Gumboro)\",\"groupId\":\"$PG_VAX\",\"subGroupId\":\"$PSG_LIVEVAX\",\"unitId\":\"$UNIT_L\",\"packingId\":\"$PACK_500ML\",\"code\":\"IBD-001\",\"salePrice\":950,\"purchasePrice\":800,\"taxPercent\":5,\"isActive\":true,\"description\":\"IBD live vaccine, 1000 dose/bottle\"}")
PROD_IBD=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Product: Gumboro Vaccine → $PROD_IBD"

RES=$(post "/settings/products" "{\"name\":\"Infectious Bronchitis Vaccine\",\"groupId\":\"$PG_VAX\",\"subGroupId\":\"$PSG_LIVEVAX\",\"unitId\":\"$UNIT_L\",\"packingId\":\"$PACK_1L\",\"code\":\"IBV-001\",\"salePrice\":780,\"purchasePrice\":650,\"taxPercent\":5,\"isActive\":true,\"description\":\"IB Massachusetts strain\"}")
PROD_IB=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Product: IB Vaccine → $PROD_IB"

RES=$(post "/settings/products" "{\"name\":\"Vitamin & Electrolyte Supplement\",\"groupId\":\"$PG_VAX\",\"subGroupId\":\"$PSG_INACVAX\",\"unitId\":\"$UNIT_KG\",\"packingId\":\"$PACK_25KG\",\"code\":\"VES-001\",\"salePrice\":3200,\"purchasePrice\":2800,\"taxPercent\":0,\"isActive\":true,\"description\":\"Multi-vitamin electrolyte powder\"}")
PROD_VIT=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Product: Vitamin Supplement → $PROD_VIT"

# ── 7. DISCOUNT SCHEMES ───────────────────────────────────────
head "SETTINGS — Discount Schemes"
RES=$(post "/settings/discount-schemes" '{"name":"Bulk Buyer 5%","type":"percentage","value":5,"applicableTo":"all","validFrom":"2026-01-01","validTo":"2026-12-31","notes":"5% off for bulk buyers"}')
DS_BULK=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Discount Scheme: Bulk Buyer 5% → $DS_BULK"

RES=$(post "/settings/discount-schemes" '{"name":"Seasonal Flat 500","type":"flat","value":500,"applicableTo":"all","validFrom":"2026-01-01","validTo":"2026-06-30","notes":"Flat 500 off per invoice - seasonal"}')
DS_FLAT=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Discount Scheme: Seasonal Flat 500 → $DS_FLAT"

# ── 8. TOWNS ──────────────────────────────────────────────────
head "SETTINGS — Towns"
RES=$(post "/settings/towns" '{"name":"Karachi Central","district":"Karachi","province":"Sindh"}')
TOWN_KHI=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Town: Karachi Central → $TOWN_KHI"

RES=$(post "/settings/towns" '{"name":"Hyderabad","district":"Hyderabad","province":"Sindh"}')
TOWN_HYD=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Town: Hyderabad → $TOWN_HYD"

RES=$(post "/settings/towns" '{"name":"Lahore","district":"Lahore","province":"Punjab"}')
TOWN_LHR=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Town: Lahore → $TOWN_LHR"

RES=$(post "/settings/towns" '{"name":"Faisalabad","district":"Faisalabad","province":"Punjab"}')
TOWN_FSD=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Town: Faisalabad → $TOWN_FSD"

# ── 9. SECTORS ────────────────────────────────────────────────
head "SETTINGS — Sectors"
RES=$(post "/settings/sectors" "{\"name\":\"Korangi Industrial\",\"townId\":\"$TOWN_KHI\",\"description\":\"Korangi industrial and commercial zone\"}")
SEC_KORANGI=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Sector: Korangi Industrial → $SEC_KORANGI"

RES=$(post "/settings/sectors" "{\"name\":\"Landhi\",\"townId\":\"$TOWN_KHI\",\"description\":\"Landhi township area\"}")
SEC_LANDHI=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Sector: Landhi → $SEC_LANDHI"

RES=$(post "/settings/sectors" "{\"name\":\"Latifabad\",\"townId\":\"$TOWN_HYD\",\"description\":\"Latifabad unit 10\"}")
SEC_LAT=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Sector: Latifabad → $SEC_LAT"

RES=$(post "/settings/sectors" "{\"name\":\"Gulberg\",\"townId\":\"$TOWN_LHR\",\"description\":\"Gulberg commercial area\"}")
SEC_GLB=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Sector: Gulberg → $SEC_GLB"

# ── 10. SALESMEN ──────────────────────────────────────────────
head "SETTINGS — Salesmen"
RES=$(post "/settings/salesmen" "{\"name\":\"Usman Ghani\",\"phone\":\"03001234567\",\"code\":\"SM-001\",\"email\":\"usman@farm.pk\",\"address\":\"Karachi\",\"joiningDate\":\"2024-01-15\",\"baseSalary\":35000,\"commissionType\":\"percentage\",\"commissionValue\":1.5,\"assignedTowns\":[\"$TOWN_KHI\"],\"isActive\":true,\"notes\":\"Senior salesman - Karachi region\"}")
SALES_USM=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Salesman: Usman Ghani → $SALES_USM"

RES=$(post "/settings/salesmen" "{\"name\":\"Rizwan Akhtar\",\"phone\":\"03119876543\",\"code\":\"SM-002\",\"email\":\"rizwan@farm.pk\",\"address\":\"Hyderabad\",\"joiningDate\":\"2024-03-01\",\"baseSalary\":30000,\"commissionType\":\"percentage\",\"commissionValue\":1.2,\"assignedTowns\":[\"$TOWN_HYD\",\"$TOWN_FSD\"],\"isActive\":true,\"notes\":\"Interior Sindh & Punjab region\"}")
SALES_RIZ=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Salesman: Rizwan Akhtar → $SALES_RIZ"

# ── 11. VENDORS ───────────────────────────────────────────────
head "SETTINGS — Vendors"
RES=$(post "/settings/vendors" "{\"name\":\"AgriTech Feed Depot\",\"companyId\":\"$COMP_AGRI\",\"phone\":\"021-32570001\",\"email\":\"depot@agritech.pk\",\"address\":\"Plot 12, SITE Area, Karachi\",\"town\":\"Karachi\",\"openingBalance\":150000,\"balanceType\":\"credit\",\"notes\":\"Main feed vendor\"}")
VEND_AGRI=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Vendor: AgriTech Feed Depot → $VEND_AGRI"

RES=$(post "/settings/vendors" "{\"name\":\"FeedMasters Pharma\",\"companyId\":\"$COMP_FEED\",\"phone\":\"022-2678900\",\"email\":\"pharma@feedmasters.pk\",\"address\":\"Hyderabad Industrial Estate\",\"town\":\"Hyderabad\",\"openingBalance\":75000,\"balanceType\":\"credit\",\"notes\":\"Vaccine and medicine vendor\"}")
VEND_FEED=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Vendor: FeedMasters Pharma → $VEND_FEED"

RES=$(post "/settings/vendors" "{\"name\":\"Poultry Pro Chicks\",\"companyId\":\"$COMP_PRO\",\"phone\":\"041-8720000\",\"email\":\"chicks@poultrpro.pk\",\"address\":\"Faisalabad\",\"town\":\"Faisalabad\",\"openingBalance\":0,\"balanceType\":\"credit\",\"notes\":\"Day-old chick supplier\"}")
VEND_CHICK=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Vendor: Poultry Pro Chicks → $VEND_CHICK"

# ── 12. CUSTOMERS ─────────────────────────────────────────────
head "SETTINGS — Customers"
RES=$(post "/settings/customers" "{\"name\":\"Al-Madina Poultry Shop\",\"phone\":\"03212345678\",\"code\":\"CUST-001\",\"email\":\"almadina@shop.pk\",\"address\":\"Shop 5, Korangi Market\",\"townId\":\"$TOWN_KHI\",\"sectorId\":\"$SEC_KORANGI\",\"salesmanId\":\"$SALES_USM\",\"companyId\":\"$COMP_AGRI\",\"discountSchemeId\":\"$DS_BULK\",\"creditLimit\":500000,\"openingBalance\":25000,\"balanceType\":\"debit\",\"isActive\":true,\"notes\":\"Regular bulk buyer\"}")
CUST_MADINA=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Customer: Al-Madina Poultry → $CUST_MADINA"

RES=$(post "/settings/customers" "{\"name\":\"Bismillah Murgh Centre\",\"phone\":\"03331122334\",\"code\":\"CUST-002\",\"email\":\"bismillah@murgh.pk\",\"address\":\"Landhi Colony, Block 5\",\"townId\":\"$TOWN_KHI\",\"sectorId\":\"$SEC_LANDHI\",\"salesmanId\":\"$SALES_USM\",\"discountSchemeId\":\"$DS_FLAT\",\"creditLimit\":300000,\"openingBalance\":0,\"balanceType\":\"credit\",\"isActive\":true,\"notes\":\"Retail chicken shop\"}")
CUST_BISM=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Customer: Bismillah Murgh → $CUST_BISM"

RES=$(post "/settings/customers" "{\"name\":\"Hassan Poultry Farm\",\"phone\":\"03009988776\",\"code\":\"CUST-003\",\"email\":\"hassan@farm.pk\",\"address\":\"Latifabad Unit 10\",\"townId\":\"$TOWN_HYD\",\"sectorId\":\"$SEC_LAT\",\"salesmanId\":\"$SALES_RIZ\",\"creditLimit\":200000,\"openingBalance\":10000,\"balanceType\":\"debit\",\"isActive\":true,\"notes\":\"Hyderabad buyer\"}")
CUST_HASAN=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Customer: Hassan Poultry Farm → $CUST_HASAN"

RES=$(post "/settings/customers" "{\"name\":\"Gulberg Live Chicken\",\"phone\":\"04211223344\",\"code\":\"CUST-004\",\"email\":\"gulberg@live.pk\",\"address\":\"Main Boulevard, Gulberg\",\"townId\":\"$TOWN_LHR\",\"sectorId\":\"$SEC_GLB\",\"salesmanId\":\"$SALES_RIZ\",\"creditLimit\":400000,\"openingBalance\":0,\"balanceType\":\"credit\",\"isActive\":true,\"notes\":\"Lahore wholesale buyer\"}")
CUST_GULB=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Customer: Gulberg Live Chicken → $CUST_GULB"

# ── 13. ACCOUNTS ──────────────────────────────────────────────
head "SETTINGS — Accounts"
RES=$(post "/settings/accounts" '{"accountName":"Cash in Hand","accountCode":"1001","accountType":"asset","openingBalance":250000,"balanceType":"debit","isActive":true,"description":"Petty cash and daily transactions"}')
ACC_CASH=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Account: Cash in Hand → $ACC_CASH"

RES=$(post "/settings/accounts" '{"accountName":"Bank — HBL Current","accountCode":"1002","accountType":"asset","openingBalance":1500000,"balanceType":"debit","isActive":true,"description":"HBL main current account"}')
ACC_BANK=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Account: Bank HBL → $ACC_BANK"

RES=$(post "/settings/accounts" '{"accountName":"Sales Revenue","accountCode":"4001","accountType":"income","openingBalance":0,"balanceType":"credit","isActive":true,"description":"Chicken and poultry sales"}')
ACC_SALES=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Account: Sales Revenue → $ACC_SALES"

RES=$(post "/settings/accounts" '{"accountName":"Feed Purchase Expense","accountCode":"5001","accountType":"expense","openingBalance":0,"balanceType":"debit","isActive":true,"description":"Poultry feed purchase costs"}')
ACC_FEED_EXP=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Account: Feed Purchase Expense → $ACC_FEED_EXP"

RES=$(post "/settings/accounts" '{"accountName":"Medicine & Vaccine Expense","accountCode":"5002","accountType":"expense","openingBalance":0,"balanceType":"debit","isActive":true,"description":"Vaccine and medicine costs"}')
ACC_MED_EXP=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Account: Medicine Expense → $ACC_MED_EXP"

# ── 14. OPENING STOCK ─────────────────────────────────────────
head "SETTINGS — Opening Stock"
RES=$(post "/settings/openings/stock" "{\"productId\":\"$PROD_STARTER\",\"quantity\":500,\"rate\":4300,\"date\":\"2026-01-01\"}")
ok "Opening Stock: Starter Feed 500kg → $(echo "$RES" | jq -r '.data.id // .id // empty')"

RES=$(post "/settings/openings/stock" "{\"productId\":\"$PROD_GROWER\",\"quantity\":300,\"rate\":4100,\"date\":\"2026-01-01\"}")
ok "Opening Stock: Grower Feed 300kg → $(echo "$RES" | jq -r '.data.id // .id // empty')"

RES=$(post "/settings/openings/stock" "{\"productId\":\"$PROD_NDV\",\"quantity\":20,\"rate\":700,\"date\":\"2026-01-01\"}")
ok "Opening Stock: Newcastle Vaccine 20pcs → $(echo "$RES" | jq -r '.data.id // .id // empty')"

# ── 15. OPENING RECEIVABLES & PAYABLES ────────────────────────
head "SETTINGS — Opening Receivables"
RES=$(post "/settings/openings/receivables" "{\"customerId\":\"$CUST_MADINA\",\"amount\":25000,\"date\":\"2026-01-01\",\"notes\":\"Opening balance carried forward\"}")
ok "Opening Receivable: Al-Madina 25k → $(echo "$RES" | jq -r '.data.id // .id // empty')"

RES=$(post "/settings/openings/receivables" "{\"customerId\":\"$CUST_HASAN\",\"amount\":10000,\"date\":\"2026-01-01\",\"notes\":\"Previous season balance\"}")
ok "Opening Receivable: Hassan Farm 10k → $(echo "$RES" | jq -r '.data.id // .id // empty')"

head "SETTINGS — Opening Payables"
RES=$(post "/settings/openings/payables" "{\"vendorId\":\"$VEND_AGRI\",\"amount\":150000,\"date\":\"2026-01-01\",\"notes\":\"Feed purchase outstanding\"}")
ok "Opening Payable: AgriTech 150k → $(echo "$RES" | jq -r '.data.id // .id // empty')"

RES=$(post "/settings/openings/payables" "{\"vendorId\":\"$VEND_FEED\",\"amount\":75000,\"date\":\"2026-01-01\",\"notes\":\"Vaccine supply outstanding\"}")
ok "Opening Payable: FeedMasters 75k → $(echo "$RES" | jq -r '.data.id // .id // empty')"

# ═══════════════════════════════════════════════════════════════
#  POULTRY MODULE
# ═══════════════════════════════════════════════════════════════

# ── 16. FEED SCHEDULES ────────────────────────────────────────
head "POULTRY — Feed Schedules"
RES=$(post "/poultry/feed-schedules" "{\"name\":\"Broiler Pre-Starter (Day 0-7)\",\"feedType\":\"pre_starter\",\"ageFromDays\":0,\"ageToDays\":7,\"dailyFeedPerBirdGrams\":25,\"productId\":\"$PROD_PRESTARTER\",\"packingId\":\"$PACK_50KG\",\"description\":\"High protein pre-starter phase\"}")
FS_PRESTARTER=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Feed Schedule: Pre-Starter → $FS_PRESTARTER"

RES=$(post "/poultry/feed-schedules" "{\"name\":\"Broiler Starter (Day 7-21)\",\"feedType\":\"starter\",\"ageFromDays\":7,\"ageToDays\":21,\"dailyFeedPerBirdGrams\":65,\"productId\":\"$PROD_STARTER\",\"packingId\":\"$PACK_50KG\",\"description\":\"Starter phase rapid growth\"}")
FS_STARTER=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Feed Schedule: Starter → $FS_STARTER"

RES=$(post "/poultry/feed-schedules" "{\"name\":\"Broiler Grower (Day 21-35)\",\"feedType\":\"grower\",\"ageFromDays\":21,\"ageToDays\":35,\"dailyFeedPerBirdGrams\":120,\"productId\":\"$PROD_GROWER\",\"packingId\":\"$PACK_50KG\",\"description\":\"Grower phase muscle development\"}")
FS_GROWER=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Feed Schedule: Grower → $FS_GROWER"

RES=$(post "/poultry/feed-schedules" "{\"name\":\"Broiler Finisher (Day 35+)\",\"feedType\":\"finisher\",\"ageFromDays\":35,\"ageToDays\":42,\"dailyFeedPerBirdGrams\":165,\"productId\":\"$PROD_FINISHER\",\"packingId\":\"$PACK_50KG\",\"description\":\"Finisher phase market weight\"}")
FS_FINISHER=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Feed Schedule: Finisher → $FS_FINISHER"

# ── 17. VACCINE SCHEDULES ─────────────────────────────────────
head "POULTRY — Vaccine Schedules"
RES=$(post "/poultry/vaccine-schedules" "{\"name\":\"Newcastle (La Sota) Day 7\",\"vaccineType\":\"newcastle\",\"targetAgeDays\":7,\"administrationRoute\":\"eye_drop\",\"dosePerBird\":1,\"productId\":\"$PROD_NDV\",\"boosterRequired\":true,\"boosterIntervalDays\":14,\"description\":\"First ND vaccination via eye drop\"}")
VS_NDV1=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Vaccine Schedule: Newcastle Day 7 → $VS_NDV1"

RES=$(post "/poultry/vaccine-schedules" "{\"name\":\"Gumboro (IBD) Day 14\",\"vaccineType\":\"gumboro\",\"targetAgeDays\":14,\"administrationRoute\":\"drinking_water\",\"dosePerBird\":1,\"productId\":\"$PROD_IBD\",\"boosterRequired\":true,\"boosterIntervalDays\":7,\"description\":\"First IBD vaccination in drinking water\"}")
VS_IBD1=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Vaccine Schedule: Gumboro Day 14 → $VS_IBD1"

RES=$(post "/poultry/vaccine-schedules" "{\"name\":\"Infectious Bronchitis Day 10\",\"vaccineType\":\"infectious_bronchitis\",\"targetAgeDays\":10,\"administrationRoute\":\"spray\",\"dosePerBird\":1,\"productId\":\"$PROD_IB\",\"boosterRequired\":false,\"description\":\"IB spray vaccination\"}")
VS_IB=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Vaccine Schedule: IB Day 10 → $VS_IB"

RES=$(post "/poultry/vaccine-schedules" "{\"name\":\"Newcastle (La Sota) Day 21 Booster\",\"vaccineType\":\"newcastle\",\"targetAgeDays\":21,\"administrationRoute\":\"drinking_water\",\"dosePerBird\":1,\"productId\":\"$PROD_NDV\",\"boosterRequired\":false,\"description\":\"ND booster in drinking water\"}")
VS_NDV2=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Vaccine Schedule: Newcastle Booster Day 21 → $VS_NDV2"

# ── 18. FLOCKS ────────────────────────────────────────────────
head "POULTRY — Flocks"
RES=$(post "/poultry/flocks" "{\"flockNo\":\"BF-2026-001\",\"flockName\":\"Spring Batch Alpha\",\"birdType\":\"broiler\",\"breed\":\"Ross 308\",\"placementDate\":\"2026-04-01\",\"initialBirdsCount\":5000,\"shedNo\":\"Shed-A\",\"vendorId\":\"$VEND_CHICK\",\"placementWeightKg\":0.042,\"targetWeightKg\":2.5,\"targetAgeDays\":42,\"feedScheduleIds\":[\"$FS_PRESTARTER\",\"$FS_STARTER\",\"$FS_GROWER\",\"$FS_FINISHER\"],\"vaccineScheduleIds\":[\"$VS_NDV1\",\"$VS_IBD1\",\"$VS_IB\",\"$VS_NDV2\"],\"status\":\"sold\",\"closureDate\":\"2026-05-13\",\"closureReason\":\"All birds sold to market\",\"notes\":\"First batch of 2026 spring season\"}")
FLOCK_A=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Flock: Spring Batch Alpha → $FLOCK_A"

RES=$(post "/poultry/flocks" "{\"flockNo\":\"BF-2026-002\",\"flockName\":\"Spring Batch Beta\",\"birdType\":\"broiler\",\"breed\":\"Cobb 500\",\"placementDate\":\"2026-04-10\",\"initialBirdsCount\":4000,\"shedNo\":\"Shed-B\",\"vendorId\":\"$VEND_CHICK\",\"placementWeightKg\":0.040,\"targetWeightKg\":2.3,\"targetAgeDays\":40,\"feedScheduleIds\":[\"$FS_PRESTARTER\",\"$FS_STARTER\",\"$FS_GROWER\",\"$FS_FINISHER\"],\"vaccineScheduleIds\":[\"$VS_NDV1\",\"$VS_IBD1\",\"$VS_IB\",\"$VS_NDV2\"],\"status\":\"active\",\"notes\":\"Second batch ongoing\"}")
FLOCK_B=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Flock: Spring Batch Beta → $FLOCK_B"

RES=$(post "/poultry/flocks" "{\"flockNo\":\"LF-2026-001\",\"flockName\":\"Layer Flock Gamma\",\"birdType\":\"layer\",\"breed\":\"Lohmann Brown\",\"placementDate\":\"2026-03-01\",\"initialBirdsCount\":3000,\"shedNo\":\"Shed-C\",\"vendorId\":\"$VEND_CHICK\",\"placementWeightKg\":0.038,\"targetWeightKg\":1.8,\"targetAgeDays\":500,\"feedScheduleIds\":[\"$FS_STARTER\"],\"vaccineScheduleIds\":[\"$VS_NDV1\",\"$VS_IB\"],\"status\":\"active\",\"notes\":\"Layer flock for egg production\"}")
FLOCK_C=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Flock: Layer Gamma → $FLOCK_C"

# ── 19. FLOCK FEEDS ───────────────────────────────────────────
head "POULTRY — Flock Feeds (Flock A — Day 1 to 42)"
FEED_DAYS=(1 3 5 7 10 14 18 21 25 28 32 35 38 42)
FEED_CONSUMED=(120 180 250 320 480 720 960 1100 1450 1680 2000 2200 2450 2600)
FEED_WEIGHT=(0.05 0.08 0.12 0.18 0.28 0.42 0.60 0.80 1.10 1.35 1.65 1.90 2.15 2.48)
FEED_MORTALITY=(0 2 1 3 5 4 3 2 4 3 2 1 2 0)
FEED_SCHEDIDS=("$FS_PRESTARTER" "$FS_PRESTARTER" "$FS_PRESTARTER" "$FS_STARTER" "$FS_STARTER" "$FS_STARTER" "$FS_STARTER" "$FS_GROWER" "$FS_GROWER" "$FS_GROWER" "$FS_GROWER" "$FS_FINISHER" "$FS_FINISHER" "$FS_FINISHER")
FEED_PRODS=("$PROD_PRESTARTER" "$PROD_PRESTARTER" "$PROD_PRESTARTER" "$PROD_STARTER" "$PROD_STARTER" "$PROD_STARTER" "$PROD_STARTER" "$PROD_GROWER" "$PROD_GROWER" "$PROD_GROWER" "$PROD_GROWER" "$PROD_FINISHER" "$PROD_FINISHER" "$PROD_FINISHER")

for i in "${!FEED_DAYS[@]}"; do
  DAY="${FEED_DAYS[$i]}"
  DATE=$(date -v+"$(( DAY - 1 ))"d -j -f "%Y-%m-%d" "2026-04-01" "+%Y-%m-%d" 2>/dev/null || date -d "2026-04-01 +$((DAY-1)) days" "+%Y-%m-%d" 2>/dev/null)
  RES=$(post "/poultry/flock-feeds" "{\"flockId\":\"$FLOCK_A\",\"date\":\"$DATE\",\"ageDays\":$DAY,\"birdsCount\":$((5000 - 31)),\"mortalityCount\":${FEED_MORTALITY[$i]},\"feedConsumedKg\":${FEED_CONSUMED[$i]},\"averageWeightKg\":${FEED_WEIGHT[$i]},\"productId\":\"${FEED_PRODS[$i]}\",\"feedScheduleId\":\"${FEED_SCHEDIDS[$i]}\",\"batchNo\":\"BATCH-A-$(printf '%02d' $DAY)\",\"notes\":\"Day $DAY daily feed record\"}")
  ID=$(echo "$RES" | jq -r '.data.id // .id // empty')
  if [ -n "$ID" ]; then ok "Flock Feed Day $DAY → $ID"
  else fail "Flock Feed Day $DAY failed: $(echo $RES | jq -r '.message // .')"; fi
done

head "POULTRY — Flock Feeds (Flock B — Day 1 to 28)"
B_DAYS=(1 3 7 10 14 18 21 25 28)
B_CONSUMED=(95 145 260 385 575 760 880 1150 1340)
B_WEIGHT=(0.05 0.08 0.18 0.28 0.42 0.60 0.80 1.10 1.35)
B_SCHED=("$FS_PRESTARTER" "$FS_PRESTARTER" "$FS_STARTER" "$FS_STARTER" "$FS_STARTER" "$FS_STARTER" "$FS_GROWER" "$FS_GROWER" "$FS_GROWER")
B_PROD=("$PROD_PRESTARTER" "$PROD_PRESTARTER" "$PROD_STARTER" "$PROD_STARTER" "$PROD_STARTER" "$PROD_STARTER" "$PROD_GROWER" "$PROD_GROWER" "$PROD_GROWER")

for i in "${!B_DAYS[@]}"; do
  DAY="${B_DAYS[$i]}"
  DATE=$(date -v+"$(( DAY - 1 ))"d -j -f "%Y-%m-%d" "2026-04-10" "+%Y-%m-%d" 2>/dev/null || date -d "2026-04-10 +$((DAY-1)) days" "+%Y-%m-%d" 2>/dev/null)
  RES=$(post "/poultry/flock-feeds" "{\"flockId\":\"$FLOCK_B\",\"date\":\"$DATE\",\"ageDays\":$DAY,\"birdsCount\":4000,\"mortalityCount\":0,\"feedConsumedKg\":${B_CONSUMED[$i]},\"averageWeightKg\":${B_WEIGHT[$i]},\"productId\":\"${B_PROD[$i]}\",\"feedScheduleId\":\"${B_SCHED[$i]}\",\"batchNo\":\"BATCH-B-$(printf '%02d' $DAY)\",\"notes\":\"Day $DAY feed record\"}")
  ID=$(echo "$RES" | jq -r '.data.id // .id // empty')
  if [ -n "$ID" ]; then ok "Flock B Feed Day $DAY → $ID"
  else fail "Flock B Feed Day $DAY: $(echo $RES | jq -r '.message // .')"; fi
done

# ── 20. FLOCK VACCINES ────────────────────────────────────────
head "POULTRY — Flock Vaccines (Flock A)"
VAX_RECORDS=(
  "$FLOCK_A|2026-04-08|7|4990|$PROD_NDV|eye_drop|1|$VS_NDV1|Dr. Ahmed Khan|First ND vaccination eye drop"
  "$FLOCK_A|2026-04-11|10|4990|$PROD_IB|spray|1|$VS_IB|Dr. Ahmed Khan|IB spray vaccination"
  "$FLOCK_A|2026-04-15|14|4980|$PROD_IBD|drinking_water|1|$VS_IBD1|Farm Staff|Gumboro drinking water"
  "$FLOCK_A|2026-04-22|21|4960|$PROD_NDV|drinking_water|1|$VS_NDV2|Farm Staff|Newcastle booster"
  "$FLOCK_A|2026-04-21|20|4960|$PROD_IBD|drinking_water|1|$VS_IBD1|Farm Staff|Gumboro booster day 20"
)

for rec in "${VAX_RECORDS[@]}"; do
  IFS='|' read -r fid vdate vage vbirds vprod vroute vdose vsched vadmin vnote <<< "$rec"
  RES=$(post "/poultry/flock-vaccines" "{\"flockId\":\"$fid\",\"date\":\"$vdate\",\"ageDays\":$vage,\"birdsVaccinated\":$vbirds,\"productId\":\"$vprod\",\"administrationRoute\":\"$vroute\",\"dosePerBird\":$vdose,\"vaccineScheduleId\":\"$vsched\",\"administeredBy\":\"$vadmin\",\"notes\":\"$vnote\"}")
  ID=$(echo "$RES" | jq -r '.data.id // .id // empty')
  if [ -n "$ID" ]; then ok "Flock A Vaccine Day $vage ($vroute) → $ID"
  else fail "Flock A Vaccine Day $vage: $(echo $RES | jq -r '.message // .')"; fi
done

head "POULTRY — Flock Vaccines (Flock B)"
VAX_B_RECORDS=(
  "$FLOCK_B|2026-04-17|7|3998|$PROD_NDV|eye_drop|1|$VS_NDV1|Dr. Ahmed Khan|First ND eye drop"
  "$FLOCK_B|2026-04-20|10|3998|$PROD_IB|spray|1|$VS_IB|Farm Staff|IB spray"
  "$FLOCK_B|2026-04-24|14|3996|$PROD_IBD|drinking_water|1|$VS_IBD1|Farm Staff|Gumboro day 14"
  "$FLOCK_B|2026-05-01|21|3994|$PROD_NDV|drinking_water|1|$VS_NDV2|Farm Staff|ND booster day 21"
)
for rec in "${VAX_B_RECORDS[@]}"; do
  IFS='|' read -r fid vdate vage vbirds vprod vroute vdose vsched vadmin vnote <<< "$rec"
  RES=$(post "/poultry/flock-vaccines" "{\"flockId\":\"$fid\",\"date\":\"$vdate\",\"ageDays\":$vage,\"birdsVaccinated\":$vbirds,\"productId\":\"$vprod\",\"administrationRoute\":\"$vroute\",\"dosePerBird\":$vdose,\"vaccineScheduleId\":\"$vsched\",\"administeredBy\":\"$vadmin\",\"notes\":\"$vnote\"}")
  ID=$(echo "$RES" | jq -r '.data.id // .id // empty')
  if [ -n "$ID" ]; then ok "Flock B Vaccine Day $vage → $ID"
  else fail "Flock B Vaccine Day $vage: $(echo $RES | jq -r '.message // .')"; fi
done

# ── 21. CHICKEN INVOICES ──────────────────────────────────────
head "POULTRY — Chicken Invoices (Flock A — Sold)"
RES=$(post "/poultry/chicken-invoices" "{\"invoiceNo\":\"CI-2026-001\",\"flockId\":\"$FLOCK_A\",\"customerId\":\"$CUST_MADINA\",\"invoiceDate\":\"2026-05-10\",\"saleType\":\"live_weight\",\"birdsCount\":2000,\"totalLiveWeightKg\":5000,\"dressedWeightKg\":0,\"pricePerKg\":480,\"discountPercent\":3,\"taxPercent\":0,\"advanceReceived\":500000,\"vehicleNo\":\"KHI-1234\",\"driverName\":\"Hamid Ali\",\"salesmanId\":\"$SALES_USM\",\"notes\":\"First sale batch - Al-Madina Poultry\"}")
INV1=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Invoice CI-2026-001 → $INV1"

RES=$(post "/poultry/chicken-invoices" "{\"invoiceNo\":\"CI-2026-002\",\"flockId\":\"$FLOCK_A\",\"customerId\":\"$CUST_BISM\",\"invoiceDate\":\"2026-05-11\",\"saleType\":\"live_weight\",\"birdsCount\":1500,\"totalLiveWeightKg\":3750,\"dressedWeightKg\":0,\"pricePerKg\":475,\"discountPercent\":0,\"taxPercent\":0,\"advanceReceived\":1000000,\"vehicleNo\":\"KHI-5678\",\"driverName\":\"Salim Shah\",\"salesmanId\":\"$SALES_USM\",\"notes\":\"Second batch sale - Bismillah\"}")
INV2=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Invoice CI-2026-002 → $INV2"

RES=$(post "/poultry/chicken-invoices" "{\"invoiceNo\":\"CI-2026-003\",\"flockId\":\"$FLOCK_A\",\"customerId\":\"$CUST_HASAN\",\"invoiceDate\":\"2026-05-12\",\"saleType\":\"per_bird\",\"birdsCount\":969,\"totalLiveWeightKg\":2400,\"dressedWeightKg\":0,\"pricePerKg\":470,\"discountPercent\":2,\"taxPercent\":0,\"advanceReceived\":700000,\"vehicleNo\":\"HYD-9012\",\"driverName\":\"Zubair Qureshi\",\"salesmanId\":\"$SALES_RIZ\",\"notes\":\"Final clearance - Hassan Farm\"}")
INV3=$(echo "$RES" | jq -r '.data.id // .id // empty')
ok "Invoice CI-2026-003 → $INV3"

# ── 22. DEMAND ANALYSIS REPORT ────────────────────────────────
head "POULTRY — Reports"
info "Fetching Flock B Status Report..."
REPORT1=$(curl -s "$BASE_URL/poultry/reports/flock-status?flockId=$FLOCK_B" \
  -H "Authorization: Bearer $TOKEN")
echo "$REPORT1" | jq '.data // .' 2>/dev/null | head -30
ok "Flock Status Report done"

info "Fetching Demand Analysis (Flock B, 7 days ahead)..."
REPORT2=$(curl -s "$BASE_URL/poultry/reports/demand-analysis?flockIds[]=$FLOCK_B&daysAhead=7" \
  -H "Authorization: Bearer $TOKEN")
echo "$REPORT2" | jq '.data // .' 2>/dev/null | head -30
ok "Demand Analysis Report done"

# ── SUMMARY ───────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}╔════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║        SEED COMPLETE — IDs Summary      ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════╝${NC}"
echo -e "${CYAN}Units:${NC}        kg=$UNIT_KG  pcs=$UNIT_PCS  g=$UNIT_G  L=$UNIT_L"
echo -e "${CYAN}Packings:${NC}     50kg=$PACK_50KG  25kg=$PACK_25KG  1L=$PACK_1L"
echo -e "${CYAN}Companies:${NC}    AgriTech=$COMP_AGRI  FeedMasters=$COMP_FEED  Pro=$COMP_PRO"
echo -e "${CYAN}Prod Groups:${NC}  Feed=$PG_FEED  Vax=$PG_VAX  Equip=$PG_EQP"
echo -e "${CYAN}Products:${NC}     PreStarter=$PROD_PRESTARTER  Starter=$PROD_STARTER"
echo -e "              Grower=$PROD_GROWER  Finisher=$PROD_FINISHER"
echo -e "              NDV=$PROD_NDV  IBD=$PROD_IBD  IB=$PROD_IB  Vit=$PROD_VIT"
echo -e "${CYAN}Towns:${NC}        Karachi=$TOWN_KHI  Hyd=$TOWN_HYD  Lhr=$TOWN_LHR  Fsd=$TOWN_FSD"
echo -e "${CYAN}Vendors:${NC}      AgriTech=$VEND_AGRI  FeedMasters=$VEND_FEED  Chicks=$VEND_CHICK"
echo -e "${CYAN}Customers:${NC}    AlMadina=$CUST_MADINA  Bismillah=$CUST_BISM  Hassan=$CUST_HASAN  Gulberg=$CUST_GULB"
echo -e "${CYAN}Salesmen:${NC}     Usman=$SALES_USM  Rizwan=$SALES_RIZ"
echo -e "${CYAN}FeedScheds:${NC}   PreStarter=$FS_PRESTARTER  Starter=$FS_STARTER  Grower=$FS_GROWER  Finisher=$FS_FINISHER"
echo -e "${CYAN}VaxScheds:${NC}    NDV=$VS_NDV1  IBD=$VS_IBD1  IB=$VS_IB  NDVBooster=$VS_NDV2"
echo -e "${CYAN}Flocks:${NC}       Alpha(sold)=$FLOCK_A  Beta(active)=$FLOCK_B  Gamma(layer)=$FLOCK_C"
echo -e "${CYAN}Invoices:${NC}     $INV1  $INV2  $INV3"
echo -e "${CYAN}Accounts:${NC}     Cash=$ACC_CASH  Bank=$ACC_BANK  Sales=$ACC_SALES  FeedExp=$ACC_FEED_EXP  MedExp=$ACC_MED_EXP"
echo ""
ok "All done! Poultry + Settings data loaded."
echo -e "${YELLOW}→ To seed ledger entries run: ${BOLD}bash seed_ledger_only.sh${NC}"
