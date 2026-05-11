import 'base_settings_model.dart';

class Customer extends BaseSettingsModel {
  Customer({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory Customer.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return Customer(id: '${map['id'] ?? ''}', data: data);
  }
}
