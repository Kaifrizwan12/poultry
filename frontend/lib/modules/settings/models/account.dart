import 'base_settings_model.dart';

class Account extends BaseSettingsModel {
  Account({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory Account.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return Account(id: '${map['id'] ?? ''}', data: data);
  }
}
