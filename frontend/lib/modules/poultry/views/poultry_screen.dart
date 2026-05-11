import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/poultry_nav_controller.dart';
import 'feed_schedule_screen.dart';
import 'vaccine_schedule_screen.dart';
import 'flocks_list_screen.dart';
import 'flock_detail_screen.dart';
import 'chicken_invoice_screen_standalone.dart';
import 'demand_analysis_screen.dart';

class PoultryScreen extends StatelessWidget {
  const PoultryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PoultryNavController>(
      builder: (context, nav, _) {
        final width = MediaQuery.of(context).size.width;

        if (width < 600) {
          return _MobilePoultryLayout(nav: nav);
        }

        return Padding(
          padding: AppTheme.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PoultryChipBar(nav: nav),
              const SizedBox(height: 14),
              Expanded(child: _PoultryContentArea(nav: nav)),
            ],
          ),
        );
      },
    );
  }
}

// ─── Nav items ────────────────────────────────────────────────────────────────

const List<_NavItem> _kNavItems = [
  _NavItem(id: 'flocks', label: 'Flocks', icon: Icons.egg_outlined),
  _NavItem(id: 'feed_schedules', label: 'Feed Schedules', icon: Icons.restaurant_outlined),
  _NavItem(id: 'vaccine_schedules', label: 'Vaccine Schedules', icon: Icons.vaccines_outlined),
  _NavItem(id: 'invoices', label: 'Chicken Invoices', icon: Icons.receipt_long_outlined),
  _NavItem(id: 'demand', label: 'Demand Analysis', icon: Icons.bar_chart_outlined),
];

class _NavItem {
  const _NavItem({required this.id, required this.label, required this.icon});
  final String id;
  final String label;
  final IconData icon;
}

// ─── Chip Bar (tablet / desktop) ──────────────────────────────────────────────

class _PoultryChipBar extends StatelessWidget {
  const _PoultryChipBar({required this.nav});
  final PoultryNavController nav;

  @override
  Widget build(BuildContext context) {
    final activeSection = nav.selectedSection == 'menu' ? 'flocks' : nav.selectedSection;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _kNavItems.map((item) {
          final selected  = item.id == activeSection;
          final iconColor = selected ? AppTheme.terra800 : AppTheme.textSecondary;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(item.icon, size: 15, color: iconColor),
                const SizedBox(width: 5),
                Text(item.label),
              ]),
              selected: selected,
              selectedColor: AppTheme.terra100,
              backgroundColor: AppTheme.surfaceWhite,
              side: BorderSide(
                color: selected ? AppTheme.terra400 : AppTheme.softBorder,
                width: selected ? 1.5 : 1,
              ),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppTheme.terra800 : AppTheme.textSecondary,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              onSelected: (_) => nav.selectSection(item.id),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Content Area ─────────────────────────────────────────────────────────────

class _PoultryContentArea extends StatelessWidget {
  const _PoultryContentArea({required this.nav});
  final PoultryNavController nav;

  @override
  Widget build(BuildContext context) {
    // If a flock is selected and we're in the flocks section, show detail
    if (nav.selectedSection == 'flocks' && nav.selectedFlockId != null) {
      return FlockDetailScreen(flockId: nav.selectedFlockId!);
    }

    switch (nav.selectedSection) {
      case 'flocks':
        return const FlocksListScreen();
      case 'feed_schedules':
        return const FeedScheduleScreen();
      case 'vaccine_schedules':
        return const VaccineScheduleScreen();
      case 'invoices':
        return const ChickenInvoiceStandaloneScreen();
      case 'demand':
        return const DemandAnalysisScreen();
      default:
        return const FlocksListScreen();
    }
  }
}

// ─── Mobile Layout ────────────────────────────────────────────────────────────

class _MobilePoultryLayout extends StatelessWidget {
  const _MobilePoultryLayout({required this.nav});
  final PoultryNavController nav;

  @override
  Widget build(BuildContext context) {
    // If a flock detail is open
    if (nav.selectedSection == 'flocks' && nav.selectedFlockId != null) {
      return Padding(
        padding: AppTheme.pagePadding(context),
        child: FlockDetailScreen(flockId: nav.selectedFlockId!),
      );
    }

    // If a section is selected (not the menu), show it
    if (nav.selectedSection != 'menu') {
      return Scaffold(
        appBar: AppBar(
          title: Text(_labelForSection(nav.selectedSection)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => nav.selectSection('menu'),
          ),
        ),
        body: Padding(
          padding: AppTheme.pagePadding(context),
          child: _sectionWidget(nav.selectedSection),
        ),
      );
    }

    // Show menu list
    return ListView.builder(
      padding: AppTheme.pagePadding(context),
      itemCount: _kNavItems.length,
      itemBuilder: (context, index) {
        final item = _kNavItems[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: AppTheme.cardDecor,
          child: ListTile(
            contentPadding: AppTheme.tilePadding,
            minLeadingWidth: 24,
            leading: CircleAvatar(
              backgroundColor: AppTheme.terra50,
              child: Icon(item.icon, color: AppTheme.terra600, size: 20),
            ),
            title: Text(item.label),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            onTap: () => nav.selectSection(item.id),
          ),
        );
      },
    );
  }

  Widget _sectionWidget(String section) {
    switch (section) {
      case 'flocks': return const FlocksListScreen();
      case 'feed_schedules': return const FeedScheduleScreen();
      case 'vaccine_schedules': return const VaccineScheduleScreen();
      case 'invoices': return const ChickenInvoiceStandaloneScreen();
      case 'demand': return const DemandAnalysisScreen();
      default: return const FlocksListScreen();
    }
  }

  String _labelForSection(String section) {
    for (final item in _kNavItems) {
      if (item.id == section) return item.label;
    }
    return 'Poultry';
  }
}
