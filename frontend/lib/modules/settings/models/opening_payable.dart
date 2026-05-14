import 'base_settings_model.dart';

class OpeningPayable extends BaseSettingsModel {
  OpeningPayable({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory OpeningPayable.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return OpeningPayable(id: '${map['id'] ?? ''}', data: data);
  }

  String get vendorId => text('vendorId');
  double get amount   => number('amount');
  String get date     => text('date');
  String get notes    => text('notes');
}
