import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Thin, tap-able card used in mobile list views across all invoicing/
/// transaction screens. Kept intentionally compact so bulk records fit
/// comfortably on screen without scrolling through a lot of whitespace.
class RecordCard extends StatelessWidget {
  const RecordCard({
    super.key,
    required this.id,
    this.subtitle,
    this.meta,
    this.amount,
    this.badge,
    this.onTap,
    this.trailing,
    this.isOffline = false,
  });

  /// Primary identifier shown in bold (e.g. "SI-0001", "SR-0001").
  final String id;

  /// Entity name: customer, vendor, salesman, etc.
  final String? subtitle;

  /// Secondary short line: formatted date + any extra label.
  final String? meta;

  /// Formatted amount string (e.g. "10,875" or "10,875.50").
  final String? amount;

  /// Status chip or any small badge widget placed below amount.
  final Widget? badge;

  /// Custom trailing column (for action buttons on reconciliation screens).
  /// When provided, replaces the default amount+badge column.
  final Widget? trailing;

  /// Opens the detail / form dialog.
  final VoidCallback? onTap;

  /// Tints the card slightly to signal cached data.
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isOffline
              ? AppTheme.warningBg.withValues(alpha: 0.4)
              : AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.softBorder.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Left: id + subtitle ───────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        id,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppTheme.terra600,
                        ),
                      ),
                      if (meta != null) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            meta!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textTertiary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            // ── Right: amount + badge  OR  custom trailing ────────────────
            if (trailing != null)
              trailing!
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (amount != null)
                    Text(
                      amount!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  if (badge != null) ...[
                    const SizedBox(height: 3),
                    badge!,
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
