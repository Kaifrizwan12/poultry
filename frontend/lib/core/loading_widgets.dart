import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Slim animated bar pinned to the very top of a screen column.
/// Use whenever data is loading — even when stale data is already visible.
/// Keeps page content in place; no jarring blank-then-reload flicker.
class TopLoadingBar extends StatelessWidget {
  const TopLoadingBar({super.key, required this.isLoading, this.child});

  final bool isLoading;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (child != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoading)
            LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
              color: AppTheme.terra400,
            ),
          Expanded(child: child!),
        ],
      );
    }
    if (!isLoading) return const SizedBox.shrink();
    return LinearProgressIndicator(
      minHeight: 2,
      backgroundColor: Colors.transparent,
      color: AppTheme.terra400,
    );
  }
}

/// Centered spinner for initial empty-state loading.
class CenteredLoader extends StatelessWidget {
  const CenteredLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Expanded(
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
