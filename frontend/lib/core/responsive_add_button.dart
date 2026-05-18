import 'package:flutter/material.dart';

class ResponsiveAddButton extends StatelessWidget {
  const ResponsiveAddButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.tooltip,
  });

  final VoidCallback onPressed;
  final String label;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      return Tooltip(
        message: tooltip ?? label,
        child: SizedBox(
          width: 44,
          height: 44,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 44),
            ),
            child: const Icon(Icons.add, size: 20),
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add, size: 18),
      label: Text(label),
    );
  }
}
