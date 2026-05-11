import 'package:farm_mgt_auth/modules/settings/models/base_settings_model.dart';

class FlockVaccineModel extends BaseSettingsModel {
  FlockVaccineModel({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory FlockVaccineModel.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return FlockVaccineModel(id: '${map['id'] ?? ''}', data: data);
  }

  String get flockId => text('flockId');
  String get vaccineScheduleId => text('vaccineScheduleId');
  String get date => text('date');
  int get ageDays => number('ageDays').toInt();
  int get birdsVaccinated => number('birdsVaccinated').toInt();
  String get productId => text('productId');
  String get batchNo => text('batchNo');
  String get administrationRoute => text('administrationRoute');
  double get dosePerBird => number('dosePerBird');
  double get totalDoseUsed => number('totalDoseUsed');
  String get administeredBy => text('administeredBy');
  String get nextDueDate => text('nextDueDate');
  String get notes => text('notes');
}
