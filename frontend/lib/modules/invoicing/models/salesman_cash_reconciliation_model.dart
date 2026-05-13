import 'package:farm_mgt_auth/modules/settings/models/base_settings_model.dart';

class SalesmanCashReconciliationModel extends BaseSettingsModel {
  SalesmanCashReconciliationModel({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory SalesmanCashReconciliationModel.fromMap(Map<String, dynamic> map) {
    final d = Map<String, dynamic>.from(map)..remove('id');
    return SalesmanCashReconciliationModel(id: '${map['id'] ?? ''}', data: d);
  }

  String get reconciliationId  => text('reconciliationId');
  String get date              => text('date');
  String get salesmanId        => text('salesmanId');
  String get salesmanName      => text('salesmanName');
  double get openingBalance    => number('openingBalance');
  double get totalCashReceived => number('totalCashReceived');
  double get totalDiscount     => number('totalDiscount');
  double get totalExpenses     => number('totalExpenses');
  double get cashDeposited     => number('cashDeposited');
  double get closingBalance    => number('closingBalance');
  String get status            => text('status');

  List<Map<String, dynamic>> get recoveryEntries {
    final raw = data['recoveryEntries'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }

  List<Map<String, dynamic>> get expenseEntries {
    final raw = data['expenseEntries'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }
}
