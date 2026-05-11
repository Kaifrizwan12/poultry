import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/models/lookup_option.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/products_controller.dart';
import 'package:farm_mgt_auth/modules/settings/controllers/packings_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/poultry_definitions.dart';
import '../controllers/feed_schedule_controller.dart';
import '../models/feed_schedule_model.dart';
import '_poultry_crud_screen.dart';

class FeedScheduleScreen extends StatelessWidget {
  const FeedScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productsCtrl  = context.read<ProductsController>();
    final packingsCtrl  = context.read<PackingsController>();

    final List<LookupOption> productOptions = productsCtrl.items
        .map((p) => LookupOption(value: p.id, label: p.text('name')))
        .toList();
    final List<LookupOption> packingOptions = packingsCtrl.items
        .map((p) => LookupOption(value: p.id, label: p.text('name')))
        .toList();

    return Consumer<FeedScheduleController>(
      builder: (context, ctrl, _) {
        return PoultryCrudScreen<FeedScheduleModel>(
          title: 'Feed Schedules',
          addLabel: 'Add Feed Schedule',
          isLoading: ctrl.isLoading,
          error: ctrl.error,
          items: ctrl.filteredItems,
          searchQuery: ctrl.searchQuery,
          onSearch: ctrl.setSearchQuery,
          onAdd: () => _openEditor(context, ctrl, productOptions, packingOptions),
          onEdit: (item) => _openEditor(context, ctrl, productOptions, packingOptions, item),
          onDelete: (item) => _confirmDelete(context, ctrl, item),
          itemTitle: (item) => item.name,
          itemSubtitleRows: (item) => [
            _Row('Feed Type', labelFor(kFeedTypes, item.feedType)),
            _Row('Age Range', '${item.ageFromDays}–${item.ageToDays} days'),
            _Row('Feed/Bird/Day', '${item.dailyFeedPerBirdGrams} g'),
          ],
        );
      },
    );
  }

  void _openEditor(
    BuildContext context,
    FeedScheduleController ctrl,
    List<LookupOption> productOptions,
    List<LookupOption> packingOptions, [
    FeedScheduleModel? item,
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
            child: _FeedScheduleForm(
              controller: ctrl,
              productOptions: productOptions,
              packingOptions: packingOptions,
              item: item,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    FeedScheduleController ctrl,
    FeedScheduleModel item,
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

// ─── Row helper (local only) ──────────────────────────────────────────────────
class _Row {
  const _Row(this.label, this.value);
  final String label;
  final String value;
}

// ─── Form ─────────────────────────────────────────────────────────────────────

class _FeedScheduleForm extends StatefulWidget {
  const _FeedScheduleForm({
    required this.controller,
    required this.productOptions,
    required this.packingOptions,
    this.item,
  });

  final FeedScheduleController controller;
  final List<LookupOption> productOptions;
  final List<LookupOption> packingOptions;
  final FeedScheduleModel? item;

  @override
  State<_FeedScheduleForm> createState() => _FeedScheduleFormState();
}

class _FeedScheduleFormState extends State<_FeedScheduleForm> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _v;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _v = widget.item != null ? widget.item!.toJson() : {};
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
              widget.item == null ? 'Add Feed Schedule' : 'Edit Feed Schedule',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            _field('Name', _textField('name', required: true)),
            _field('Feed Type', _dropdownField('feedType', kFeedTypes, required: true)),
            _field('Age From (Days)', _numberField('ageFromDays', required: true)),
            _field('Age To (Days)', _numberField('ageToDays', required: true)),
            _field('Feed/Bird/Day (grams)', _numberField('dailyFeedPerBirdGrams', required: true)),
            _field('Feed Product *', _dropdownField('productId', widget.productOptions, required: true)),
            _field('Preferred Packing', _dropdownField('packingId', widget.packingOptions)),
            _field('Description', _textArea('description')),
            const SizedBox(height: 20),
            _actions(),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, height: 1)),
        const SizedBox(height: 6),
        child,
      ],
    ),
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

  Widget _dropdownField(String key, List<LookupOption> options, {bool required = false}) {
    final current = '${_v[key] ?? ''}';
    return DropdownButtonFormField<String>(
      value: current.isEmpty ? null : current,
      items: options.map((o) => DropdownMenuItem(value: o.value, child: Text(o.label))).toList(),
      decoration: const InputDecoration(),
      validator: required ? (v) => (v ?? '').isEmpty ? 'Required' : null : null,
      onChanged: (v) => setState(() => _v[key] = v ?? ''),
    );
  }

  Widget _actions() => Row(children: [
    Expanded(child: OutlinedButton(
      onPressed: _saving ? null : () => Navigator.of(context).pop(),
      child: const Text('Cancel'),
    )),
    const SizedBox(width: 12),
    Expanded(child: ElevatedButton(
      onPressed: _saving ? null : _save,
      child: Text(_saving ? 'Saving…' : 'Save'),
    )),
  ]);

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

// ─── Shared helpers ───────────────────────────────────────────────────────────

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
