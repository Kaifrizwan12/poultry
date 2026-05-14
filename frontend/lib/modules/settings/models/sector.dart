import 'base_settings_model.dart';

class Sector extends BaseSettingsModel {
  Sector({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory Sector.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return Sector(id: '${map['id'] ?? ''}', data: data);
  }

  String get name        => text('name');
  String get townId      => text('townId');
  String get description => text('description');
}
