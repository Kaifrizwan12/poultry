import 'package:flutter/material.dart';

import 'app_theme.dart';

class DetailLineCard extends StatelessWidget {
  const DetailLineCard({
    super.key,
    required this.index,
    required this.title,
    this.subtitle,
    this.amount,
    this.amountLabel,
    this.chips = const [],
    this.onEdit,
    this.onDelete,
  });

  final int index;
  final String title;
  final String? subtitle;
  final String? amount;
  final String? amountLabel;
  final List<String> chips;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AppTheme.cardDecor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '#${index + 1}',
                      style: const TextStyle(
                        color: AppTheme.terra600,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: chips
                        .map((chip) => _DetailChip(label: chip))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          if (amount != null || onEdit != null || onDelete != null) ...[
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (amount != null) ...[
                  Text(
                    amount!,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  if (amountLabel != null && amountLabel!.isNotEmpty)
                    Text(
                      amountLabel!,
                      style: const TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                ],
                if (onEdit != null || onDelete != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onEdit != null)
                        IconButton(
                          tooltip: 'Edit item',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 32,
                            height: 32,
                          ),
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppTheme.terra600,
                          ),
                          onPressed: onEdit,
                        ),
                      if (onDelete != null)
                        IconButton(
                          tooltip: 'Delete item',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 32,
                            height: 32,
                          ),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppTheme.dangerText,
                          ),
                          onPressed: onDelete,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.clayBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.softBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
