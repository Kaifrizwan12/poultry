import 'package:farm_mgt_auth/modules/settings/models/base_settings_model.dart';

class RecoveryReceivableWiseModel extends BaseSettingsModel {
  RecoveryReceivableWiseModel({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory RecoveryReceivableWiseModel.fromMap(Map<String, dynamic> map) {
    final d = Map<String, dynamic>.from(map)..remove('id');
    return RecoveryReceivableWiseModel(id: '${map['id'] ?? ''}', data: d);
  }

  String get recoveryId               => text('recoveryId');
  String get recoveryDate             => text('recoveryDate');
  String get salesmanId               => text('salesmanId');
  String get salesmanName             => text('salesmanName');
  String get townId                   => text('townId');
  String get sectorId                 => text('sectorId');
  bool   get showSalesmanInNarration  => boolean('showSalesmanInNarration');
  double get netReceived              => number('netReceived');
  double get discount                 => number('discount');
  double get grossRecoveries          => number('grossRecoveries');

  List<Map<String, dynamic>> get customerRecoveries {
    final raw = data['customerRecoveries'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }
}
