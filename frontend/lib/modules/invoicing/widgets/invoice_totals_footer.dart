import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:farm_mgt_auth/core/horizontal_scroll_wheel.dart';

class InvoiceTotalsFooter extends StatelessWidget {
  const InvoiceTotalsFooter({
    super.key,
    required this.totals,
    required this.visibleKeys,
  });

  final Map<String, double> totals;
  final List<String> visibleKeys;

  static const Map<String, String> _labels = {
    'gross': 'Gross',
    'disc2Percent': 'Disc%',
    'discounts': 'Discounts',
    'invoiceValue': 'Inv.Value',
    'salesTax': 'S.Tax',
    'fTax': 'F.Tax',
    'expense': 'Expense',
    'totalSED': 'SED',
    'spcDisc': 'Spc.Disc',
    'netValue': 'Net',
    'totalPayable': 'Payable',
    'ttlQty': 'Qty',
    'paidAmount': 'Paid',
    'remBalance': 'Balance',
    'furtherTaxValue': 'FTax Value',
    'fTaxPercent': 'FTax%',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.clayBg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: HorizontalScrollWheel(child: Row(
          children: visibleKeys.map((key) {
            final label = _labels[key] ?? key;
            final value = totals[key] ?? 0.0;
            return Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value.toStringAsFixed(2),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
