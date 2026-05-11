import 'base_settings_model.dart';

class Product extends BaseSettingsModel {
  Product({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory Product.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return Product(id: '${map['id'] ?? ''}', data: data);
  }
}
