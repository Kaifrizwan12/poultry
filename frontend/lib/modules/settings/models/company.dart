import 'base_settings_model.dart';

class Company extends BaseSettingsModel {
  Company({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory Company.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return Company(id: '${map['id'] ?? ''}', data: data);
  }

  String get name          => text('name');
  String get address       => text('address');
  String get phone         => text('phone');
  String get email         => text('email');
  String get ntn           => text('ntn');
  String get strn          => text('strn');
  String get contactPerson => text('contactPerson');
  String get notes         => text('notes');
}
