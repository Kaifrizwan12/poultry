import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/accounts_reports_nav_controller.dart';
import 'controllers/ledger_controller.dart';

class AccountsReportsScope extends StatefulWidget {
  const AccountsReportsScope({super.key, required this.child});
  final Widget child;

  @override
  State<AccountsReportsScope> createState() => _AccountsReportsScopeState();
}

class _AccountsReportsScopeState extends State<AccountsReportsScope> {
  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccountsReportsNavController()),
        ChangeNotifierProvider(create: (_) => LedgerController()),
      ],
      child: Builder(
        builder: (context) {
          if (!_loaded) {
            _loaded = true;
            // Trigger initial load after the first frame so providers are ready
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.read<LedgerController>().loadAll();
            });
          }
          return widget.child;
        },
      ),
    );
  }
}
