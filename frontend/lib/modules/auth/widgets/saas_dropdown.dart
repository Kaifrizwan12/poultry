import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';

class SaasDropdown extends StatelessWidget {
  const SaasDropdown({
    super.key,
    required this.onChanged,
    this.value,
  });

  final ValueChanged<String?> onChanged;
  final String? value;

  // Only two options are active for now. Others are displayed as coming soon.
  static const List<Map<String, Object>> _items = <Map<String, Object>>[
    <String, Object>{
      'label': 'Poultry farming',
      'value': 'poultry',
      'note': 'Layer and broiler workflows',
      'enabled': true,
    },
    <String, Object>{
      'label': 'Chicken farm',
      'value': 'chicken',
      'note': 'Small-scale to commercial',
      'enabled': true,
    },
    <String, Object>{
      'label': 'Crop farming',
      'value': 'crop',
      'note': 'Fields, irrigation, seasonal planning',
      'enabled': false,
    },
    <String, Object>{
      'label': 'Livestock',
      'value': 'livestock',
      'note': 'Herd health, feed, breeding, barns',
      'enabled': false,
    },
    <String, Object>{
      'label': 'Horticulture',
      'value': 'horticulture',
      'note': 'Nursery, greenhouse, orchard workflows',
      'enabled': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Farm model',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(
            hintText: 'Select the type of operation',
            prefixIcon: Icon(Icons.agriculture_outlined),
          ),
          selectedItemBuilder: (BuildContext context) {
            return _items.map((Map<String, Object> item) {
              final String label = item['label'] as String;
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }).toList();
          },
          items: _items.map((Map<String, Object> item) {
            final bool enabled = item['enabled'] as bool? ?? true;
            final String label = item['label'] as String;
            final String note = item['note'] as String;
            return DropdownMenuItem<String>(
              value: item['value'] as String,
              enabled: enabled,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Flexible(
                    fit: FlexFit.loose,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: enabled
                          ? null
                          : Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).disabledColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (enabled)
                    Flexible(
                      child: Text(
                        note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontSize: 11.5),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.claySurface,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                          color: AppTheme.clayBorder,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        'Coming soon',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
