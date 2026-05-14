import 'base_settings_model.dart';

class Unit extends BaseSettingsModel {
  Unit({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory Unit.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return Unit(id: '${map['id'] ?? ''}', data: data);
  }

  String get name         => text('name');
  String get abbreviation => text('abbreviation');
  String get description  => text('description');
}
