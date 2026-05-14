import 'base_settings_model.dart';

class Packing extends BaseSettingsModel {
  Packing({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory Packing.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return Packing(id: '${map['id'] ?? ''}', data: data);
  }

  String get name        => text('name');
  String get unitId      => text('unitId');
  double get quantity    => number('quantity');
  String get description => text('description');
}
