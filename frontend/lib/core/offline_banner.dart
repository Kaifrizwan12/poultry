import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Shown at the top of any list screen when the controller is serving
/// cached (offline) data. Keeps users aware they're seeing stale records.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      color: AppTheme.warningBg,
      child: Row(
        children: const [
          Icon(Icons.cloud_off_outlined, size: 14, color: AppTheme.warningText),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing cached data — changes will sync when back online',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.warningText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
