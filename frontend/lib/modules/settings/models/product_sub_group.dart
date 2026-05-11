import 'base_settings_model.dart';

class ProductSubGroup extends BaseSettingsModel {
  ProductSubGroup({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory ProductSubGroup.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return ProductSubGroup(id: '${map['id'] ?? ''}', data: data);
  }
}
