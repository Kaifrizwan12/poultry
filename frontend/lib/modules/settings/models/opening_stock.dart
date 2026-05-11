import 'base_settings_model.dart';

class OpeningStock extends BaseSettingsModel {
  OpeningStock({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory OpeningStock.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return OpeningStock(id: '${map['id'] ?? ''}', data: data);
  }
}
