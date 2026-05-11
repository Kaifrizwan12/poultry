import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/models/lookup_option.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/products_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/poultry_definitions.dart';
import '../controllers/vaccine_schedule_controller.dart';
import '../models/vaccine_schedule_model.dart';
import '_poultry_crud_screen.dart';

class VaccineScheduleScreen extends StatelessWidget {
  const VaccineScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productsCtrl = context.read<ProductsController>();
    final productOptions = productsCtrl.items
        .map((p) => LookupOption(value: p.id, label: p.text('name')))
        .toList();

    return Consumer<VaccineScheduleController>(
      builder: (context, ctrl, _) {
        return PoultryCrudScreen<VaccineScheduleModel>(
          title: 'Vaccine Schedules',
          addLabel: 'Add Vaccine Schedule',
          isLoading: ctrl.isLoading,
          error: ctrl.error,
          items: ctrl.filteredItems,
          searchQuery: ctrl.searchQuery,
          onSearch: ctrl.setSearchQuery,
          onAdd: () => _openEditor(context, ctrl, productOptions),
          onEdit: (item) => _openEditor(context, ctrl, productOptions, item),
          onDelete: (item) => _confirmDelete(context, ctrl, item),
          itemTitle: (item) => item.name,
          itemSubtitleRows: (item) => [
            _Row('Vaccine Type', labelFor(kVaccineTypes, item.vaccineType)),
            _Row('Target Age', '${item.targetAgeDays} days'),
            _Row('Route', labelFor(kAdministrationRoutes, item.administrationRoute)),
            _Row('Dose/Bird', '${item.dosePerBird}'),
            if (item.boosterRequired) _Row('Booster', 'Every ${item.boosterIntervalDays} days'),
          ],
        );
      },
    );
  }

  void _openEditor(
    BuildContext context,
    VaccineScheduleController ctrl,
    List<LookupOption> productOptions, [
    VaccineScheduleModel? item,
  ]) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width < 600
                  ? MediaQuery.of(context).size.width - 24
                  : 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _VaccineScheduleForm(
              controller: ctrl,
              productOptions: productOptions,
              item: item,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    VaccineScheduleController ctrl,
    VaccineScheduleModel item,
  ) async {
    final confirmed = await _showDeleteDialog(context);
    if (confirmed == true) {
      try {
        await ctrl.deleteItem(item.id);
        _snack(context, 'Deleted successfully', AppTheme.successText);
      } catch (e) {
        _snack(context, e.toString(), AppTheme.dangerText);
      }
    }
  }
}

class _Row {
  const _Row(this.label, this.value);
  final String label;
  final String value;
}

class _VaccineScheduleForm extends StatefulWidget {
  const _VaccineScheduleForm({
    required this.controller,
    required this.productOptions,
    this.item,
  });

  final VaccineScheduleController controller;
  final List<LookupOption> productOptions;
  final VaccineScheduleModel? item;

  @override
  State<_VaccineScheduleForm> createState() => _VaccineScheduleFormState();
}

class _VaccineScheduleFormState extends State<_VaccineScheduleForm> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _v;
  bool _saving = false;
  bool _booster = false;

  @override
  void initState() {
    super.initState();
    _v = widget.item != null ? widget.item!.toJson() : {};
    _booster = _v['boosterRequired'] == true;
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
              widget.item == null ? 'Add Vaccine Schedule' : 'Edit Vaccine Schedule',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            _field('Name', _textField('name', required: true)),
            _field('Vaccine Type', _dropdown('vaccineType', kVaccineTypes, required: true)),
            _field('Target Age (Days)', _numberField('targetAgeDays', required: true)),
            _field('Administration Route', _dropdown('administrationRoute', kAdministrationRoutes, required: true)),
            _field('Dose Per Bird', _numberField('dosePerBird', required: true)),
            _field('Vaccine Product *', _dropdown('productId', widget.productOptions, required: true)),
            _field('Booster Required', _toggle('boosterRequired')),
            if (_booster)
              _field('Booster Interval (Days)', _numberField('boosterIntervalDays', required: true)),
            _field('Description', _textArea('description')),
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
      const SizedBox(height: 6),
      child,
    ]),
  );

  Widget _textField(String key, {bool required = false}) => TextFormField(
    initialValue: '${_v[key] ?? ''}',
    decoration: const InputDecoration(),
    validator: required ? (v) => (v ?? '').trim().isEmpty ? 'Required' : null : null,
    onChanged: (v) => _v[key] = v,
  );

  Widget _textArea(String key) => TextFormField(
    initialValue: '${_v[key] ?? ''}',
    minLines: 3, maxLines: 4,
    decoration: const InputDecoration(),
    onChanged: (v) => _v[key] = v,
  );

  Widget _numberField(String key, {bool required = false}) => TextFormField(
    initialValue: _v[key] != null ? '${_v[key]}' : '',
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: const InputDecoration(),
    validator: required ? (v) => (v ?? '').trim().isEmpty ? 'Required' : null : null,
    onChanged: (v) => _v[key] = double.tryParse(v.trim()) ?? 0,
  );

  Widget _dropdown(String key, List<LookupOption> opts, {bool required = false}) {
    final current = '${_v[key] ?? ''}';
    return DropdownButtonFormField<String>(
      value: current.isEmpty ? null : current,
      items: opts.map((o) => DropdownMenuItem(value: o.value, child: Text(o.label))).toList(),
      decoration: const InputDecoration(),
      validator: required ? (v) => (v ?? '').isEmpty ? 'Required' : null : null,
      onChanged: (v) => setState(() => _v[key] = v ?? ''),
    );
  }

  Widget _toggle(String key) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.inputRadius),
        border: Border.all(color: AppTheme.inputBorderColor),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        activeColor: AppTheme.terra400,
        value: _booster,
        title: Text(_booster ? 'Yes' : 'No',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w500)),
        onChanged: (v) => setState(() {
          _booster = v;
          _v[key] = v;
        }),
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
        await widget.controller.updateItem(widget.item!.id, _v);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppTheme.successText,
        content: const Text('Saved successfully'),
        duration: const Duration(milliseconds: 2500),
      ));
    } catch (e) {
      if (!mounted) return;
      _snack(context, e.toString(), AppTheme.dangerText);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

Future<bool?> _showDeleteDialog(BuildContext context) => showDialog<bool>(
  context: context,
  builder: (ctx) => AlertDialog(
    title: const Text('Delete item'),
    content: const Text('Are you sure you want to delete this record?'),
    actions: [
      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
      TextButton(
        onPressed: () => Navigator.of(ctx).pop(true),
        style: TextButton.styleFrom(foregroundColor: AppTheme.dangerText),
        child: const Text('Delete'),
      ),
    ],
  ),
);

void _snack(BuildContext context, String msg, Color color) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    backgroundColor: color,
    content: Text(msg),
    duration: const Duration(milliseconds: 2500),
  ));
}
