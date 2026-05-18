import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'app_utils.dart';

/// Compact card for a single line item inside an invoice / return form dialog.
/// Used on mobile in place of the DataTable row.
class LineItemCard extends StatelessWidget {
  const LineItemCard({
    super.key,
    required this.index,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    this.detailLine,
  });

  final int index;
  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String? detailLine;

  @override
  Widget build(BuildContext context) {
    final productName = '${item['productName'] ?? ''}';
    final packingName = '${item['packingName'] ?? ''}';
    final qtyPacks = (item['qtyPacks'] as num?)?.toStringAsFixed(0) ?? '0';
    final qtyLoose = (item['qtyLoose'] as num?)?.toStringAsFixed(0) ?? '0';
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final discPct = (item['discPercent'] as num?)?.toDouble() ?? 0.0;
    final gross = (item['lineGross'] as num?)?.toDouble() ?? 0.0;

    final qtyStr = int.tryParse(qtyLoose) == 0
        ? '${qtyPacks}P'
        : '${qtyPacks}P + ${qtyLoose}L';

    final detailText = detailLine ??
        [
          if (packingName.isNotEmpty) packingName,
          'Qty: $qtyStr',
          'PKR ${AppUtils.fmtAmt2(price)}',
          if (discPct > 0) 'Disc: ${discPct.toStringAsFixed(1)}%',
        ].join('  ·  ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: (index % 2 == 0)
            ? AppTheme.surfaceWhite
            : AppTheme.clayBg.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(color: AppTheme.softBorder.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: product + details ─────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${index + 1}. $productName',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                if (detailText.isNotEmpty)
                  Text(
                    detailText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // ── Right: gross + actions ──────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppUtils.fmtAmt(gross),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: 'Edit item',
                    child: GestureDetector(
                      onTap: onEdit,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.edit_outlined,
                            size: 16, color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                  Tooltip(
                    message: 'Delete item',
                    child: GestureDetector(
                      onTap: onDelete,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline,
                            size: 16, color: AppTheme.dangerText),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
