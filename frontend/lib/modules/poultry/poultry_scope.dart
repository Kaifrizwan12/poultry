import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/feed_schedule_controller.dart';
import 'controllers/vaccine_schedule_controller.dart';
import 'controllers/flock_controller.dart';
import 'controllers/flock_feed_controller.dart';
import 'controllers/flock_vaccine_controller.dart';
import 'controllers/chicken_invoice_controller.dart';
import 'controllers/poultry_report_controller.dart';
import 'controllers/poultry_nav_controller.dart';

class PoultryScope extends StatefulWidget {
  const PoultryScope({super.key, required this.child});
  final Widget child;

  @override
  State<PoultryScope> createState() => _PoultryScopeState();
}

class _PoultryScopeState extends State<PoultryScope> {
  bool _loaded = false;

  Future<void> _bootstrap(BuildContext context) async {
    // Pre-fetch the primary lists; child-entity lists are fetched lazily
    final futures = <Future<void>>[
      context.read<FeedScheduleController>().fetchAll(),
      context.read<VaccineScheduleController>().fetchAll(),
      context.read<FlockController>().fetchAll(),
    ];
    await Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PoultryNavController()),
        ChangeNotifierProvider(create: (_) => FeedScheduleController()),
        ChangeNotifierProvider(create: (_) => VaccineScheduleController()),
        ChangeNotifierProvider(create: (_) => FlockController()),
        ChangeNotifierProvider(create: (_) => FlockFeedController()),
        ChangeNotifierProvider(create: (_) => FlockVaccineController()),
        ChangeNotifierProvider(create: (_) => ChickenInvoiceController()),
        ChangeNotifierProvider(create: (_) => PoultryReportController()),
      ],
      child: Builder(
        builder: (context) {
          if (!_loaded) {
            _loaded = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _bootstrap(context);
            });
          }
          return widget.child;
        },
      ),
    );
  }
}
