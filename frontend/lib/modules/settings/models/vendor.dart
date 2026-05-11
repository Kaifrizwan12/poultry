import 'base_settings_model.dart';

class Vendor extends BaseSettingsModel {
  Vendor({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory Vendor.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return Vendor(id: '${map['id'] ?? ''}', data: data);
  }
}
