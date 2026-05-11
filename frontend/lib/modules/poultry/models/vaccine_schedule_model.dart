import 'package:farm_mgt_auth/modules/settings/models/base_settings_model.dart';

class VaccineScheduleModel extends BaseSettingsModel {
  VaccineScheduleModel({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory VaccineScheduleModel.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return VaccineScheduleModel(id: '${map['id'] ?? ''}', data: data);
  }

  String get name => text('name');
  String get vaccineType => text('vaccineType');
  int get targetAgeDays => number('targetAgeDays').toInt();
  String get administrationRoute => text('administrationRoute');
  double get dosePerBird => number('dosePerBird');
  String get productId => text('productId');
  bool get boosterRequired => boolean('boosterRequired');
  int get boosterIntervalDays => number('boosterIntervalDays').toInt();
  String get description => text('description');
}
