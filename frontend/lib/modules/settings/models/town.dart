import 'base_settings_model.dart';

class Town extends BaseSettingsModel {
  Town({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory Town.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return Town(id: '${map['id'] ?? ''}', data: data);
  }
}
