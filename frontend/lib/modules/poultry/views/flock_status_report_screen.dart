import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/poultry_report_controller.dart';
import '../models/flock_status_report_model.dart';

class FlockStatusReportScreen extends StatefulWidget {
  const FlockStatusReportScreen({super.key, required this.flockId});
  final String flockId;

  @override
  State<FlockStatusReportScreen> createState() => _FlockStatusReportScreenState();
}

class _FlockStatusReportScreenState extends State<FlockStatusReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PoultryReportController>().loadFlockStatus(widget.flockId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PoultryReportController>(
      builder: (context, ctrl, _) {
        if (ctrl.isLoadingStatus) return const Center(child: CircularProgressIndicator());
        if (ctrl.errorStatus != null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(ctrl.errorStatus!),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => ctrl.loadFlockStatus(widget.flockId, force: true),
            child: const Text('Retry'),
          ),
        ]));

        final report = ctrl.flockStatus;
        if (report == null) return const Center(child: Text('No data'));

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => ctrl.loadFlockStatus(widget.flockId, force: true),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                ),
              ]),
              const SizedBox(height: 16),
              _SummaryGrid(report: report),
              const SizedBox(height: 20),
              if (report.pendingVaccines.isNotEmpty) ...[
                _sectionTitle(context, 'Pending Vaccines', Icons.vaccines_outlined),
                const SizedBox(height: 10),
                _PendingVaccineTable(items: report.pendingVaccines),
                const SizedBox(height: 20),
              ],
              if (report.feedHistory.isNotEmpty) ...[
                _sectionTitle(context, 'Feed History', Icons.restaurant_outlined),
                const SizedBox(height: 10),
                _FeedHistoryTable(history: report.feedHistory),
                const SizedBox(height: 20),
              ],
              if (report.completedVaccines.isNotEmpty) ...[
                _sectionTitle(context, 'Completed Vaccinations', Icons.check_circle_outline),
                const SizedBox(height: 10),
                _CompletedVaccineTable(vaccines: report.completedVaccines),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(BuildContext context, String title, IconData icon) => Row(
    children: [
      Icon(icon, size: 18, color: AppTheme.terra600),
      const SizedBox(width: 8),
      Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
    ],
  );
}

// ─── Summary Grid ─────────────────────────────────────────────────────────────

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.report});
  final FlockStatusReportModel report;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatCard(label: 'Age', value: '${report.ageDays} days'),
        _StatCard(label: 'Current Birds', value: '${report.currentBirdsCount}'),
        _StatCard(label: 'Total Mortality', value: '${report.totalMortality}'),
        _StatCard(label: 'Mortality Rate', value: report.mortalityRate,
            valueColor: double.tryParse(report.mortalityRate.replaceAll('%', '')) != null &&
                double.parse(report.mortalityRate.replaceAll('%', '')) > 5
                ? AppTheme.dangerText : null),
        _StatCard(label: 'Total Feed', value: '${report.totalFeedConsumedKg.toStringAsFixed(1)} kg'),
        _StatCard(label: 'Avg Daily Feed', value: '${report.averageDailyFeedKg.toStringAsFixed(2)} kg'),
        if (report.feedConversionRatio > 0)
          _StatCard(label: 'FCR', value: report.feedConversionRatio.toStringAsFixed(3),
              valueColor: report.feedConversionRatio > 2.0 ? AppTheme.dangerText : AppTheme.successText),
        if (report.averageCurrentWeightKg > 0)
          _StatCard(label: 'Avg Weight', value: '${report.averageCurrentWeightKg.toStringAsFixed(3)} kg'),
        if (report.projectedHarvestDate != null)
          _StatCard(label: 'Projected Harvest', value: _formatDate(report.projectedHarvestDate!),
              valueColor: AppTheme.terra600),
      ],
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.softBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
            color: valueColor ?? AppTheme.textPrimary)),
      ]),
    );
  }
}

// ─── Pending Vaccines Table ───────────────────────────────────────────────────

class _PendingVaccineTable extends StatelessWidget {
  const _PendingVaccineTable({required this.items});
  final List<PendingVaccineItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.softBorder),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          final isLast = i == items.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: item.isOverdue ? const Color(0xFFFEF2F2) : null,
              border: !isLast ? const Border(bottom: BorderSide(color: AppTheme.softBorder)) : null,
              borderRadius: BorderRadius.only(
                topLeft: i == 0 ? const Radius.circular(12) : Radius.zero,
                topRight: i == 0 ? const Radius.circular(12) : Radius.zero,
                bottomLeft: isLast ? const Radius.circular(12) : Radius.zero,
                bottomRight: isLast ? const Radius.circular(12) : Radius.zero,
              ),
            ),
            child: Row(children: [
              Icon(
                item.isOverdue ? Icons.warning_amber_rounded : Icons.schedule,
                size: 18,
                color: item.isOverdue ? AppTheme.dangerText : AppTheme.terra600,
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.name, style: TextStyle(fontWeight: FontWeight.w600,
                    color: item.isOverdue ? AppTheme.dangerText : AppTheme.textPrimary)),
                Text('Due: ${_formatDate(item.dueDate)}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ])),
              if (item.isOverdue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
                  child: Text('${item.overdueDays}d overdue',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.dangerText)),
                ),
            ]),
          );
        }).toList(),
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

// ─── Feed History Table ───────────────────────────────────────────────────────

class _FeedHistoryTable extends StatelessWidget {
  const _FeedHistoryTable({required this.history});
  final List<Map<String, dynamic>> history;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.softBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.pageBg),
          dataRowMinHeight: 40,
          dataRowMaxHeight: 52,
          columnSpacing: 24,
          headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Age'), numeric: true),
            DataColumn(label: Text('Birds'), numeric: true),
            DataColumn(label: Text('Consumed (kg)'), numeric: true),
            DataColumn(label: Text('Standard (kg)'), numeric: true),
            DataColumn(label: Text('Variance (kg)'), numeric: true),
          ],
          rows: history.map((row) {
            final variance = (row['feedVarianceKg'] as num?)?.toDouble() ?? 0;
            final standard = (row['standardFeedKg'] as num?)?.toDouble() ?? 0;
            Color varColor = AppTheme.textSecondary;
            if (standard > 0) {
              final pct = variance / standard;
              if (pct > 0.05) varColor = AppTheme.dangerText;
              else if (pct < -0.05) varColor = AppTheme.successText;
            }
            return DataRow(cells: [
              DataCell(Text(_formatDate('${row['date'] ?? ''}'))),
              DataCell(Text('${row['ageDays'] ?? 0}')),
              DataCell(Text('${row['birdsCount'] ?? 0}')),
              DataCell(Text('${(row['feedConsumedKg'] as num?)?.toStringAsFixed(2) ?? '0.00'}')),
              DataCell(Text(standard > 0 ? standard.toStringAsFixed(2) : '—')),
              DataCell(Text(
                standard > 0 ? '${variance >= 0 ? '+' : ''}${variance.toStringAsFixed(2)}' : '—',
                style: TextStyle(color: varColor, fontWeight: FontWeight.w600),
              )),
            ]);
          }).toList(),
        ),
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

// ─── Completed Vaccines Table ─────────────────────────────────────────────────

class _CompletedVaccineTable extends StatelessWidget {
  const _CompletedVaccineTable({required this.vaccines});
  final List<Map<String, dynamic>> vaccines;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.softBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.pageBg),
          dataRowMinHeight: 40,
          dataRowMaxHeight: 52,
          columnSpacing: 24,
          headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Age'), numeric: true),
            DataColumn(label: Text('Birds'), numeric: true),
            DataColumn(label: Text('Route')),
            DataColumn(label: Text('Dose/Bird'), numeric: true),
            DataColumn(label: Text('Total Dose'), numeric: true),
            DataColumn(label: Text('Batch')),
          ],
          rows: vaccines.map((row) => DataRow(cells: [
            DataCell(Text(_formatDate('${row['date'] ?? ''}'))),
            DataCell(Text('${row['ageDays'] ?? 0}')),
            DataCell(Text('${row['birdsVaccinated'] ?? 0}')),
            DataCell(Text('${row['administrationRoute'] ?? '—'}')),
            DataCell(Text('${(row['dosePerBird'] as num?)?.toStringAsFixed(2) ?? '0.00'}')),
            DataCell(Text('${(row['totalDoseUsed'] as num?)?.toStringAsFixed(2) ?? '0.00'}')),
            DataCell(Text('${row['batchNo'] ?? '—'}')),
          ])).toList(),
        ),
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
