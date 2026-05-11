import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/models/lookup_option.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/products_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/poultry_definitions.dart';
import '../controllers/flock_vaccine_controller.dart';
import '../controllers/vaccine_schedule_controller.dart';
import '../models/flock_model.dart';
import '../models/flock_vaccine_model.dart';
import '../widgets/auto_calc_field.dart';

class FlockVaccineScreen extends StatelessWidget {
  const FlockVaccineScreen({super.key, required this.flockId, required this.flock});
  final String flockId;
  final FlockModel flock;

  @override
  Widget build(BuildContext context) {
    return Consumer<FlockVaccineController>(
      builder: (context, ctrl, _) {
        if (ctrl.isLoading) return const Center(child: CircularProgressIndicator());
        if (ctrl.error != null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(ctrl.error!),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () => ctrl.fetchByFlock(flockId), child: const Text('Retry')),
        ]));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _openEditor(context, ctrl),
                icon: const Icon(Icons.add),
                label: const Text('Add Vaccine Record'),
              ),
            ]),
            const SizedBox(height: 16),
            Expanded(child: ctrl.items.isEmpty
              ? const Center(child: Text('No vaccine records yet', style: TextStyle(color: AppTheme.textSecondary)))
              : _VaccineTable(items: ctrl.items, flock: flock, ctrl: ctrl)),
          ],
        );
      },
    );
  }

  void _openEditor(BuildContext context, FlockVaccineController ctrl, [FlockVaccineModel? item]) {
    final productsCtrl = context.read<ProductsController>();
    final productOptions = productsCtrl.items
        .map((p) => LookupOption(value: p.id, label: p.text('name'))).toList();
    final schedOpts = context.read<VaccineScheduleController>().items
        .where((s) => flock.vaccineScheduleIds.contains(s.id))
        .map((s) => LookupOption(value: s.id, label: s.name)).toList();

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width < 600
              ? MediaQuery.of(context).size.width - 24 : 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _VaccineForm(
              ctrl: ctrl,
              flock: flock,
              productOptions: productOptions,
              scheduleOptions: schedOpts,
              item: item,
            ),
          ),
        ),
      ),
    );
  }
}

class _VaccineTable extends StatelessWidget {
  const _VaccineTable({required this.items, required this.flock, required this.ctrl});
  final List<FlockVaccineModel> items;
  final FlockModel flock;
  final FlockVaccineController ctrl;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: items.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.softBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_formatDate(item.date), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text('Age: ${item.ageDays} days  •  Birds: ${item.birdsVaccinated}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
                ])),
                IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () {
                  final screen = context.findAncestorWidgetOfExactType<FlockVaccineScreen>();
                  screen?._openEditor(context, ctrl, item);
                }),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerText),
                  onPressed: () => _delete(context, item),
                ),
              ]),
              const SizedBox(height: 10),
              Wrap(spacing: 12, runSpacing: 8, children: [
                if (item.administrationRoute.isNotEmpty)
                  _chip('Route', labelFor(kAdministrationRoutes, item.administrationRoute)),
                if (item.dosePerBird > 0)
                  _chip('Dose/Bird', '${item.dosePerBird} ml'),
                if (item.totalDoseUsed > 0)
                  _chip('Total Dose', '${item.totalDoseUsed.toStringAsFixed(2)} ml'),
                if (item.batchNo.isNotEmpty)
                  _chip('Batch', item.batchNo),
                if (item.administeredBy.isNotEmpty)
                  _chip('By', item.administeredBy),
                if (item.nextDueDate.isNotEmpty)
                  _chip('Next Due', _formatDate(item.nextDueDate), AppTheme.terra600),
              ]),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _chip(String label, String value, [Color? valueColor]) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppTheme.pageBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.softBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor ?? AppTheme.textPrimary)),
    ]),
  );

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day.toString().padLeft(2,'0')} ${m[d.month-1]} ${d.year}';
    } catch (_) { return iso.split('T').first; }
  }

  Future<void> _delete(BuildContext context, FlockVaccineModel item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vaccine Record'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.dangerText), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      try { await ctrl.deleteItem(item.id); } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppTheme.dangerText, content: Text(e.toString())));
      }
    }
  }
}

// ─── Form ─────────────────────────────────────────────────────────────────────

class _VaccineForm extends StatefulWidget {
  const _VaccineForm({
    required this.ctrl,
    required this.flock,
    required this.productOptions,
    required this.scheduleOptions,
    this.item,
  });
  final FlockVaccineController ctrl;
  final FlockModel flock;
  final List<LookupOption> productOptions;
  final List<LookupOption> scheduleOptions;
  final FlockVaccineModel? item;

  @override
  State<_VaccineForm> createState() => _VaccineFormState();
}

class _VaccineFormState extends State<_VaccineForm> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _v;
  bool _saving = false;
  double _totalDoseUsed = 0;
  String _nextDueDate = '';

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _v = widget.item!.toJson();
      _totalDoseUsed = widget.item!.totalDoseUsed;
      _nextDueDate = widget.item!.nextDueDate;
    } else {
      _v = {
        'flockId': widget.flock.id,
        'birdsVaccinated': widget.flock.currentBirdsCount,
        'ageDays': widget.flock.ageDays,
        'date': DateTime.now().toIso8601String(),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.item == null ? 'Add Vaccine Record' : 'Edit Vaccine Record',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            _field('Date *', _datePicker()),
            _field('Birds Vaccinated *', _number('birdsVaccinated', required: true, integer: true)),
            _field('Age Days', _number('ageDays', integer: true)),
            _field('Vaccine Schedule', _dropdown('vaccineScheduleId', widget.scheduleOptions)),
            _field('Vaccine Product *', _dropdown('productId', widget.productOptions, required: true)),
            _field('Administration Route', _dropdown('administrationRoute', kAdministrationRoutes)),
            _field('Dose Per Bird (ml) *', _number('dosePerBird', required: true, decimal: true)),
            if (_totalDoseUsed > 0)
              AutoCalcField(label: 'Total Dose Used (ml)', value: _totalDoseUsed.toStringAsFixed(2)),
            if (_nextDueDate.isNotEmpty)
              AutoCalcField(label: 'Next Due Date', value: _formatDatePreview(_nextDueDate)),
            _field('Batch / Lot No', _text('batchNo')),
            _field('Administered By', _text('administeredBy')),
            _field('Notes', _textArea('notes')),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save'),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, height: 1)),
      const SizedBox(height: 6), child,
    ]),
  );

  Widget _text(String key) => TextFormField(
    initialValue: '${_v[key] ?? ''}', decoration: const InputDecoration(),
    onChanged: (v) => _v[key] = v,
  );

  Widget _textArea(String key) => TextFormField(
    initialValue: '${_v[key] ?? ''}', minLines: 2, maxLines: 4,
    decoration: const InputDecoration(), onChanged: (v) => _v[key] = v,
  );

  Widget _number(String key, {bool required = false, bool integer = false, bool decimal = false}) =>
      TextFormField(
    initialValue: _v[key] != null ? '${_v[key]}' : '',
    keyboardType: TextInputType.numberWithOptions(decimal: decimal),
    decoration: const InputDecoration(),
    validator: required ? (v) => (v ?? '').trim().isEmpty ? 'Required' : null : null,
    onChanged: (v) {
      setState(() {
        _v[key] = integer
            ? (int.tryParse(v.trim()) ?? 0)
            : (double.tryParse(v.trim()) ?? 0);
        _recompute();
      });
    },
  );

  Widget _dropdown(String key, List<LookupOption> opts, {bool required = false}) {
    final current = '${_v[key] ?? ''}';
    return DropdownButtonFormField<String>(
      value: current.isEmpty ? null : current,
      items: opts.map((o) => DropdownMenuItem(value: o.value, child: Text(o.label))).toList(),
      decoration: const InputDecoration(),
      validator: required ? (v) => (v ?? '').isEmpty ? 'Required' : null : null,
      onChanged: (v) => setState(() { _v[key] = v ?? ''; _recompute(); }),
    );
  }

  Widget _datePicker() {
    final raw = '${_v['date'] ?? ''}';
    String display = '';
    if (raw.isNotEmpty) {
      try {
        final d = DateTime.parse(raw);
        display = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
        if (_v['ageDays'] == null || _v['ageDays'] == 0) {
          final ageDays = d.difference(DateTime.parse(widget.flock.placementDate)).inDays;
          _v['ageDays'] = ageDays.clamp(0, 9999);
        }
      } catch (_) { display = raw.split('T').first; }
    }
    return TextFormField(
      key: ValueKey('date:$raw'), readOnly: true, initialValue: display,
      decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today_outlined)),
      validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
      onTap: () async {
        final picked = await showDatePicker(context: context,
            initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
        if (picked != null) {
          setState(() {
            _v['date'] = picked.toIso8601String();
            final ageDays = picked.difference(DateTime.parse(widget.flock.placementDate)).inDays;
            _v['ageDays'] = ageDays.clamp(0, 9999);
          });
        }
      },
    );
  }

  void _recompute() {
    final dosePerBird = (_v['dosePerBird'] is num) ? (_v['dosePerBird'] as num).toDouble() : 0.0;
    final birdsVaccinated = (_v['birdsVaccinated'] is num) ? (_v['birdsVaccinated'] as num).toInt() : 0;

    _totalDoseUsed = dosePerBird * birdsVaccinated;

    final schedId = '${_v['vaccineScheduleId'] ?? ''}';
    if (schedId.isNotEmpty) {
      try {
        final schedCtrl = context.read<VaccineScheduleController>();
        final sched = schedCtrl.items.firstWhere((s) => s.id == schedId);
        if (sched.boosterRequired && sched.boosterIntervalDays > 0) {
          final dateStr = '${_v['date'] ?? ''}';
          if (dateStr.isNotEmpty) {
            final vaccDate = DateTime.tryParse(dateStr);
            if (vaccDate != null) {
              final due = vaccDate.add(Duration(days: sched.boosterIntervalDays));
              _nextDueDate = due.toIso8601String();
            }
          }
        } else {
          _nextDueDate = '';
        }
      } catch (_) {}
    }
  }

  String _formatDatePreview(String iso) {
    try {
      final d = DateTime.parse(iso);
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day.toString().padLeft(2,'0')} ${m[d.month-1]} ${d.year}';
    } catch (_) { return iso.split('T').first; }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final messenger = ScaffoldMessenger.of(context);
      if (widget.item == null) {
        await widget.ctrl.add(_v);
      } else {
        await widget.ctrl.updateItem(widget.item!.id, _v);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(backgroundColor: AppTheme.successText,
          content: const Text('Saved'), duration: const Duration(milliseconds: 2500)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppTheme.dangerText, content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
