import 'package:farm_mgt_auth/modules/settings/models/base_settings_model.dart';

class CashVoucherModel extends BaseSettingsModel {
  CashVoucherModel({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory CashVoucherModel.fromMap(Map<String, dynamic> map) {
    final d = Map<String, dynamic>.from(map)..remove('id');
    return CashVoucherModel(id: '${map['id'] ?? ''}', data: d);
  }

  String get voucherType    => text('voucherType');
  String get voucherNo      => text('voucherNo');
  String get voucherDate    => text('voucherDate');
  bool   get isConfirmed    => boolean('isConfirmed');
  String get confirmedDate  => text('confirmedDate');
  String get confirmedBy    => text('confirmedBy');

  double get totalDebit {
    final t = data['totals'];
    if (t is Map) return (t['debit'] as num?)?.toDouble() ?? 0;
    return 0;
  }

  double get totalCredit {
    final t = data['totals'];
    if (t is Map) return (t['credit'] as num?)?.toDouble() ?? 0;
    return 0;
  }

  List<Map<String, dynamic>> get lines {
    final raw = data['lines'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }
}
