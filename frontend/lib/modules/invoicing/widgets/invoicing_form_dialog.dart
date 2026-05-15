import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:flutter/material.dart';

/// Shared fixed-size dialog shell for list-first invoicing forms.
///
/// Desktop/tablet uses a consistent fixed size with internal scrolling.
/// Mobile falls back to edge-to-edge sizing so complex forms remain usable.
class InvoicingFormDialog extends StatelessWidget {
  const InvoicingFormDialog({
    super.key,
    required this.title,
    required this.body,
    this.footer,
    this.badgeText,
    this.onClose,
  });

  final String title;
  final Widget body;
  final Widget? footer;
  final String? badgeText;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    final width = isMobile
        ? size.width
        : size.width < AppTheme.dialogDesktopWidth + 80
            ? size.width - 40
            : AppTheme.dialogDesktopWidth;
    final height = isMobile
        ? size.height
        : size.height < AppTheme.dialogDesktopHeight + 64
            ? size.height - 32
            : AppTheme.dialogDesktopHeight;

    return Dialog(
      insetPadding: isMobile
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: AppTheme.dialogRadius),
      child: ClipRRect(
        borderRadius: AppTheme.dialogRadius,
        child: SizedBox(
          width: width,
          height: height,
          child: Column(
            children: [
              Container(
                color: AppTheme.surfaceWhite,
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                child: Row(
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    if (badgeText != null && badgeText!.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.terra50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.terra200),
                        ),
                        child: Text(
                          badgeText!,
                          style: const TextStyle(
                            color: AppTheme.terra800,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    IconButton(
                      onPressed: onClose ?? () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20),
                      color: AppTheme.textSecondary,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: double.infinity,
                          child: body,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (footer != null) ...[
                const Divider(height: 1, thickness: 1),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
