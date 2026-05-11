import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/models/lookup_option.dart';
import 'package:farm_mgt_auth/modules/settings/utils/code_generators.dart';
import 'package:flutter/material.dart';

import '../config/poultry_definitions.dart';
import '../controllers/flock_controller.dart';

class FlockFormDialog extends StatefulWidget {
  const FlockFormDialog({
    super.key,
    required this.controller,
    required this.vendorOptions,
    required this.feedScheduleOptions,
    required this.vaccineScheduleOptions,
    this.item,
    required this.onSaved,
  });

  final FlockController controller;
  final List<LookupOption> vendorOptions;
  final List<LookupOption> feedScheduleOptions;
  final List<LookupOption> vaccineScheduleOptions;
  final Map<String, dynamic>? item; // null = new flock
  final VoidCallback onSaved;

  @override
  State<FlockFormDialog> createState() => _FlockFormDialogState();
}

class _FlockFormDialogState extends State<FlockFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _v;
  bool _saving = false;
  bool _showClosure = false;

  @override
  void initState() {
    super.initState();
    _v = widget.item != null
        ? Map<String, dynamic>.from(widget.item!)
        : {'flockNo': generatedFlockNo(), 'status': 'active', 'birdType': 'broiler'};
    _showClosure = _v['status'] != null && _v['status'] != 'active';
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
            Text(
              widget.item == null ? 'New Flock' : 'Edit Flock',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),

            _section('Basic Info'),
            _field('Flock No *', _text('flockNo', required: true)),
            _field('Flock Name *', _text('flockName', required: true)),
            _field('Bird Type *', _dropdown('birdType', kBirdTypes, required: true)),
            _field('Breed', _text('breed')),
            _field('Shed No *', _text('shedNo', required: true)),
            _field('Vendor', _dropdown('vendorId', widget.vendorOptions)),

            _section('Placement'),
            _field('Placement Date *', _datePicker('placementDate', required: true)),
            _field('Initial Birds Count *', _number('initialBirdsCount', required: true, integer: true)),
            _field('Placement Weight (kg/bird)', _number('placementWeightKg')),

            _section('Targets'),
            _field('Target Weight (kg)', _number('targetWeightKg')),
            _field('Target Age (days)', _number('targetAgeDays', integer: true)),

            _section('Schedules'),
            _field('Feed Schedules', _multiSelect('feedScheduleIds', widget.feedScheduleOptions)),
            _field('Vaccine Schedules', _multiSelect('vaccineScheduleIds', widget.vaccineScheduleOptions)),

            _section('Status'),
            _field('Status *', _dropdown('status', kFlockStatuses, required: true)),
            if (_showClosure) ...[
              _field('Closure Date', _datePicker('closureDate')),
              _field('Closure Reason', _text('closureReason')),
            ],
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

  Widget _section(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 4),
    child: Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(
      color: AppTheme.terra600, fontWeight: FontWeight.w700, fontSize: 14)),
  );

  Widget _field(String label, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, height: 1)),
      const SizedBox(height: 6),
      child,
    ]),
  );

  Widget _text(String key, {bool required = false}) => TextFormField(
    initialValue: '${_v[key] ?? ''}',
    decoration: const InputDecoration(),
    validator: required ? (v) => (v ?? '').trim().isEmpty ? 'Required' : null : null,
    onChanged: (v) => _v[key] = v,
  );

  Widget _textArea(String key) => TextFormField(
    initialValue: '${_v[key] ?? ''}',
    minLines: 2, maxLines: 4,
    decoration: const InputDecoration(),
    onChanged: (v) => _v[key] = v,
  );

  Widget _number(String key, {bool required = false, bool integer = false}) => TextFormField(
    initialValue: _v[key] != null ? '${_v[key]}' : '',
    keyboardType: TextInputType.numberWithOptions(decimal: !integer),
    decoration: const InputDecoration(),
    validator: required ? (v) => (v ?? '').trim().isEmpty ? 'Required' : null : null,
    onChanged: (v) {
      _v[key] = integer
          ? (int.tryParse(v.trim()) ?? 0)
          : (double.tryParse(v.trim()) ?? 0);
    },
  );

  Widget _dropdown(String key, List<LookupOption> opts, {bool required = false}) {
    final current = '${_v[key] ?? ''}';
    return DropdownButtonFormField<String>(
      value: current.isEmpty ? null : current,
      items: opts.map((o) => DropdownMenuItem(value: o.value, child: Text(o.label))).toList(),
      decoration: const InputDecoration(),
      validator: required ? (v) => (v ?? '').isEmpty ? 'Required' : null : null,
      onChanged: (v) => setState(() {
        _v[key] = v ?? '';
        if (key == 'status') {
          _showClosure = v != 'active';
        }
      }),
    );
  }

  Widget _datePicker(String key, {bool required = false}) {
    final raw = '${_v[key] ?? ''}';
    String display = '';
    if (raw.isNotEmpty) {
      try {
        final d = DateTime.parse(raw);
        display = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      } catch (_) {
        display = raw.split('T').first;
      }
    }
    return TextFormField(
      key: ValueKey('$key:$raw'),
      readOnly: true,
      initialValue: display,
      decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today_outlined)),
      validator: required ? (v) => (v ?? '').trim().isEmpty ? 'Required' : null : null,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() => _v[key] = picked.toIso8601String());
        }
      },
    );
  }

  Widget _multiSelect(String key, List<LookupOption> opts) {
    final selected = (_v[key] is List)
        ? List<String>.from(_v[key] as List)
        : <String>[];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.inputRadius),
        border: Border.all(color: AppTheme.inputBorderColor),
      ),
      child: opts.isEmpty
          ? Text('No options available', style: TextStyle(color: AppTheme.textTertiary, fontSize: 13))
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: opts.map((o) {
                final isSel = selected.contains(o.value);
                return FilterChip(
                  label: Text(o.label),
                  selected: isSel,
                  selectedColor: AppTheme.sidebarActive,
                  checkmarkColor: AppTheme.terra800,
                  side: const BorderSide(color: AppTheme.softBorder),
                  labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSel ? AppTheme.terra800 : AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  onSelected: (v) => setState(() {
                    if (v) selected.add(o.value); else selected.remove(o.value);
                    _v[key] = selected.toSet().toList();
                  }),
                );
              }).toList(),
            ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final messenger = ScaffoldMessenger.of(context);
      if (widget.item == null) {
        await widget.controller.add(_v);
      } else {
        await widget.controller.updateItem('${widget.item!['id'] ?? ''}', _v);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppTheme.successText,
        content: const Text('Saved successfully'),
        duration: const Duration(milliseconds: 2500),
      ));
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppTheme.dangerText,
        content: Text(e.toString()),
        duration: const Duration(milliseconds: 3000),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
