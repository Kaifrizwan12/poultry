import 'package:farm_mgt_auth/core/app_theme.dart';
import 'package:flutter/material.dart';

/// Responsive action bar used on all invoicing/transaction form screens.
///
/// Desktop (≥ 600 px): full horizontal row of buttons — original layout.
/// Mobile  (< 600 px): primary action button (Save/Load) stays visible.
///                     All secondary actions collapse into a circular ⋯ FAB
///                     at the bottom-right that opens a modal bottom sheet.
///
/// Pass [null] for any callback to hide that button entirely.
/// Pass [canRemove] = false to show Remove as disabled (record not yet loaded).
class InvoicingActionBar extends StatelessWidget {
  const InvoicingActionBar({
    super.key,
    // ── Primary / always-visible ──────────────────────────────────────────
    this.onSave,
    this.saveLabel = 'Save',
    this.isSaving  = false,
    // ── Secondary (overflow on mobile) ───────────────────────────────────
    this.onPending,
    this.onClear,
    this.onRecords,
    this.onRemove,
    this.canRemove = false,
    // ── Filter-table screens use these instead of Save ────────────────────
    this.onLoad,
    this.onSaveChanges,
    // ── Always present ────────────────────────────────────────────────────
    this.onClose,
  });

  final VoidCallback? onSave;
  final String saveLabel;
  final bool isSaving;

  final VoidCallback? onPending;
  final VoidCallback? onClear;
  final VoidCallback? onRecords;
  final VoidCallback? onRemove;
  final bool canRemove;

  final VoidCallback? onLoad;
  final VoidCallback? onSaveChanges;

  final VoidCallback? onClose;

  // ── Helpers ──────────────────────────────────────────────────────────────

  // Actions shown in the bottom sheet on mobile (all except the primary).
  List<_ActionItem> _secondaryActions() {
    return [
      if (onPending != null)
        _ActionItem('Pending', Icons.hourglass_top_outlined,
            onPending, isDestructive: false),
      if (onClear != null)
        _ActionItem('Clear', Icons.refresh_outlined, onClear),
      if (onRecords != null)
        _ActionItem('Records', Icons.folder_open_outlined, onRecords),
      if (onLoad != null)
        _ActionItem('Load', Icons.search_outlined, onLoad),
      if (onSaveChanges != null)
        _ActionItem('Save Changes', Icons.save_outlined, onSaveChanges),
      _ActionItem('Print', Icons.print_outlined, () {}),   // placeholder
      if (onRemove != null || canRemove)
        _ActionItem(
          'Remove',
          Icons.delete_outline,
          canRemove ? onRemove : null,
          isDestructive: true,
        ),
      if (onClose != null)
        _ActionItem('Close', Icons.close, onClose),
    ];
  }

  void _openBottomSheet(BuildContext context) {
    final items = _secondaryActions();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // drag handle
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.softBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ...items.map((item) => ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: item.isDestructive
                      ? const Color(0xFFFEF2F2)
                      : AppTheme.terra50,
                  child: Icon(
                    item.icon,
                    size: 18,
                    color: item.isDestructive
                        ? AppTheme.dangerText
                        : item.onTap == null
                            ? AppTheme.textTertiary
                            : AppTheme.terra600,
                  ),
                ),
                title: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: item.isDestructive
                        ? AppTheme.dangerText
                        : item.onTap == null
                            ? AppTheme.textTertiary
                            : AppTheme.textPrimary,
                  ),
                ),
                enabled: item.onTap != null,
                onTap: item.onTap == null
                    ? null
                    : () {
                        Navigator.pop(context);
                        item.onTap!();
                      },
              )),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  bool get _hasAnyAction =>
      onSave != null || onPending != null || onClear != null ||
      onRecords != null || onRemove != null || onLoad != null ||
      onSaveChanges != null || onClose != null;

  @override
  Widget build(BuildContext context) {
    if (!_hasAnyAction) return const SizedBox.shrink();
    final isMobile = MediaQuery.of(context).size.width < 600;
    return isMobile ? _buildMobile(context) : _buildDesktop(context);
  }

  // Desktop: full horizontal button row — same as before
  Widget _buildDesktop(BuildContext context) {
    return Container(
      color: AppTheme.surfaceWhite,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          if (onPending != null) ...[
            TextButton(
              onPressed: isSaving ? null : onPending,
              child: const Text('Pending'),
            ),
            const SizedBox(width: 2),
          ],
          if (onClear != null) ...[
            TextButton(onPressed: onClear, child: const Text('Clear')),
            const SizedBox(width: 2),
          ],
          if (onRecords != null) ...[
            TextButton(onPressed: onRecords, child: const Text('Records')),
            const SizedBox(width: 2),
          ],
          if (onLoad != null) ...[
            TextButton(onPressed: onLoad, child: const Text('Load')),
            const SizedBox(width: 2),
          ],
          Tooltip(
            message: 'Print coming soon',
            child: TextButton(
              onPressed: null,
              child: const Text('Print'),
            ),
          ),
          const SizedBox(width: 2),
          if (onRemove != null || canRemove)
            TextButton(
              onPressed: canRemove ? onRemove : null,
              style: TextButton.styleFrom(
                  foregroundColor: AppTheme.dangerText),
              child: const Text('Remove'),
            ),
          const Spacer(),
          if (onSave != null)
            ElevatedButton(
              onPressed: isSaving ? null : onSave,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 56),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(saveLabel),
            ),
          if (onSaveChanges != null) ...[
            ElevatedButton(
              onPressed: onSaveChanges,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 56),
              ),
              child: const Text('Save Changes'),
            ),
          ],
          const SizedBox(width: 8),
          if (onClose != null)
            OutlinedButton(
              onPressed: onClose,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 56),
              ),
              child: const Text('Close'),
            ),
        ],
      ),
    );
  }

  // Mobile: primary button + circular ⋯ menu FAB
  Widget _buildMobile(BuildContext context) {
    final hasPrimary = onSave != null || onSaveChanges != null || onLoad != null;

    return Container(
      color: AppTheme.surfaceWhite,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          // ── Left: primary action, full width ───────────────────────────
          Expanded(
            child: hasPrimary
                ? ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : onSave ?? onSaveChanges ?? onLoad,
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56)),
                    child: isSaving
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : Text(onSave != null
                            ? saveLabel
                            : onSaveChanges != null
                                ? 'Save Changes'
                                : 'Load'),
                  )
                : OutlinedButton(
                    onPressed: onClose,
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56)),
                    child: const Text('Close'),
                  ),
          ),
          const SizedBox(width: 12),
          // ── Right: circular ⋯ button ────────────────────────────────────
          Material(
            color: AppTheme.terra50,
            shape: const CircleBorder(
                side: BorderSide(color: AppTheme.terra200)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _openBottomSheet(context),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.more_horiz,
                    size: 20, color: AppTheme.terra600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionItem {
  const _ActionItem(this.label, this.icon, this.onTap,
      {this.isDestructive = false});
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDestructive;
}
