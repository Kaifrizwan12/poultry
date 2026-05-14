import 'base_settings_model.dart';

class ProductGroup extends BaseSettingsModel {
  ProductGroup({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory ProductGroup.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return ProductGroup(id: '${map['id'] ?? ''}', data: data);
  }

  String get name        => text('name');
  String get description => text('description');
}
