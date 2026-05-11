import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:farm_mgt_auth/services/local_storage_service.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = LocalStorageService.cachedUser();
    final greeting = _greeting();
    final displayName =
        ((user?.name ?? '').isNotEmpty) ? (user?.name ?? 'User') : 'User';
    final cards = const [
      _SummaryCardData('Today\'s Sales', Icons.payments_outlined),
      _SummaryCardData('Outstanding Recovery', Icons.account_balance_wallet_outlined),
      _SummaryCardData('Active Customers', Icons.people_outline),
      _SummaryCardData('Pending Orders', Icons.pending_actions_outlined),
    ];

    return SingleChildScrollView(
      padding: AppTheme.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting, $displayName',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Farm Management Dashboard',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cards.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width < 800 ? 2 : 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent:
                  MediaQuery.of(context).size.width < 600 ? 152 : 132,
            ),
            itemBuilder: (context, index) {
              final card = cards[index];
              return LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 126;
                  return Container(
                    padding: EdgeInsets.all(compact ? 14 : 20),
                    decoration: AppTheme.cardDecor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: compact ? 16 : 20,
                          backgroundColor: AppTheme.terra50,
                          child: Icon(
                            card.icon,
                            size: compact ? 16 : 20,
                            color: AppTheme.terra600,
                          ),
                        ),
                        SizedBox(height: compact ? 10 : 14),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              card.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        height: 1.15,
                                        fontSize: compact ? 12 : null,
                                      ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '--',
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: compact ? 20 : null,
                                  ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 17) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }
}

class _SummaryCardData {
  const _SummaryCardData(this.label, this.icon);

  final String label;
  final IconData icon;
}
