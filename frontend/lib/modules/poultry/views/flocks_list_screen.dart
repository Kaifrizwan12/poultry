import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/models/lookup_option.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/vendors_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/products_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/poultry_definitions.dart';
import '../controllers/flock_controller.dart';
import '../controllers/feed_schedule_controller.dart';
import '../controllers/vaccine_schedule_controller.dart';
import '../controllers/poultry_nav_controller.dart';
import '../models/flock_model.dart';
import '../widgets/flock_card.dart';
import 'flock_form_dialog.dart';

class FlocksListScreen extends StatelessWidget {
  const FlocksListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<FlockController, PoultryNavController>(
      builder: (context, flockCtrl, navCtrl, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Toolbar(flockCtrl: flockCtrl, navCtrl: navCtrl),
            const SizedBox(height: 16),
            Expanded(child: _FlockGrid(flockCtrl: flockCtrl, navCtrl: navCtrl)),
          ],
        );
      },
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.flockCtrl, required this.navCtrl});
  final FlockController flockCtrl;
  final PoultryNavController navCtrl;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 520;
      final filters = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in const ['all', 'active', 'sold', 'closed'])
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(
                    s == 'all' ? 'All' : s[0].toUpperCase() + s.substring(1)),
                selected: flockCtrl.statusFilter == s,
                selectedColor: AppTheme.sidebarActive,
                side: const BorderSide(color: AppTheme.softBorder),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: flockCtrl.statusFilter == s
                      ? AppTheme.terra800
                      : AppTheme.textSecondary,
                ),
                onSelected: (_) => flockCtrl.setStatusFilter(s),
              ),
            ),
        ],
      );

      if (compact) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text('Flocks',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w600))),
            ElevatedButton.icon(
                onPressed: () => _openAdd(context),
                icon: const Icon(Icons.add),
                label: const Text('New Flock')),
          ]),
          const SizedBox(height: 12),
          TextField(
            onChanged: flockCtrl.setSearchQuery,
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search), hintText: 'Search flocks'),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
              scrollDirection: Axis.horizontal, child: filters),
        ]);
      }

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text('Flocks',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w600))),
          Expanded(
              child: TextField(
            onChanged: flockCtrl.setSearchQuery,
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search), hintText: 'Search flocks'),
          )),
          const SizedBox(width: 12),
          ElevatedButton.icon(
              onPressed: () => _openAdd(context),
              icon: const Icon(Icons.add),
              label: const Text('New Flock')),
        ]),
        const SizedBox(height: 12),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: filters),
      ]);
    });
  }

  void _openAdd(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final vendorOptions = context
            .read<VendorsController>()
            .items
            .map((v) => LookupOption(value: v.id, label: v.text('name')))
            .toList();
        final feedScheduleOptions = context
            .read<FeedScheduleController>()
            .items
            .map((f) => LookupOption(value: f.id, label: f.name))
            .toList();
        final vaccineScheduleOptions = context
            .read<VaccineScheduleController>()
            .items
            .map((v) => LookupOption(value: v.id, label: v.name))
            .toList();
        return Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width < 600
                    ? MediaQuery.of(context).size.width - 24
                    : 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: FlockFormDialog(
                controller: context.read<FlockController>(),
                vendorOptions: vendorOptions,
                feedScheduleOptions: feedScheduleOptions,
                vaccineScheduleOptions: vaccineScheduleOptions,
                onSaved: () {},
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FlockGrid extends StatelessWidget {
  const _FlockGrid({required this.flockCtrl, required this.navCtrl});
  final FlockController flockCtrl;
  final PoultryNavController navCtrl;

  @override
  Widget build(BuildContext context) {
    if (flockCtrl.isLoading)
      return const Center(child: CircularProgressIndicator());
    if (flockCtrl.error != null) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 48, color: AppTheme.dangerText),
        const SizedBox(height: 12),
        Text(flockCtrl.error!),
        const SizedBox(height: 12),
        ElevatedButton(
            onPressed: flockCtrl.fetchAll, child: const Text('Retry')),
      ]));
    }

    final items = flockCtrl.filteredItems;
    if (items.isEmpty) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.egg_outlined, size: 64, color: AppTheme.textTertiary),
        const SizedBox(height: 12),
        Text('No flocks yet',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textSecondary)),
      ]));
    }

    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 900
          ? 3
          : constraints.maxWidth > 600
              ? 2
              : 1;
      return GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.6,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => FlockCard(
          flock: items[index],
          onTap: () => navCtrl.openFlock(items[index].id),
        ),
      );
    });
  }
}
