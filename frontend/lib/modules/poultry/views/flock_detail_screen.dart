import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/models/lookup_option.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/vendors_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/flock_controller.dart';
import '../controllers/flock_feed_controller.dart';
import '../controllers/flock_vaccine_controller.dart';
import '../controllers/chicken_invoice_controller.dart';
import '../controllers/feed_schedule_controller.dart';
import '../controllers/vaccine_schedule_controller.dart';
import '../controllers/poultry_nav_controller.dart';
import '../models/flock_model.dart';
import '../widgets/flock_status_badge.dart';
import 'chicken_invoice_screen.dart';
import 'flock_form_dialog.dart';
import 'flock_feed_screen.dart';
import 'flock_vaccine_screen.dart';
import 'flock_status_report_screen.dart';


class FlockDetailScreen extends StatefulWidget {
  const FlockDetailScreen({super.key, required this.flockId});
  final String flockId;

  @override
  State<FlockDetailScreen> createState() => _FlockDetailScreenState();
}

class _FlockDetailScreenState extends State<FlockDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<PoultryNavController>().selectFlockTab(_tabController.index);
      }
    });
    // Pre-fetch child data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FlockFeedController>().fetchByFlock(widget.flockId);
      context.read<FlockVaccineController>().fetchByFlock(widget.flockId);
      context.read<ChickenInvoiceController>().fetchByFlock(widget.flockId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flock = context.watch<FlockController>().findById(widget.flockId);
    if (flock == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Breadcrumb(flockName: flock.flockName),
        const SizedBox(height: 12),
        _HeaderCard(flock: flock),
        const SizedBox(height: 16),
        Container(
          decoration: AppTheme.cardDecor,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.terra600,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.terra400,
            tabs: const [
              Tab(text: 'Feed Log'),
              Tab(text: 'Vaccine Log'),
              Tab(text: 'Sales'),
              Tab(text: 'Status'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              FlockFeedScreen(flockId: widget.flockId, flock: flock),
              FlockVaccineScreen(flockId: widget.flockId, flock: flock),
              ChickenInvoiceScreen(flockId: widget.flockId, flock: flock),
              FlockStatusReportScreen(flockId: widget.flockId),
            ],
          ),
        ),
      ],
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.flockName});
  final String flockName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.read<PoultryNavController>().closeFlock(),
          child: Row(children: [
            const Icon(Icons.arrow_back_ios_new, size: 14, color: AppTheme.terra600),
            const SizedBox(width: 4),
            Text('Flocks', style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.terra600, fontWeight: FontWeight.w600)),
          ]),
        ),
        Text(' › ', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
        Expanded(
          child: Text(flockName, style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.flock});
  final FlockModel flock;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTheme.cardPadding,
      decoration: AppTheme.cardDecor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(flock.flockName, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(flock.flockNo, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary)),
            ])),
            FlockStatusBadge(status: flock.status),
          ]),
          const SizedBox(height: 12),
          Container(height: 1, color: AppTheme.softBorder),
          const SizedBox(height: 12),
          Wrap(spacing: 24, runSpacing: 8, children: [
            _stat('Shed', flock.shedNo),
            _stat('Type', flock.birdType[0].toUpperCase() + flock.birdType.substring(1)),
            _stat('Placed', _date(flock.placementDate)),
            _stat('Age', '${flock.ageDays} days'),
            _stat('Birds', '${flock.currentBirdsCount} / ${flock.initialBirdsCount}'),
            _stat('Mortality', '${flock.mortalityCount} (${flock.mortalityRate.toStringAsFixed(1)}%)'),
            if (flock.targetWeightKg > 0) _stat('Target Wt', '${flock.targetWeightKg} kg'),
            if (flock.targetAgeDays > 0) _stat('Target Age', '${flock.targetAgeDays} d'),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            ElevatedButton.icon(
              onPressed: () => _editFlock(context),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit Flock'),
            ),
            if (flock.isActive) ...[
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _closeFlock(context, flock),
                icon: const Icon(Icons.close_outlined, size: 16),
                label: const Text('Close Flock'),
                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.dangerText,
                    side: BorderSide(color: AppTheme.dangerText)),
              ),
            ],
          ]),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
    ],
  );

  String _date(String iso) {
    try {
      final d = DateTime.parse(iso);
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day.toString().padLeft(2,'0')} ${m[d.month-1]} ${d.year}';
    } catch (_) {
      return iso.split('T').first;
    }
  }

  void _editFlock(BuildContext context) {
    final vendorOptions = context.read<VendorsController>().items
        .map((v) => LookupOption(value: v.id, label: v.text('name'))).toList();
    final feedOpts = context.read<FeedScheduleController>().items
        .map((f) => LookupOption(value: f.id, label: f.name)).toList();
    final vacOpts = context.read<VaccineScheduleController>().items
        .map((v) => LookupOption(value: v.id, label: v.name)).toList();

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width < 600
              ? MediaQuery.of(context).size.width - 24 : 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: FlockFormDialog(
              controller: context.read<FlockController>(),
              vendorOptions: vendorOptions,
              feedScheduleOptions: feedOpts,
              vaccineScheduleOptions: vacOpts,
              item: {'id': flock.id, ...flock.toJson()},
              onSaved: () {},
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _closeFlock(BuildContext context, FlockModel flock) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Flock'),
        content: const Text('Mark this flock as closed? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerText),
            child: const Text('Close Flock'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await context.read<FlockController>().updateItem(flock.id, {
          ...flock.toJson(),
          'status': 'closed',
          'closureDate': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppTheme.dangerText, content: Text(e.toString())));
      }
    }
  }
}
