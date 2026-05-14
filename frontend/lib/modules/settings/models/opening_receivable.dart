import 'base_settings_model.dart';

class OpeningReceivable extends BaseSettingsModel {
  OpeningReceivable({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory OpeningReceivable.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return OpeningReceivable(id: '${map['id'] ?? ''}', data: data);
  }

  String get customerId => text('customerId');
  double get amount     => number('amount');
  String get date       => text('date');
  String get notes      => text('notes');
}
