import 'package:flutter/material.dart';

class ResponsiveSearchFilterBar extends StatelessWidget {
  const ResponsiveSearchFilterBar({
    super.key,
    required this.search,
    required this.filters,
  });

  final Widget search;
  final List<Widget> filters;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          search,
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: filters),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: search),
        const SizedBox(width: 10),
        for (var i = 0; i < filters.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          filters[i],
        ],
      ],
    );
  }
}
