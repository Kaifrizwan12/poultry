import 'package:farm_mgt_auth/modules/settings/models/base_settings_model.dart';

class StockWastageModel extends BaseSettingsModel {
  StockWastageModel({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory StockWastageModel.fromMap(Map<String, dynamic> map) {
    final d = Map<String, dynamic>.from(map)..remove('id');
    return StockWastageModel(id: '${map['id'] ?? ''}', data: d);
  }

  String get wastageId => text('wastageId');
  String get date      => text('date');
  double get netValue  => number('netValue');

  List<Map<String, dynamic>> get items {
    final raw = data['items'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }
}
