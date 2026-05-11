import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/models/lookup_option.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/products_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/poultry_definitions.dart';
import '../controllers/flock_feed_controller.dart';
import '../controllers/feed_schedule_controller.dart';
import '../models/flock_model.dart';
import '../models/flock_feed_model.dart';
import '../widgets/auto_calc_field.dart';

class FlockFeedScreen extends StatelessWidget {
  const FlockFeedScreen({super.key, required this.flockId, required this.flock});
  final String flockId;
  final FlockModel flock;

  @override
  Widget build(BuildContext context) {
    return Consumer<FlockFeedController>(
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
                label: const Text('Add Feed Record'),
              ),
            ]),
            const SizedBox(height: 16),
            Expanded(child: ctrl.items.isEmpty
              ? const Center(child: Text('No feed records yet', style: TextStyle(color: AppTheme.textSecondary)))
              : _FeedTable(items: ctrl.items, flock: flock, ctrl: ctrl)),
          ],
        );
      },
    );
  }

  void _openEditor(BuildContext context, FlockFeedController ctrl, [FlockFeedModel? item]) {
    final productsCtrl = context.read<ProductsController>();
    final productOptions = productsCtrl.items
        .map((p) => LookupOption(value: p.id, label: p.text('name'))).toList();
    final schedOpts = context.read<FeedScheduleController>().items
        .where((s) => flock.feedScheduleIds.contains(s.id))
        .map((s) => LookupOption(value: s.id, label: s.name)).toList();

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width < 600
              ? MediaQuery.of(context).size.width - 24 : 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _FeedForm(
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

class _FeedTable extends StatelessWidget {
  const _FeedTable({required this.items, required this.flock, required this.ctrl});
  final List<FlockFeedModel> items;
  final FlockModel flock;
  final FlockFeedController ctrl;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: items.map((item) {
          final variance = item.feedVarianceKg;
          Color varColor = AppTheme.textSecondary;
          if (item.standardFeedKg > 0) {
            final pct = variance / item.standardFeedKg;
            if (pct > 0.05) varColor = AppTheme.dangerText;
            else if (pct < -0.05) varColor = AppTheme.successText;
          }

          return Container(
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
                    Text('Age: ${item.ageDays} days  •  Birds: ${item.birdsCount}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
                  ])),
                  IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () {
                    // Edit from the parent - bubble up through context
                    final screen = context.findAncestorWidgetOfExactType<FlockFeedScreen>();
                    screen?._openEditor(context, ctrl, item);
                  }),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerText),
                    onPressed: () => _delete(context, item),
                  ),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 12, runSpacing: 8, children: [
                  _chip('Feed Consumed', '${item.feedConsumedKg} kg'),
                  if (item.standardFeedKg > 0)
                    _chip('Standard', '${item.standardFeedKg.toStringAsFixed(2)} kg'),
                  _chip('Variance', '${variance >= 0 ? '+' : ''}${variance.toStringAsFixed(2)} kg', varColor),
                  if (item.mortalityCount > 0)
                    _chip('Mortality', '${item.mortalityCount}', AppTheme.dangerText),
                  if (item.averageWeightKg > 0)
                    _chip('Avg Weight', '${item.averageWeightKg} kg'),
                ]),
              ],
            ),
          );
        }).toList(),
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

  Future<void> _delete(BuildContext context, FlockFeedModel item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Feed Record'),
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

class _FeedForm extends StatefulWidget {
  const _FeedForm({
    required this.ctrl,
    required this.flock,
    required this.productOptions,
    required this.scheduleOptions,
    this.item,
  });
  final FlockFeedController ctrl;
  final FlockModel flock;
  final List<LookupOption> productOptions;
  final List<LookupOption> scheduleOptions;
  final FlockFeedModel? item;

  @override
  State<_FeedForm> createState() => _FeedFormState();
}

class _FeedFormState extends State<_FeedForm> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _v;
  bool _saving = false;
  double _standardFeedKg = 0;
  double _feedVarianceKg = 0;
  double _totalDoseUsed = 0;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _v = widget.item!.toJson();
      _standardFeedKg = widget.item!.standardFeedKg;
      _feedVarianceKg = widget.item!.feedVarianceKg;
    } else {
      final ageDays = widget.flock.ageDays;
      _v = {
        'flockId': widget.flock.id,
        'birdsCount': widget.flock.currentBirdsCount,
        'mortalityCount': 0,
        'ageDays': ageDays,
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
            Text(widget.item == null ? 'Add Feed Record' : 'Edit Feed Record',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            _field('Date *', _datePicker()),
            _field('Birds Count *', _number('birdsCount', required: true, integer: true)),
            _field('Age Days', _number('ageDays', integer: true)),
            _field('Mortality Count', _number('mortalityCount', integer: true)),
            _field('Feed Schedule', _dropdown('feedScheduleId', widget.scheduleOptions)),
            _field('Feed Product *', _dropdown('productId', widget.productOptions, required: true)),
            _field('Feed Consumed (kg) *', _number('feedConsumedKg', required: true, decimal: true)),
            if (_standardFeedKg > 0) ...[
              AutoCalcField(label: 'Standard Feed (kg)', value: _standardFeedKg.toStringAsFixed(2)),
              AutoCalcField(label: 'Feed Variance (kg)',
                  value: '${_feedVarianceKg >= 0 ? '+' : ''}${_feedVarianceKg.toStringAsFixed(2)}'),
            ],
            _field('Average Weight (kg)', _number('averageWeightKg', decimal: true)),
            _field('Batch No', _text('batchNo')),
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
        // Auto-calc ageDays
        final ageDays = d.difference(DateTime.parse(widget.flock.placementDate)).inDays;
        if (_v['ageDays'] == null || _v['ageDays'] == 0) _v['ageDays'] = ageDays.clamp(0, 9999);
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
    final schedId = '${_v['feedScheduleId'] ?? ''}';
    final birdsCount = (_v['birdsCount'] is num) ? (_v['birdsCount'] as num).toDouble() : 0.0;
    final feedConsumed = (_v['feedConsumedKg'] is num) ? (_v['feedConsumedKg'] as num).toDouble() : 0.0;

    if (schedId.isNotEmpty) {
      // Local preview from feedScheduleController
      try {
        final schedCtrl = context.read<FeedScheduleController>();
        final sched = schedCtrl.items.firstWhere((s) => s.id == schedId);
        _standardFeedKg = sched.dailyFeedPerBirdGrams * birdsCount / 1000;
        _feedVarianceKg = feedConsumed - _standardFeedKg;
      } catch (_) {}
    }
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
