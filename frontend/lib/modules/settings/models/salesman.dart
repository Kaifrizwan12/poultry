import 'base_settings_model.dart';

class Salesman extends BaseSettingsModel {
  Salesman({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory Salesman.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return Salesman(id: '${map['id'] ?? ''}', data: data);
  }
}
