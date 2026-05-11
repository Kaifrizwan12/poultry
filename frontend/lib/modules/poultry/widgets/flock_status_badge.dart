import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:flutter/material.dart';

class FlockStatusBadge extends StatelessWidget {
  const FlockStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'active':
        bg = AppTheme.successBg;
        fg = AppTheme.successText;
        label = 'Active';
        break;
      case 'sold':
        bg = AppTheme.terra50;
        fg = AppTheme.terra600;
        label = 'Sold';
        break;
      case 'closed':
      default:
        bg = AppTheme.pageBg;
        fg = AppTheme.textSecondary;
        label = 'Closed';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
