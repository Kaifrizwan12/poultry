import 'base_settings_model.dart';

class DiscountScheme extends BaseSettingsModel {
  DiscountScheme({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory DiscountScheme.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return DiscountScheme(id: '${map['id'] ?? ''}', data: data);
  }

  String get name         => text('name');
  String get type         => text('type');
  double get value        => number('value');
  String get applicableTo => text('applicableTo');
  String get refId        => text('refId');
  String get validFrom    => text('validFrom');
  String get validTo      => text('validTo');
  String get notes        => text('notes');
}
