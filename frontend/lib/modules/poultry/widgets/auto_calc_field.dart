import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:flutter/material.dart';

class AutoCalcField extends StatelessWidget {
  const AutoCalcField({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                      height: 1,
                    ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.calculate_outlined,
                  size: 12, color: AppTheme.textTertiary),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.terra50,
              borderRadius: BorderRadius.circular(AppTheme.inputRadius),
              border: Border.all(color: AppTheme.terra100),
            ),
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.terra800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
