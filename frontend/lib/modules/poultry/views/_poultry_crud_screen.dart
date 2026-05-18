// Generic CRUD list/detail layout — mirrors _CategoryCrudView from settings.
// Used by FeedScheduleScreen and VaccineScheduleScreen.

import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:flutter/material.dart';

class _MetaRow {
  const _MetaRow(this.label, this.value);
  final String label;
  final String value;
}

class PoultryCrudScreen<T> extends StatelessWidget {
  const PoultryCrudScreen({
    super.key,
    required this.title,
    required this.addLabel,
    required this.isLoading,
    required this.error,
    required this.items,
    required this.searchQuery,
    required this.onSearch,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.itemTitle,
    required this.itemSubtitleRows,
  });

  final String title;
  final String addLabel;
  final bool isLoading;
  final String? error;
  final List<T> items;
  final String searchQuery;
  final void Function(String) onSearch;
  final VoidCallback onAdd;
  final void Function(T) onEdit;
  final void Function(T) onDelete;
  final String Function(T) itemTitle;
  final List<dynamic> Function(T) itemSubtitleRows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                    label: Text(addLabel),
                  ),
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600))),
              const SizedBox(width: 12),
              ElevatedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: Text(addLabel)),
            ],
          );
        }),
        const SizedBox(height: 16),
        TextField(
          onChanged: onSearch,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search'),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: AppTheme.cardDecor,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _buildList(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context) {
    if (error != null)
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(16), child: Text(error!)));
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined,
                size: 64, color: AppTheme.textTertiary),
            const SizedBox(height: 12),
            Text('No ${title.toLowerCase()} added yet',
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onAdd, child: Text(addLabel)),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (isLoading)
          LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: Colors.transparent,
            color: AppTheme.terra400,
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final rows = itemSubtitleRows(item);
              return _RecordCard(
                title: itemTitle(item),
                rows: rows.cast<dynamic>(),
                onEdit: () => onEdit(item),
                onDelete: () => onDelete(item),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.title,
    required this.rows,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final List<dynamic> rows;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final stacked = constraints.maxWidth < 420;
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
            if (stacked)
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _TitleBlock(title: title),
                const SizedBox(height: 12),
                _ActionButtons(onEdit: onEdit, onDelete: onDelete),
              ])
            else
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _TitleBlock(title: title)),
                _ActionButtons(onEdit: onEdit, onDelete: onDelete),
              ]),
            if (rows.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(height: 1, color: AppTheme.listTileDivider),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: rows.map((row) {
                  final label = row is _MetaRow ? row.label : '${row.runtimeType}';
                  final value = row is _MetaRow ? row.value : '$row';
                  // Support dynamic objects with .label and .value
                  final l = _extractField(row, 'label') ?? label;
                  final v = _extractField(row, 'value') ?? value;
                  return _MetaBadge(label: l, value: v, context: context);
                }).toList(),
              ),
            ],
          ],
        ),
      );
    });
  }

  String? _extractField(dynamic obj, String field) {
    try {
      if (field == 'label') return (obj as dynamic).label as String?;
      if (field == 'value') return (obj as dynamic).value as String?;
    } catch (_) {}
    return null;
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('NAME', style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 11, letterSpacing: 0.3)),
      const SizedBox(height: 6),
      Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
    ],
  );
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.onEdit, required this.onDelete});
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    _ActionBtn(icon: Icons.edit_outlined, color: AppTheme.textSecondary, onTap: onEdit),
    const SizedBox(width: 8),
    _ActionBtn(icon: Icons.delete_outline, color: AppTheme.dangerText, onTap: onDelete),
  ]);
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: AppTheme.pageBg,
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.softBorder),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    ),
  );
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.label, required this.value, required this.context});
  final String label;
  final String value;
  final BuildContext context;
  @override
  Widget build(BuildContext ctx) => Container(
    constraints: const BoxConstraints(maxWidth: 280),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppTheme.pageBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.softBorder),
    ),
    child: RichText(text: TextSpan(
      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary, height: 1.45),
      children: [
        TextSpan(text: '$label; ', style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
          color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 12)),
        TextSpan(text: value, style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
          color: AppTheme.textPrimary, fontWeight: FontWeight.w500, fontSize: 12)),
      ],
    )),
  );
}
