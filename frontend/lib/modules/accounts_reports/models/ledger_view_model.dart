import 'ledger_entry_model.dart';

class LedgerViewModel {
  const LedgerViewModel({
    required this.account,
    required this.entries,
    required this.openingBalance,
    required this.totalDebits,
    required this.totalCredits,
    required this.closingBalance,
  });

  final Map<String, dynamic> account;
  final List<LedgerEntry> entries;
  final double openingBalance;
  final double totalDebits;
  final double totalCredits;
  final double closingBalance;

  String get accountName => '${account['accountName'] ?? ''}';
  String get accountCode => '${account['accountCode'] ?? ''}';
  String get accountType => '${account['accountType'] ?? ''}';
  String get balanceType => '${account['balanceType'] ?? 'debit'}';

  factory LedgerViewModel.fromJson(Map<String, dynamic> json) {
    final rawAccount = json['account'];
    final account    = rawAccount is Map ? Map<String, dynamic>.from(rawAccount) : <String, dynamic>{};

    final rawEntries = json['entries'];
    final entries    = rawEntries is List
        ? rawEntries
            .whereType<Map>()
            .map((e) => LedgerEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <LedgerEntry>[];

    return LedgerViewModel(
      account:        account,
      entries:        entries,
      openingBalance: _toDouble(json['openingBalance']),
      totalDebits:    _toDouble(json['totalDebits']),
      totalCredits:   _toDouble(json['totalCredits']),
      closingBalance: _toDouble(json['closingBalance']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0.0;
  }
}
