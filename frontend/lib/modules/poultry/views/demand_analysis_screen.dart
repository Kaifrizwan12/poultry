import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farm_mgt_auth/core/horizontal_scroll_wheel.dart';

import '../controllers/flock_controller.dart';
import '../controllers/poultry_report_controller.dart';
import '../models/demand_analysis_report_model.dart';

class DemandAnalysisScreen extends StatefulWidget {
  const DemandAnalysisScreen({super.key});

  @override
  State<DemandAnalysisScreen> createState() => _DemandAnalysisScreenState();
}

class _DemandAnalysisScreenState extends State<DemandAnalysisScreen> {
  final Set<String> _selectedFlockIds = {};
  int _daysAhead = 7;
  bool _hasLoaded = false;

  static const List<int> _dayOptions = [3, 7, 14, 30];

  @override
  Widget build(BuildContext context) {
    final flockCtrl = context.watch<FlockController>();
    final activeFlocks = flockCtrl.activeFlocks;

    return Consumer<PoultryReportController>(
      builder: (context, ctrl, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FilterPanel(
              activeFlocks: activeFlocks.map((f) => MapEntry(f.id, f.flockName)).toList(),
              selectedFlockIds: _selectedFlockIds,
              daysAhead: _daysAhead,
              isLoading: ctrl.isLoadingDemand,
              onFlockToggled: (id) => setState(() {
                if (_selectedFlockIds.contains(id)) _selectedFlockIds.remove(id);
                else _selectedFlockIds.add(id);
              }),
              onDaysChanged: (v) => setState(() => _daysAhead = v),
              onRun: _selectedFlockIds.isEmpty ? null : () => _loadReport(ctrl),
            ),
            const SizedBox(height: 20),
            if (ctrl.isLoadingDemand)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (ctrl.errorDemand != null)
              Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(ctrl.errorDemand!),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: () => _loadReport(ctrl), child: const Text('Retry')),
              ])))
            else if (!_hasLoaded)
              Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.bar_chart_outlined, size: 64, color: AppTheme.textTertiary),
                const SizedBox(height: 12),
                Text('Select flocks and click Run Analysis',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ])))
            else if (ctrl.demandAnalysis == null)
              const Expanded(child: Center(child: Text('No data')))
            else
              Expanded(child: _ReportBody(report: ctrl.demandAnalysis!)),
          ],
        );
      },
    );
  }

  Future<void> _loadReport(PoultryReportController ctrl) async {
    setState(() => _hasLoaded = true);
    await ctrl.loadDemandAnalysis(_selectedFlockIds.toList(), _daysAhead);
  }
}

// ─── Filter Panel ─────────────────────────────────────────────────────────────

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.activeFlocks,
    required this.selectedFlockIds,
    required this.daysAhead,
    required this.isLoading,
    required this.onFlockToggled,
    required this.onDaysChanged,
    required this.onRun,
  });

  final List<MapEntry<String, String>> activeFlocks;
  final Set<String> selectedFlockIds;
  final int daysAhead;
  final bool isLoading;
  final void Function(String id) onFlockToggled;
  final void Function(int days) onDaysChanged;
  final VoidCallback? onRun;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analysis Parameters', style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.terra600)),
          const SizedBox(height: 16),
          Text('Active Flocks', style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          activeFlocks.isEmpty
              ? Text('No active flocks', style: TextStyle(color: AppTheme.textTertiary, fontSize: 13))
              : Wrap(
                  spacing: 8, runSpacing: 8,
                  children: activeFlocks.map((e) {
                    final isSel = selectedFlockIds.contains(e.key);
                    return FilterChip(
                      label: Text(e.value),
                      selected: isSel,
                      selectedColor: AppTheme.sidebarActive,
                      checkmarkColor: AppTheme.terra800,
                      side: const BorderSide(color: AppTheme.softBorder),
                      labelStyle: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500,
                        color: isSel ? AppTheme.terra800 : AppTheme.textPrimary,
                      ),
                      onSelected: (_) => onFlockToggled(e.key),
                    );
                  }).toList(),
                ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final chips = _DemandAnalysisScreenState._dayOptions.map((d) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('$d days'),
                selected: daysAhead == d,
                selectedColor: AppTheme.sidebarActive,
                side: const BorderSide(color: AppTheme.softBorder),
                labelStyle: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500,
                  color: daysAhead == d ? AppTheme.terra800 : AppTheme.textSecondary,
                ),
                onSelected: (_) => onDaysChanged(d),
              ),
            )).toList();

            final runBtn = ElevatedButton.icon(
              onPressed: isLoading ? null : onRun,
              icon: isLoading
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(isLoading ? 'Running…' : 'Run Analysis'),
            );

            if (constraints.maxWidth < 480) {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Projection Days:', style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Wrap(spacing: 0, children: chips),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: runBtn),
              ]);
            }

            return Row(children: [
              Text('Projection Days:', style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
              const SizedBox(width: 12),
              ...chips,
              const Spacer(),
              runBtn,
            ]);
          }),
        ],
      ),
    );
  }
}

// ─── Report Body ──────────────────────────────────────────────────────────────

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report});
  final DemandAnalysisReportModel report;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (report.aggregatedFeed.isNotEmpty) ...[
            _sectionTitle(context, 'Feed Requirements (${report.projectionDays}-day total)', Icons.restaurant_outlined),
            const SizedBox(height: 10),
            _AggFeedTable(items: report.aggregatedFeed),
            const SizedBox(height: 20),
          ],
          if (report.aggregatedVaccines.isNotEmpty) ...[
            _sectionTitle(context, 'Vaccine Requirements (${report.projectionDays}-day total)', Icons.vaccines_outlined),
            const SizedBox(height: 10),
            _AggVaccineTable(items: report.aggregatedVaccines),
            const SizedBox(height: 20),
          ],
          if (report.flocks.isNotEmpty) ...[
            _sectionTitle(context, 'Per-Flock Breakdown', Icons.expand_outlined),
            const SizedBox(height: 10),
            ...report.flocks.map((f) => _FlockExpansion(flock: f)),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, IconData icon) => Row(
    children: [
      Icon(icon, size: 18, color: AppTheme.terra600),
      const SizedBox(width: 8),
      Text(title, style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
    ],
  );
}

class _AggFeedTable extends StatelessWidget {
  const _AggFeedTable({required this.items});
  final List<AggregatedFeedProduct> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.softBorder),
      ),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppTheme.pageBg),
        columnSpacing: 24,
        headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
        columns: const [
          DataColumn(label: Text('Product')),
          DataColumn(label: Text('Total (kg)'), numeric: true),
        ],
        rows: items.map((p) => DataRow(cells: [
          DataCell(Text(p.productName, style: const TextStyle(fontWeight: FontWeight.w600))),
          DataCell(Text(p.totalKg.toStringAsFixed(2))),
        ])).toList(),
      ),
    );
  }
}

class _AggVaccineTable extends StatelessWidget {
  const _AggVaccineTable({required this.items});
  final List<AggregatedVaccineProduct> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.softBorder),
      ),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppTheme.pageBg),
        columnSpacing: 24,
        headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
        columns: const [
          DataColumn(label: Text('Product')),
          DataColumn(label: Text('Total Dose (ml)'), numeric: true),
        ],
        rows: items.map((p) => DataRow(cells: [
          DataCell(Text(p.productName, style: const TextStyle(fontWeight: FontWeight.w600))),
          DataCell(Text(p.totalDose.toStringAsFixed(2))),
        ])).toList(),
      ),
    );
  }
}

class _FlockExpansion extends StatelessWidget {
  const _FlockExpansion({required this.flock});
  final FlockDemandResult flock;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.softBorder),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(flock.flockName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${flock.projectedFeed.length} feed entries  •  ${flock.projectedVaccines.length} vaccine entries',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        children: [
          if (flock.projectedFeed.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(alignment: Alignment.centerLeft, child: Text('Feed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700, color: AppTheme.terra600))),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: HorizontalScrollWheel(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppTheme.pageBg),
                  columnSpacing: 20,
                  dataRowMinHeight: 36, dataRowMaxHeight: 44,
                  headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                  columns: const [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Age'), numeric: true),
                    DataColumn(label: Text('Product')),
                    DataColumn(label: Text('Req (kg)'), numeric: true),
                  ],
                  rows: flock.projectedFeed.map((r) => DataRow(cells: [
                    DataCell(Text(_formatDate(r.date))),
                    DataCell(Text('${r.ageDays}')),
                    DataCell(Text(r.productName)),
                    DataCell(Text(r.requiredKg.toStringAsFixed(2))),
                  ])).toList(),
                ),
              ),
            ),
          ],
          if (flock.projectedVaccines.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(alignment: Alignment.centerLeft, child: Text('Vaccines',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700, color: AppTheme.terra600))),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: HorizontalScrollWheel(
                child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppTheme.pageBg),
                columnSpacing: 20,
                dataRowMinHeight: 36, dataRowMaxHeight: 44,
                headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Schedule')),
                  DataColumn(label: Text('Product')),
                  DataColumn(label: Text('Birds'), numeric: true),
                  DataColumn(label: Text('Dose (ml)'), numeric: true),
                ],
                rows: flock.projectedVaccines.map((r) => DataRow(cells: [
                  DataCell(Text(_formatDate(r.date))),
                  DataCell(Text(r.scheduleName)),
                  DataCell(Text(r.productName)),
                  DataCell(Text('${r.birdsCount}')),
                  DataCell(Text(r.totalDose.toStringAsFixed(2))),
                ])).toList(),
              ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day.toString().padLeft(2,'0')} ${m[d.month-1]} ${d.year}';
    } catch (_) { return iso.split('T').first; }
  }
}
