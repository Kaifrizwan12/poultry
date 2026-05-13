import 'package:farm_mgt_auth/modules/settings/controllers/accounts_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/base_settings_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/companies_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/customers_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/discount_schemes_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/opening_payables_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/opening_receivables_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/opening_stock_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/packings_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/product_groups_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/product_sub_groups_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/products_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/salesmen_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/sectors_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/towns_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/units_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/vendors_controller.dart';
import 'package:farm_mgt_auth/modules/settings/models/base_settings_model.dart';
import 'package:farm_mgt_auth/modules/settings/models/lookup_option.dart';
import 'package:farm_mgt_auth/modules/settings/utils/code_generators.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum SettingsFieldType {
  text,
  multiline,
  number,
  dropdown,
  boolToggle,
  date,
  multiSelect,
}

class SettingsFieldConfig {
  const SettingsFieldConfig({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.optionsBuilder,
    this.hintText,
  });

  final String key;
  final String label;
  final SettingsFieldType type;
  final bool required;
  final String? hintText;
  final List<LookupOption> Function(
    BuildContext context,
    Map<String, dynamic> values,
    BaseSettingsModel? item,
  )? optionsBuilder;
}

class SettingsCategoryConfig {
  const SettingsCategoryConfig({
    required this.id,
    required this.title,
    required this.icon,
    required this.addLabel,
    required this.fields,
    required this.listTitleKey,
    required this.listSubtitleKeys,
    this.children = const <SettingsCategoryConfig>[],
    this.initialValues,
  });

  final String id;
  final String title;
  final IconData icon;
  final String addLabel;
  final List<SettingsFieldConfig> fields;
  final String listTitleKey;
  final List<String> listSubtitleKeys;
  final List<SettingsCategoryConfig> children;
  final Map<String, dynamic> Function()? initialValues;

  bool get isOpeningsGroup => children.isNotEmpty;
}

class SettingsDefinitions {
  static SettingsCrudController controllerOf(BuildContext context, String id) {
    switch (id) {
      case 'units':
        return context.read<UnitsController>();
      case 'packings':
        return context.read<PackingsController>();
      case 'companies':
        return context.read<CompaniesController>();
      case 'product_groups':
        return context.read<ProductGroupsController>();
      case 'product_sub_groups':
        return context.read<ProductSubGroupsController>();
      case 'products':
        return context.read<ProductsController>();
      case 'discount_schemes':
        return context.read<DiscountSchemesController>();
      case 'vendors':
        return context.read<VendorsController>();
      case 'towns':
        return context.read<TownsController>();
      case 'sectors':
        return context.read<SectorsController>();
      case 'customers':
        return context.read<CustomersController>();
      case 'salesmen':
        return context.read<SalesmenController>();
      case 'accounts':
        return context.read<AccountsController>();
      case 'opening_stock':
        return context.read<OpeningStockController>();
      case 'opening_receivables':
        return context.read<OpeningReceivablesController>();
      case 'opening_payables':
        return context.read<OpeningPayablesController>();
      default:
        throw StateError('Unknown settings category: $id');
    }
  }

  static List<LookupOption> _optionsFromController(
    SettingsCrudController controller,
    String labelKey,
  ) {
    return controller.items
        .map(
          (item) => LookupOption(value: item.id, label: item.text(labelKey)),
        )
        .toList();
  }

  static List<LookupOption> _unitsOptions(BuildContext context) {
    return _optionsFromController(context.read<UnitsController>(), 'name');
  }

  static List<LookupOption> _packingOptions(BuildContext context) {
    return _optionsFromController(context.read<PackingsController>(), 'name');
  }

  static List<LookupOption> _companyOptions(BuildContext context) {
    return _optionsFromController(context.read<CompaniesController>(), 'name');
  }

  static List<LookupOption> _groupOptions(BuildContext context) {
    return _optionsFromController(
        context.read<ProductGroupsController>(), 'name');
  }

  static List<LookupOption> _subGroupOptions(
    BuildContext context,
    Map<String, dynamic> values,
  ) {
    final groupId = '${values['groupId'] ?? ''}';
    final controller = context.read<ProductSubGroupsController>();
    return controller.whereFieldEquals('groupId', groupId).map((item) {
      return LookupOption(value: item.id, label: item.text('name'));
    }).toList();
  }

  static List<LookupOption> _productOptions(BuildContext context) {
    return _optionsFromController(context.read<ProductsController>(), 'name');
  }

  static List<LookupOption> _townOptions(BuildContext context) {
    return _optionsFromController(context.read<TownsController>(), 'name');
  }

  static List<LookupOption> _sectorOptions(
    BuildContext context,
    Map<String, dynamic> values,
  ) {
    final townId = '${values['townId'] ?? ''}';
    final controller = context.read<SectorsController>();
    return controller.whereFieldEquals('townId', townId).map((item) {
      return LookupOption(value: item.id, label: item.text('name'));
    }).toList();
  }

  static List<LookupOption> _salesmanOptions(BuildContext context) {
    return _optionsFromController(context.read<SalesmenController>(), 'name');
  }

  static List<LookupOption> _schemeOptions(BuildContext context) {
    return _optionsFromController(
      context.read<DiscountSchemesController>(),
      'name',
    );
  }

  static List<LookupOption> _vendorOptions(BuildContext context) {
    return _optionsFromController(context.read<VendorsController>(), 'name');
  }

  static List<LookupOption> _accountOptions(BuildContext context) {
    return _optionsFromController(
        context.read<AccountsController>(), 'accountName');
  }

  static List<LookupOption> _discountReferenceOptions(
    BuildContext context,
    Map<String, dynamic> values,
  ) {
    final applicableTo = '${values['applicableTo'] ?? 'all'}';
    if (applicableTo == 'product_group') {
      return _groupOptions(context);
    }
    if (applicableTo == 'product') {
      return _productOptions(context);
    }
    return const <LookupOption>[];
  }

  static final List<SettingsCategoryConfig> categories =
      <SettingsCategoryConfig>[
    SettingsCategoryConfig(
      id: 'units',
      title: 'Units',
      icon: Icons.straighten_outlined,
      addLabel: 'Add Unit',
      listTitleKey: 'name',
      listSubtitleKeys: const ['abbreviation', 'description'],
      fields: const [
        SettingsFieldConfig(
          key: 'name',
          label: 'Name',
          type: SettingsFieldType.text,
          required: true,
        ),
        SettingsFieldConfig(
          key: 'abbreviation',
          label: 'Abbreviation',
          type: SettingsFieldType.text,
          required: true,
        ),
        SettingsFieldConfig(
          key: 'description',
          label: 'Description',
          type: SettingsFieldType.multiline,
        ),
      ],
    ),
    SettingsCategoryConfig(
      id: 'packings',
      title: 'Packings',
      icon: Icons.inventory_2_outlined,
      addLabel: 'Add Packing',
      listTitleKey: 'name',
      listSubtitleKeys: const ['quantity', 'description'],
      fields: [
        const SettingsFieldConfig(
          key: 'name',
          label: 'Name',
          type: SettingsFieldType.text,
          required: true,
        ),
        SettingsFieldConfig(
          key: 'unitId',
          label: 'Unit',
          type: SettingsFieldType.dropdown,
          required: true,
          optionsBuilder: (context, values, item) => _unitsOptions(context),
        ),
        const SettingsFieldConfig(
          key: 'quantity',
          label: 'Quantity',
          type: SettingsFieldType.number,
          required: true,
        ),
        const SettingsFieldConfig(
          key: 'description',
          label: 'Description',
          type: SettingsFieldType.multiline,
        ),
      ],
    ),
    SettingsCategoryConfig(
      id: 'companies',
      title: 'Companies',
      icon: Icons.apartment_outlined,
      addLabel: 'Add Company',
      listTitleKey: 'name',
      listSubtitleKeys: const ['phone', 'email', 'contactPerson'],
      fields: const [
        SettingsFieldConfig(
            key: 'name',
            label: 'Name',
            type: SettingsFieldType.text,
            required: true),
        SettingsFieldConfig(
            key: 'address',
            label: 'Address',
            type: SettingsFieldType.multiline),
        SettingsFieldConfig(
            key: 'phone', label: 'Phone', type: SettingsFieldType.text),
        SettingsFieldConfig(
            key: 'email', label: 'Email', type: SettingsFieldType.text),
        SettingsFieldConfig(
            key: 'ntn', label: 'NTN', type: SettingsFieldType.text),
        SettingsFieldConfig(
            key: 'strn', label: 'STRN', type: SettingsFieldType.text),
        SettingsFieldConfig(
            key: 'contactPerson',
            label: 'Contact Person',
            type: SettingsFieldType.text),
        SettingsFieldConfig(
            key: 'notes', label: 'Notes', type: SettingsFieldType.multiline),
      ],
    ),
    SettingsCategoryConfig(
      id: 'product_groups',
      title: 'Product Groups',
      icon: Icons.category_outlined,
      addLabel: 'Add Product Group',
      listTitleKey: 'name',
      listSubtitleKeys: const ['description'],
      fields: const [
        SettingsFieldConfig(
            key: 'name',
            label: 'Name',
            type: SettingsFieldType.text,
            required: true),
        SettingsFieldConfig(
            key: 'description',
            label: 'Description',
            type: SettingsFieldType.multiline),
      ],
    ),
    SettingsCategoryConfig(
      id: 'product_sub_groups',
      title: 'Product SubGroups',
      icon: Icons.account_tree_outlined,
      addLabel: 'Add Product SubGroup',
      listTitleKey: 'name',
      listSubtitleKeys: const ['groupId', 'description'],
      fields: [
        const SettingsFieldConfig(
            key: 'name',
            label: 'Name',
            type: SettingsFieldType.text,
            required: true),
        SettingsFieldConfig(
          key: 'groupId',
          label: 'Product Group',
          type: SettingsFieldType.dropdown,
          required: true,
          optionsBuilder: (context, values, item) => _groupOptions(context),
        ),
        const SettingsFieldConfig(
            key: 'description',
            label: 'Description',
            type: SettingsFieldType.multiline),
      ],
    ),
    SettingsCategoryConfig(
      id: 'products',
      title: 'Products',
      icon: Icons.shopping_bag_outlined,
      addLabel: 'Add Product',
      listTitleKey: 'name',
      listSubtitleKeys: const ['code', 'companyId', 'sale1Price', 'salesTaxPercent'],
      fields: [
        const SettingsFieldConfig(
            key: 'name',
            label: 'Name',
            type: SettingsFieldType.text,
            required: true),
        SettingsFieldConfig(
          key: 'companyId',
          label: 'Company',
          type: SettingsFieldType.dropdown,
          optionsBuilder: (context, values, item) => _companyOptions(context),
        ),
        const SettingsFieldConfig(
            key: 'longName', label: 'Long Name', type: SettingsFieldType.text),
        const SettingsFieldConfig(
            key: 'code', label: 'Code', type: SettingsFieldType.text),
        SettingsFieldConfig(
          key: 'groupId',
          label: 'Product Group',
          type: SettingsFieldType.dropdown,
          required: true,
          optionsBuilder: (context, values, item) => _groupOptions(context),
        ),
        SettingsFieldConfig(
          key: 'subGroupId',
          label: 'Product SubGroup',
          type: SettingsFieldType.dropdown,
          optionsBuilder: (context, values, item) =>
              _subGroupOptions(context, values),
        ),
        SettingsFieldConfig(
          key: 'unitId',
          label: 'Unit',
          type: SettingsFieldType.dropdown,
          optionsBuilder: (context, values, item) => _unitsOptions(context),
        ),
        const SettingsFieldConfig(
            key: 'size', label: 'Size', type: SettingsFieldType.number),
        const SettingsFieldConfig(
            key: 'displayOrder',
            label: 'Display Order',
            type: SettingsFieldType.number),
        SettingsFieldConfig(
          key: 'purPackingId',
          label: 'Purchase Packing',
          type: SettingsFieldType.dropdown,
          optionsBuilder: (context, values, item) => _packingOptions(context),
        ),
        SettingsFieldConfig(
          key: 'salePackingId',
          label: 'Sale Packing',
          type: SettingsFieldType.dropdown,
          optionsBuilder: (context, values, item) => _packingOptions(context),
        ),
        const SettingsFieldConfig(
            key: 'purchasePrice',
            label: 'Purchase Price',
            type: SettingsFieldType.number),
        const SettingsFieldConfig(
            key: 'purchaseDiscPercent',
            label: 'Purchase Disc%',
            type: SettingsFieldType.number),
        const SettingsFieldConfig(
            key: 'sale1Price',
            label: 'Sale Price 1',
            type: SettingsFieldType.number),
        const SettingsFieldConfig(
            key: 'sale1DiscPercent',
            label: 'Sale 1 Disc%',
            type: SettingsFieldType.number),
        const SettingsFieldConfig(
            key: 'sale2Price',
            label: 'Sale Price 2',
            type: SettingsFieldType.number),
        const SettingsFieldConfig(
            key: 'sale2DiscPercent',
            label: 'Sale 2 Disc%',
            type: SettingsFieldType.number),
        const SettingsFieldConfig(
            key: 'sale3Price',
            label: 'Sale Price 3',
            type: SettingsFieldType.number),
        const SettingsFieldConfig(
            key: 'sale3DiscPercent',
            label: 'Sale 3 Disc%',
            type: SettingsFieldType.number),
        const SettingsFieldConfig(
            key: 'salesTaxPercent',
            label: 'Sales Tax (%)',
            type: SettingsFieldType.number),
        const SettingsFieldConfig(
            key: 'sedValue',
            label: 'SED Value',
            type: SettingsFieldType.number),
        const SettingsFieldConfig(
            key: 'retailPrice',
            label: 'Retail Price',
            type: SettingsFieldType.number),
        const SettingsFieldConfig(
            key: 'isPoultryItem',
            label: 'Poultry Item',
            type: SettingsFieldType.boolToggle),
        const SettingsFieldConfig(
            key: 'inactiveInAdditions',
            label: 'Inactive in Additions',
            type: SettingsFieldType.boolToggle),
        const SettingsFieldConfig(
            key: 'inactiveOnBonusForSales',
            label: 'Inactive on Bonus for Sales',
            type: SettingsFieldType.boolToggle),
        const SettingsFieldConfig(
            key: 'isActive',
            label: 'Active',
            type: SettingsFieldType.boolToggle),
        const SettingsFieldConfig(
            key: 'description',
            label: 'Description',
            type: SettingsFieldType.multiline),
      ],
    ),
    SettingsCategoryConfig(
      id: 'discount_schemes',
      title: 'Discount Schemes',
      icon: Icons.percent_outlined,
      addLabel: 'Add Discount Scheme',
      listTitleKey: 'name',
      listSubtitleKeys: const ['type', 'value', 'applicableTo'],
      fields: [
        const SettingsFieldConfig(
            key: 'name',
            label: 'Name',
            type: SettingsFieldType.text,
            required: true),
        SettingsFieldConfig(
          key: 'type',
          label: 'Type',
          type: SettingsFieldType.dropdown,
          required: true,
          optionsBuilder: (context, values, item) => const [
            LookupOption(value: 'percentage', label: 'Percentage'),
            LookupOption(value: 'flat', label: 'Flat'),
          ],
        ),
        const SettingsFieldConfig(
            key: 'value',
            label: 'Value',
            type: SettingsFieldType.number,
            required: true),
        SettingsFieldConfig(
          key: 'applicableTo',
          label: 'Applicable To',
          type: SettingsFieldType.dropdown,
          required: true,
          optionsBuilder: (context, values, item) => const [
            LookupOption(value: 'all', label: 'All'),
            LookupOption(value: 'product_group', label: 'Product Group'),
            LookupOption(value: 'product', label: 'Product'),
          ],
        ),
        SettingsFieldConfig(
          key: 'refId',
          label: 'Reference',
          type: SettingsFieldType.dropdown,
          optionsBuilder: (context, values, item) =>
              _discountReferenceOptions(context, values),
        ),
        const SettingsFieldConfig(
            key: 'validFrom',
            label: 'Valid From',
            type: SettingsFieldType.date),
        const SettingsFieldConfig(
            key: 'validTo', label: 'Valid To', type: SettingsFieldType.date),
        const SettingsFieldConfig(
            key: 'notes', label: 'Notes', type: SettingsFieldType.multiline),
      ],
    ),
    SettingsCategoryConfig(
      id: 'vendors',
      title: 'Vendors',
      icon: Icons.storefront_outlined,
      addLabel: 'Add Vendor',
      listTitleKey: 'name',
      listSubtitleKeys: const ['phone', 'email', 'town'],
      fields: [
        const SettingsFieldConfig(
            key: 'name',
            label: 'Name',
            type: SettingsFieldType.text,
            required: true),
        SettingsFieldConfig(
          key: 'companyId',
          label: 'Company',
          type: SettingsFieldType.dropdown,
          optionsBuilder: (context, values, item) => _companyOptions(context),
        ),
        const SettingsFieldConfig(
            key: 'phone', label: 'Phone', type: SettingsFieldType.text),
        const SettingsFieldConfig(
            key: 'email', label: 'Email', type: SettingsFieldType.text),
        const SettingsFieldConfig(
            key: 'address',
            label: 'Address',
            type: SettingsFieldType.multiline),
        const SettingsFieldConfig(
            key: 'town', label: 'Town', type: SettingsFieldType.text),
        const SettingsFieldConfig(
            key: 'openingBalance',
            label: 'Opening Balance',
            type: SettingsFieldType.number),
        SettingsFieldConfig(
          key: 'balanceType',
          label: 'Balance Type',
          type: SettingsFieldType.dropdown,
          optionsBuilder: (context, values, item) => const [
            LookupOption(value: 'debit', label: 'Debit'),
            LookupOption(value: 'credit', label: 'Credit'),
          ],
        ),
        const SettingsFieldConfig(
            key: 'notes', label: 'Notes', type: SettingsFieldType.multiline),
      ],
    ),
    SettingsCategoryConfig(
      id: 'towns',
      title: 'Towns',
      icon: Icons.location_city_outlined,
      addLabel: 'Add Town',
      listTitleKey: 'name',
      listSubtitleKeys: const ['district', 'province'],
      fields: const [
        SettingsFieldConfig(
            key: 'name',
            label: 'Name',
            type: SettingsFieldType.text,
            required: true),
        SettingsFieldConfig(
            key: 'district', label: 'District', type: SettingsFieldType.text),
        SettingsFieldConfig(
            key: 'province', label: 'Province', type: SettingsFieldType.text),
      ],
    ),
    SettingsCategoryConfig(
      id: 'sectors',
      title: 'Sectors',
      icon: Icons.map_outlined,
      addLabel: 'Add Sector',
      listTitleKey: 'name',
      listSubtitleKeys: const ['townId', 'description'],
      fields: [
        const SettingsFieldConfig(
            key: 'name',
            label: 'Name',
            type: SettingsFieldType.text,
            required: true),
        SettingsFieldConfig(
          key: 'townId',
          label: 'Town',
          type: SettingsFieldType.dropdown,
          required: true,
          optionsBuilder: (context, values, item) => _townOptions(context),
        ),
        const SettingsFieldConfig(
            key: 'description',
            label: 'Description',
            type: SettingsFieldType.multiline),
      ],
    ),
    SettingsCategoryConfig(
      id: 'customers',
      title: 'Customers',
      icon: Icons.people_alt_outlined,
      addLabel: 'Add Customer',
      listTitleKey: 'name',
      listSubtitleKeys: const ['code', 'townId', 'sectorId', 'phone', 'email'],
      initialValues: () => <String, dynamic>{
        'code': generatedCustomerCode(),
        'balanceType': 'credit',
        'isActive': true
      },
      fields: [
        const SettingsFieldConfig(
            key: 'name',
            label: 'Name',
            type: SettingsFieldType.text,
            required: true),
        const SettingsFieldConfig(
            key: 'code', label: 'Code', type: SettingsFieldType.text),
        const SettingsFieldConfig(
            key: 'phone',
            label: 'Phone',
            type: SettingsFieldType.text,
            required: true),
        const SettingsFieldConfig(
            key: 'altPhone',
            label: 'Alternate Phone',
            type: SettingsFieldType.text),
        const SettingsFieldConfig(
            key: 'email', label: 'Email', type: SettingsFieldType.text),
        const SettingsFieldConfig(
            key: 'address',
            label: 'Address',
            type: SettingsFieldType.multiline),
        SettingsFieldConfig(
          key: 'townId',
          label: 'Town',
          type: SettingsFieldType.dropdown,
          optionsBuilder: (context, values, item) => _townOptions(context),
        ),
        SettingsFieldConfig(
          key: 'sectorId',
          label: 'Sector',
          type: SettingsFieldType.dropdown,
          optionsBuilder: (context, values, item) =>
              _sectorOptions(context, values),
        ),
        SettingsFieldConfig(
          key: 'salesmanId',
          label: 'Salesman',
          type: SettingsFieldType.dropdown,
          optionsBuilder: (context, values, item) => _salesmanOptions(context),
        ),
        SettingsFieldConfig(
          key: 'companyId',
          label: 'Company',
          type: SettingsFieldType.dropdown,
          optionsBuilder: (context, values, item) => _companyOptions(context),
        ),
        const SettingsFieldConfig(
            key: 'creditLimit',
            label: 'Credit Limit',
            type: SettingsFieldType.number),
        const SettingsFieldConfig(
            key: 'openingBalance',
            label: 'Opening Balance',
            type: SettingsFieldType.number),
        SettingsFieldConfig(
          key: 'balanceType',
          label: 'Balance Type',
          type: SettingsFieldType.dropdown,
          optionsBuilder: (context, values, item) => const [
            LookupOption(value: 'debit', label: 'Debit'),
            LookupOption(value: 'credit', label: 'Credit'),
          ],
        ),
        SettingsFieldConfig(
          key: 'discountSchemeId',
          label: 'Discount Scheme',
          type: SettingsFieldType.dropdown,
          optionsBuilder: (context, values, item) => _schemeOptions(context),
        ),
        const SettingsFieldConfig(
            key: 'isActive',
            label: 'Active',
            type: SettingsFieldType.boolToggle),
        const SettingsFieldConfig(
            key: 'notes', label: 'Notes', type: SettingsFieldType.multiline),
      ],
    ),
    SettingsCategoryConfig(
      id: 'salesmen',
      title: 'Salesmen',
      icon: Icons.badge_outlined,
      addLabel: 'Add Salesman',
      listTitleKey: 'name',
      listSubtitleKeys: const ['code', 'phone', 'email'],
      initialValues: () => <String, dynamic>{
        'code': generatedSalesmanCode(),
        'commissionType': 'none',
        'isActive': true
      },
      fields: [
        const SettingsFieldConfig(
            key: 'name',
            label: 'Name',
            type: SettingsFieldType.text,
            required: true),
        const SettingsFieldConfig(
            key: 'code', label: 'Code', type: SettingsFieldType.text),
        const SettingsFieldConfig(
            key: 'phone',
            label: 'Phone',
            type: SettingsFieldType.text,
            required: true),
        const SettingsFieldConfig(
            key: 'email', label: 'Email', type: SettingsFieldType.text),
        const SettingsFieldConfig(
            key: 'address',
            label: 'Address',
            type: SettingsFieldType.multiline),
        const SettingsFieldConfig(
            key: 'joiningDate',
            label: 'Joining Date',
            type: SettingsFieldType.date),
        const SettingsFieldConfig(
            key: 'baseSalary',
            label: 'Base Salary',
            type: SettingsFieldType.number),
        SettingsFieldConfig(
          key: 'commissionType',
          label: 'Commission Type',
          type: SettingsFieldType.dropdown,
          optionsBuilder: (context, values, item) => const [
            LookupOption(value: 'none', label: 'None'),
            LookupOption(value: 'percentage', label: 'Percentage'),
            LookupOption(value: 'flat', label: 'Flat'),
          ],
        ),
        const SettingsFieldConfig(
            key: 'commissionValue',
            label: 'Commission Value',
            type: SettingsFieldType.number),
        SettingsFieldConfig(
          key: 'assignedTowns',
          label: 'Assigned Towns',
          type: SettingsFieldType.multiSelect,
          optionsBuilder: (context, values, item) => _townOptions(context),
        ),
        const SettingsFieldConfig(
            key: 'isActive',
            label: 'Active',
            type: SettingsFieldType.boolToggle),
        const SettingsFieldConfig(
            key: 'notes', label: 'Notes', type: SettingsFieldType.multiline),
      ],
    ),
    SettingsCategoryConfig(
      id: 'accounts',
      title: 'Accounts Management',
      icon: Icons.account_balance_outlined,
      addLabel: 'Add Account',
      listTitleKey: 'accountName',
      listSubtitleKeys: const [
        'accountCode',
        'accountType',
        'parentAccountId',
        'description',
      ],
      initialValues: () => <String, dynamic>{
        'accountType': 'asset',
        'balanceType': 'debit',
        'isActive': true
      },
      fields: [
        const SettingsFieldConfig(
            key: 'accountName',
            label: 'Account Name',
            type: SettingsFieldType.text,
            required: true),
        const SettingsFieldConfig(
            key: 'accountCode',
            label: 'Account Code',
            type: SettingsFieldType.text,
            required: true),
        SettingsFieldConfig(
          key: 'accountType',
          label: 'Account Type',
          type: SettingsFieldType.dropdown,
          optionsBuilder: (context, values, item) => const [
            LookupOption(value: 'asset', label: 'Asset'),
            LookupOption(value: 'liability', label: 'Liability'),
            LookupOption(value: 'equity', label: 'Equity'),
            LookupOption(value: 'income', label: 'Income'),
            LookupOption(value: 'expense', label: 'Expense'),
          ],
        ),
        SettingsFieldConfig(
          key: 'parentAccountId',
          label: 'Parent Account',
          type: SettingsFieldType.dropdown,
          optionsBuilder: (context, values, item) => _accountOptions(context),
        ),
        const SettingsFieldConfig(
            key: 'openingBalance',
            label: 'Opening Balance',
            type: SettingsFieldType.number),
        SettingsFieldConfig(
          key: 'balanceType',
          label: 'Balance Type',
          type: SettingsFieldType.dropdown,
          optionsBuilder: (context, values, item) => const [
            LookupOption(value: 'debit', label: 'Debit'),
            LookupOption(value: 'credit', label: 'Credit'),
          ],
        ),
        const SettingsFieldConfig(
            key: 'isActive',
            label: 'Active',
            type: SettingsFieldType.boolToggle),
        const SettingsFieldConfig(
            key: 'description',
            label: 'Description',
            type: SettingsFieldType.multiline),
      ],
    ),
    SettingsCategoryConfig(
      id: 'openings',
      title: 'Openings',
      icon: Icons.playlist_add_check_circle_outlined,
      addLabel: 'Add Opening',
      listTitleKey: '',
      listSubtitleKeys: const [],
      fields: const [],
      children: [
        SettingsCategoryConfig(
          id: 'opening_stock',
          title: 'Opening Stock',
          icon: Icons.inventory_outlined,
          addLabel: 'Add Opening Stock',
          listTitleKey: 'productId',
          listSubtitleKeys: ['quantity', 'rate', 'date'],
          fields: [
            SettingsFieldConfig(
              key: 'productId',
              label: 'Product',
              type: SettingsFieldType.dropdown,
              required: true,
              optionsBuilder: (context, values, item) =>
                  _productOptions(context),
            ),
            SettingsFieldConfig(
                key: 'quantity',
                label: 'Quantity',
                type: SettingsFieldType.number,
                required: true),
            SettingsFieldConfig(
                key: 'rate',
                label: 'Rate',
                type: SettingsFieldType.number,
                required: true),
            SettingsFieldConfig(
                key: 'date',
                label: 'Date',
                type: SettingsFieldType.date,
                required: true),
          ],
        ),
        SettingsCategoryConfig(
          id: 'opening_receivables',
          title: 'Opening Receivables',
          icon: Icons.request_quote_outlined,
          addLabel: 'Add Opening Receivable',
          listTitleKey: 'customerId',
          listSubtitleKeys: ['amount', 'date', 'notes'],
          fields: [
            SettingsFieldConfig(
              key: 'customerId',
              label: 'Customer',
              type: SettingsFieldType.dropdown,
              required: true,
              optionsBuilder: (context, values, item) {
                return _optionsFromController(
                  context.read<CustomersController>(),
                  'name',
                );
              },
            ),
            SettingsFieldConfig(
                key: 'amount',
                label: 'Amount',
                type: SettingsFieldType.number,
                required: true),
            SettingsFieldConfig(
                key: 'date',
                label: 'Date',
                type: SettingsFieldType.date,
                required: true),
            SettingsFieldConfig(
                key: 'notes',
                label: 'Notes',
                type: SettingsFieldType.multiline),
          ],
        ),
        SettingsCategoryConfig(
          id: 'opening_payables',
          title: 'Opening Payables',
          icon: Icons.payments_outlined,
          addLabel: 'Add Opening Payable',
          listTitleKey: 'vendorId',
          listSubtitleKeys: ['amount', 'date', 'notes'],
          fields: [
            SettingsFieldConfig(
              key: 'vendorId',
              label: 'Vendor',
              type: SettingsFieldType.dropdown,
              required: true,
              optionsBuilder: (context, values, item) =>
                  _vendorOptions(context),
            ),
            SettingsFieldConfig(
                key: 'amount',
                label: 'Amount',
                type: SettingsFieldType.number,
                required: true),
            SettingsFieldConfig(
                key: 'date',
                label: 'Date',
                type: SettingsFieldType.date,
                required: true),
            SettingsFieldConfig(
                key: 'notes',
                label: 'Notes',
                type: SettingsFieldType.multiline),
          ],
        ),
      ],
    ),
  ];

  static SettingsCategoryConfig categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) {
        return category;
      }
      for (final child in category.children) {
        if (child.id == id) {
          return child;
        }
      }
    }
    throw StateError('Unknown category: $id');
  }
}
