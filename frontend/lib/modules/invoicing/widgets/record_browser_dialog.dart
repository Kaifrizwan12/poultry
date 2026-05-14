import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/modules/settings/models/base_settings_model.dart';
import 'package:flutter/material.dart';

/// Generic record-browser dialog used on every invoicing screen.
///
/// Shows all [records] in a searchable, scrollable list.
/// The user taps a row → the dialog pops with the selected model.
/// Replaces both "Open by ID" and "Open Pending" on every screen.
///
/// Usage:
/// ```dart
/// final record = await RecordBrowserDialog.show<SalesInvoiceModel>(
///   context: context,
///   records: ctrl.items,
///   title: 'Sales Invoices',
///   getBusinessId: (m) => m.saleId,
///   getTitle: (m) => '${m.saleId}  •  ${m.customerName}',
///   getSubtitle: (m) => '${m.entryDate.substring(0,10)}  |  ${m.status}  |  Rs ${m.totalPayable.toStringAsFixed(0)}',
///   statusField: 'status',   // optional — enables Pending tab
/// );
/// if (record != null) _loadFromModel(record);
/// ```
class RecordBrowserDialog<T extends BaseSettingsModel> extends StatefulWidget {
  const RecordBrowserDialog({
    super.key,
    required this.records,
    required this.title,
    required this.getBusinessId,
    required this.getTitle,
    required this.getSubtitle,
    this.statusField,
  });

  final List<T> records;
  final String title;
  final String Function(T) getBusinessId;
  final String Function(T) getTitle;
  final String Function(T) getSubtitle;
  /// If provided, a "Pending" tab is shown filtering on status == 'pending'
  final String? statusField;

  static Future<T?> show<T extends BaseSettingsModel>({
    required BuildContext context,
    required List<T> records,
    required String title,
    required String Function(T) getBusinessId,
    required String Function(T) getTitle,
    required String Function(T) getSubtitle,
    String? statusField,
  }) {
    return showDialog<T>(
      context: context,
      builder: (_) => RecordBrowserDialog<T>(
        records: records,
        title: title,
        getBusinessId: getBusinessId,
        getTitle: getTitle,
        getSubtitle: getSubtitle,
        statusField: statusField,
      ),
    );
  }

  @override
  State<RecordBrowserDialog<T>> createState() => _RecordBrowserDialogState<T>();
}

class _RecordBrowserDialogState<T extends BaseSettingsModel>
    extends State<RecordBrowserDialog<T>> {
  final _searchCtrl = TextEditingController();
  String _query   = '';
  bool _pendingOnly = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<T> get _filtered {
    var list = widget.records;

    if (_pendingOnly && widget.statusField != null) {
      list = list.where((m) => m.text(widget.statusField!) == 'pending').toList();
    }

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((m) {
        return widget.getBusinessId(m).toLowerCase().contains(q) ||
               widget.getTitle(m).toLowerCase().contains(q) ||
               widget.getSubtitle(m).toLowerCase().contains(q);
      }).toList();
    }

    // Most-recent first (records are already fetched desc by createdAt,
    // but we sort locally so search results stay stable)
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final hasPending = widget.statusField != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppTheme.dialogRadius),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 580),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
              decoration: BoxDecoration(
                color: AppTheme.clayBg,
                borderRadius: BorderRadius.only(
                  topLeft:  Radius.circular(AppTheme.dialogRadius.topLeft.x),
                  topRight: Radius.circular(AppTheme.dialogRadius.topRight.x),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_open_outlined, size: 20, color: AppTheme.terra600),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppTheme.textPrimary)),
                  ),
                  Text('${widget.records.length} records',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: AppTheme.textSecondary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // ── Search + tab row ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search by ID, name, date…',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                        isDense: true,
                        filled: true,
                        fillColor: AppTheme.surfaceWhite,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.inputRadius),
                          borderSide: const BorderSide(color: AppTheme.softBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.inputRadius),
                          borderSide: const BorderSide(color: AppTheme.softBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.inputRadius),
                          borderSide:
                              const BorderSide(color: AppTheme.terra400, width: 1.4),
                        ),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  if (hasPending) ...[
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('Pending'),
                      selected: _pendingOnly,
                      selectedColor: AppTheme.terra100,
                      backgroundColor: AppTheme.surfaceWhite,
                      side: BorderSide(
                        color: _pendingOnly ? AppTheme.terra400 : AppTheme.softBorder,
                      ),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: _pendingOnly ? AppTheme.terra800 : AppTheme.textSecondary,
                        fontWeight: _pendingOnly ? FontWeight.w700 : FontWeight.w500,
                      ),
                      onSelected: (v) => setState(() => _pendingOnly = v),
                    ),
                  ],
                ],
              ),
            ),
            // ── Record count indicator ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                '${filtered.length} record${filtered.length == 1 ? '' : 's'}'
                '${_query.isNotEmpty ? ' matching "$_query"' : ''}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
              ),
            ),
            const Divider(height: 1, color: AppTheme.pageDivider),
            // ── List ─────────────────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off, size: 36,
                              color: AppTheme.textTertiary),
                          const SizedBox(height: 8),
                          Text(
                            _query.isNotEmpty
                                ? 'No records match "$_query"'
                                : _pendingOnly
                                    ? 'No pending records'
                                    : 'No records yet',
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 16, endIndent: 16,
                              color: AppTheme.pageDivider),
                      itemBuilder: (context, idx) {
                        final record = filtered[idx];
                        final bizId  = widget.getBusinessId(record);
                        final title  = widget.getTitle(record);
                        final sub    = widget.getSubtitle(record);
                        final isPending = widget.statusField != null &&
                            record.text(widget.statusField!) == 'pending';

                        return InkWell(
                          onTap: () => Navigator.pop(context, record),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                // Business ID badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.terra50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppTheme.terra200),
                                  ),
                                  child: Text(
                                    bizId.isNotEmpty ? bizId : '—',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.terra800,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(title,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary),
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text(sub,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textSecondary),
                                          overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                if (isPending)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.warningBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('PENDING',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.warningText)),
                                  ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right,
                                    size: 18, color: AppTheme.textTertiary),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // ── Footer ───────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.pageDivider)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tap a record to open it.',
                      style: TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
