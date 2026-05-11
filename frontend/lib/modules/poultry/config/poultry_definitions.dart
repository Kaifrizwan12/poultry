import 'package:farm_mgt_auth/modules/settings/models/lookup_option.dart';

// ─── Enum option constants ────────────────────────────────────────────────────

const List<LookupOption> kFeedTypes = [
  LookupOption(value: 'pre_starter', label: 'Pre-Starter'),
  LookupOption(value: 'starter', label: 'Starter'),
  LookupOption(value: 'grower', label: 'Grower'),
  LookupOption(value: 'finisher', label: 'Finisher'),
  LookupOption(value: 'layer_mash', label: 'Layer Mash'),
  LookupOption(value: 'breeder', label: 'Breeder'),
];

const List<LookupOption> kVaccineTypes = [
  LookupOption(value: 'newcastle', label: 'Newcastle Disease (ND)'),
  LookupOption(value: 'infectious_bronchitis', label: 'Infectious Bronchitis (IB)'),
  LookupOption(value: 'gumboro', label: 'Gumboro (IBD)'),
  LookupOption(value: 'mareks', label: "Marek's Disease"),
  LookupOption(value: 'avian_influenza', label: 'Avian Influenza (AI)'),
  LookupOption(value: 'fowl_pox', label: 'Fowl Pox'),
  LookupOption(value: 'other', label: 'Other'),
];

const List<LookupOption> kAdministrationRoutes = [
  LookupOption(value: 'drinking_water', label: 'Drinking Water'),
  LookupOption(value: 'eye_drop', label: 'Eye Drop'),
  LookupOption(value: 'spray', label: 'Spray'),
  LookupOption(value: 'injection', label: 'Injection'),
  LookupOption(value: 'wing_stab', label: 'Wing Stab'),
];

const List<LookupOption> kBirdTypes = [
  LookupOption(value: 'broiler', label: 'Broiler'),
  LookupOption(value: 'layer', label: 'Layer'),
  LookupOption(value: 'breeder', label: 'Breeder'),
  LookupOption(value: 'desi', label: 'Desi'),
];

const List<LookupOption> kSaleTypes = [
  LookupOption(value: 'live_weight', label: 'Live Weight'),
  LookupOption(value: 'dressed_weight', label: 'Dressed Weight'),
  LookupOption(value: 'per_bird', label: 'Per Bird'),
];

const List<LookupOption> kFlockStatuses = [
  LookupOption(value: 'active', label: 'Active'),
  LookupOption(value: 'sold', label: 'Sold'),
  LookupOption(value: 'closed', label: 'Closed'),
];

const List<LookupOption> kPaymentStatuses = [
  LookupOption(value: 'unpaid', label: 'Unpaid'),
  LookupOption(value: 'partial', label: 'Partial'),
  LookupOption(value: 'paid', label: 'Paid'),
];

// ─── Label helpers ─────────────────────────────────────────────────────────────

String labelFor(List<LookupOption> options, String value) {
  for (final o in options) {
    if (o.value == value) return o.label;
  }
  return value;
}
