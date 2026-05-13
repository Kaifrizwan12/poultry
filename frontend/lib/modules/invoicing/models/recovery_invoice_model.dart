import 'package:farm_mgt_auth/modules/settings/models/base_settings_model.dart';

class RecoveryInvoiceModel extends BaseSettingsModel {
  RecoveryInvoiceModel({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory RecoveryInvoiceModel.fromMap(Map<String, dynamic> map) {
    final d = Map<String, dynamic>.from(map)..remove('id');
    return RecoveryInvoiceModel(id: '${map['id'] ?? ''}', data: d);
  }

  String get recoveryId    => text('recoveryId');
  String get date          => text('date');
  String get salesmanId    => text('salesmanId');
  String get salesmanName  => text('salesmanName');
  int    get totalNoInvoices => (data['totalNoInvoices'] as num?)?.toInt() ?? 0;
  double get amount        => number('amount');
  double get discount      => number('discount');

  List<Map<String, dynamic>> get customerRecoveries {
    final raw = data['customerRecoveries'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }
}
