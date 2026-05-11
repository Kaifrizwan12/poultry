class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.entryNo,
    required this.entryDate,
    required this.accountId,
    required this.entryType,
    required this.amount,
    required this.description,
    required this.referenceType,
    this.referenceId,
    this.referenceNo,
    required this.tags,
    required this.isReconciled,
    this.reconciledAt,
    this.notes,
    required this.uid,
    required this.createdAt,
    required this.updatedAt,
    this.runningBalance,
  });

  final String id;
  final String entryNo;
  final String entryDate;
  final String accountId;
  final String entryType;    // 'debit' | 'credit'
  final double amount;
  final String description;
  final String referenceType;
  final String? referenceId;
  final String? referenceNo;
  final List<String> tags;
  final bool isReconciled;
  final String? reconciledAt;
  final String? notes;
  final String uid;
  final String createdAt;
  final String updatedAt;

  // Only populated in the by-account view response
  final double? runningBalance;

  bool get isDebit  => entryType == 'debit';
  bool get isCredit => entryType == 'credit';

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    final tags = rawTags is List
        ? rawTags.map((t) => '$t').toList()
        : <String>[];
    return LedgerEntry(
      id:            '${json['id'] ?? ''}',
      entryNo:       '${json['entryNo'] ?? ''}',
      entryDate:     '${json['entryDate'] ?? ''}',
      accountId:     '${json['accountId'] ?? ''}',
      entryType:     '${json['entryType'] ?? 'debit'}',
      amount:        _toDouble(json['amount']),
      description:   '${json['description'] ?? ''}',
      referenceType: '${json['referenceType'] ?? 'manual'}',
      referenceId:   json['referenceId'] as String?,
      referenceNo:   json['referenceNo'] as String?,
      tags:          tags,
      isReconciled:  json['isReconciled'] == true,
      reconciledAt:  json['reconciledAt'] as String?,
      notes:         json['notes'] as String?,
      uid:           '${json['uid'] ?? ''}',
      createdAt:     '${json['createdAt'] ?? ''}',
      updatedAt:     '${json['updatedAt'] ?? ''}',
      runningBalance: json['runningBalance'] != null ? _toDouble(json['runningBalance']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'entryNo':       entryNo,
    'entryDate':     entryDate,
    'accountId':     accountId,
    'entryType':     entryType,
    'amount':        amount,
    'description':   description,
    'referenceType': referenceType,
    'referenceId':   referenceId,
    'referenceNo':   referenceNo,
    'tags':          tags,
    'isReconciled':  isReconciled,
    'notes':         notes,
  };

  LedgerEntry copyWith({double? runningBalance}) => LedgerEntry(
    id: id, entryNo: entryNo, entryDate: entryDate, accountId: accountId,
    entryType: entryType, amount: amount, description: description,
    referenceType: referenceType, referenceId: referenceId, referenceNo: referenceNo,
    tags: tags, isReconciled: isReconciled, reconciledAt: reconciledAt, notes: notes,
    uid: uid, createdAt: createdAt, updatedAt: updatedAt,
    runningBalance: runningBalance ?? this.runningBalance,
  );

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0.0;
  }
}
