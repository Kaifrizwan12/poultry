import 'base_settings_model.dart';

class DiscountScheme extends BaseSettingsModel {
  DiscountScheme({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory DiscountScheme.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return DiscountScheme(id: '${map['id'] ?? ''}', data: data);
  }
}
