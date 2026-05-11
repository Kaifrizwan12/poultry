import 'package:farm_mgt_auth/modules/settings/controllers/accounts_controller.dart';
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
import 'package:farm_mgt_auth/modules/settings/controllers/settings_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/towns_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/units_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/vendors_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScope extends StatefulWidget {
  const SettingsScope({
    super.key,
    required this.child,
    this.initialCategoryId,
  });

  final Widget child;
  final String? initialCategoryId;

  @override
  State<SettingsScope> createState() => _SettingsScopeState();
}

class _SettingsScopeState extends State<SettingsScope> {
  bool _loaded = false;

  Future<void> _bootstrap(BuildContext context) async {
    if (!mounted) return;

    // Fetch all 16 controllers in parallel — sequential await meant accounts
    // (13th in the old list) only started after 12 prior round-trips finished.
    await Future.wait([
      context.read<UnitsController>().fetchAll(),
      context.read<PackingsController>().fetchAll(),
      context.read<CompaniesController>().fetchAll(),
      context.read<ProductGroupsController>().fetchAll(),
      context.read<ProductSubGroupsController>().fetchAll(),
      context.read<ProductsController>().fetchAll(),
      context.read<DiscountSchemesController>().fetchAll(),
      context.read<VendorsController>().fetchAll(),
      context.read<TownsController>().fetchAll(),
      context.read<SectorsController>().fetchAll(),
      context.read<CustomersController>().fetchAll(),
      context.read<SalesmenController>().fetchAll(),
      context.read<AccountsController>().fetchAll(),
      context.read<OpeningStockController>().fetchAll(),
      context.read<OpeningReceivablesController>().fetchAll(),
      context.read<OpeningPayablesController>().fetchAll(),
    ]);

    if (!mounted) return;
    final settingsCtrl = context.read<SettingsController>();
    settingsCtrl.markBootstrapComplete();
    if (widget.initialCategoryId != null) {
      settingsCtrl.selectCategory(widget.initialCategoryId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsController()),
        ChangeNotifierProvider(create: (_) => UnitsController()),
        ChangeNotifierProvider(create: (_) => PackingsController()),
        ChangeNotifierProvider(create: (_) => CompaniesController()),
        ChangeNotifierProvider(create: (_) => ProductGroupsController()),
        ChangeNotifierProvider(create: (_) => ProductSubGroupsController()),
        ChangeNotifierProvider(create: (_) => ProductsController()),
        ChangeNotifierProvider(create: (_) => DiscountSchemesController()),
        ChangeNotifierProvider(create: (_) => VendorsController()),
        ChangeNotifierProvider(create: (_) => TownsController()),
        ChangeNotifierProvider(create: (_) => SectorsController()),
        ChangeNotifierProvider(create: (_) => CustomersController()),
        ChangeNotifierProvider(create: (_) => SalesmenController()),
        ChangeNotifierProvider(create: (_) => AccountsController()),
        ChangeNotifierProvider(create: (_) => OpeningStockController()),
        ChangeNotifierProvider(create: (_) => OpeningReceivablesController()),
        ChangeNotifierProvider(create: (_) => OpeningPayablesController()),
      ],
      child: Builder(
        builder: (context) {
          if (!_loaded) {
            _loaded = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _bootstrap(context);
            });
          }
          return widget.child;
        },
      ),
    );
  }
}
