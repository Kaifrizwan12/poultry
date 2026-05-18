import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:flutter/material.dart';

/// Shows [form] as a full-screen page on mobile (via [Navigator.push]) or
/// as a standard dialog on desktop (via [showDialog]).
///
/// Callers must NOT wrap [form] in a [Dialog] themselves; that is handled here.
Future<void> showInvoicingForm(BuildContext context, Widget form) async {
  if (MediaQuery.of(context).size.width < 600) {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => form),
    );
  } else {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => form,
    );
  }
}

/// Shared shell for all invoicing / transaction form screens.
///
/// Mobile  → renders as a [Scaffold] page with AppBar back-button.
///           Open via [showInvoicingForm] so it appears as a real route.
/// Desktop → renders as a fixed-size [Dialog] with internal scrolling.
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

  // ── Mobile: full-screen Scaffold page ──────────────────────────────────────

  Widget _buildMobilePage(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          tooltip: 'Back',
          onPressed: onClose ?? () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
            if (badgeText != null && badgeText!.isNotEmpty)
              Text(
                badgeText!,
                style: const TextStyle(
                  color: AppTheme.terra600,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: body,
      ),
      bottomNavigationBar: footer != null
          ? Material(
              color: AppTheme.surfaceWhite,
              elevation: 4,
              child: SafeArea(top: false, child: footer!),
            )
          : null,
    );
  }

  // ── Desktop: fixed-size Dialog ─────────────────────────────────────────────

  Widget _buildDesktopDialog(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width < AppTheme.dialogDesktopWidth + 80
        ? size.width - 40
        : AppTheme.dialogDesktopWidth;
    final height = size.height < AppTheme.dialogDesktopHeight + 64
        ? size.height - 32
        : AppTheme.dialogDesktopHeight;

    return Dialog(
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape:
          RoundedRectangleBorder(borderRadius: AppTheme.dialogRadius),
      child: ClipRRect(
        borderRadius: AppTheme.dialogRadius,
        child: SizedBox(
          width: width,
          height: height,
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────
              Container(
                color: AppTheme.surfaceWhite,
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (badgeText != null &&
                              badgeText!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.terra50,
                                borderRadius:
                                    BorderRadius.circular(6),
                                border: Border.all(
                                    color: AppTheme.terra200),
                              ),
                              child: Text(
                                badgeText!,
                                style: const TextStyle(
                                  color: AppTheme.terra800,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed:
                          onClose ?? () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20),
                      tooltip: 'Close',
                      color: AppTheme.textSecondary,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              // ── Scrollable body ───────────────────────────────────────
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, constraints) =>
                      SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          minWidth: constraints.maxWidth),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                            width: double.infinity, child: body),
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return isMobile ? _buildMobilePage(context) : _buildDesktopDialog(context);
  }
}
