class AppUtils {
  AppUtils._();

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// "2026-04-14" → "14 Apr 2026". Handles partial/invalid strings gracefully.
  static String formatDate(String iso) {
    if (iso.length < 10) return iso;
    try {
      final y = int.parse(iso.substring(0, 4));
      final m = int.parse(iso.substring(5, 7));
      final d = int.parse(iso.substring(8, 10));
      if (m < 1 || m > 12) return iso;
      return '$d ${_months[m - 1]} $y';
    } catch (_) {
      return iso;
    }
  }

  /// Formats a number with thousands commas, no decimals: 125000 → "1,25,000".
  /// Uses standard 3-digit grouping (Western): 1,250,000.
  static String fmtAmt(double v) {
    if (v.isNaN || v.isInfinite) return '0';
    final neg = v < 0;
    final n = v.abs().round();
    final raw = n.toString();
    final buf = StringBuffer();
    final len = raw.length;
    for (int i = 0; i < len; i++) {
      final distFromRight = len - 1 - i;
      if (i > 0 && distFromRight % 3 == 2) buf.write(',');
      buf.write(raw[i]);
    }
    return neg ? '-${buf.toString()}' : buf.toString();
  }

  /// Like fmtAmt but shows 2 decimal places only when non-zero.
  static String fmtAmt2(double v) {
    final neg = v < 0;
    final abs = v.abs();
    final intPart = abs.floor().toDouble();
    final frac = ((abs - intPart) * 100).round();
    final base = fmtAmt(neg ? -intPart : intPart);
    if (frac == 0) return base;
    return '$base.${frac.toString().padLeft(2, '0')}';
  }
}
