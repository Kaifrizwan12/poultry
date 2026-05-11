import 'base_settings_model.dart';

class OpeningPayable extends BaseSettingsModel {
  OpeningPayable({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory OpeningPayable.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return OpeningPayable(id: '${map['id'] ?? ''}', data: data);
  }
}
