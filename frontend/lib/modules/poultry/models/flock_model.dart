import 'package:farm_mgt_auth/modules/settings/models/base_settings_model.dart';

class FlockModel extends BaseSettingsModel {
  FlockModel({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory FlockModel.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return FlockModel(id: '${map['id'] ?? ''}', data: data);
  }

  String get flockNo => text('flockNo');
  String get flockName => text('flockName');
  String get birdType => text('birdType');
  String get breed => text('breed');
  String get placementDate => text('placementDate');
  int get initialBirdsCount => number('initialBirdsCount').toInt();
  int get currentBirdsCount => number('currentBirdsCount').toInt();
  String get shedNo => text('shedNo');
  String get vendorId => text('vendorId');
  double get placementWeightKg => number('placementWeightKg');
  double get targetWeightKg => number('targetWeightKg');
  int get targetAgeDays => number('targetAgeDays').toInt();
  List<String> get feedScheduleIds => stringList('feedScheduleIds');
  List<String> get vaccineScheduleIds => stringList('vaccineScheduleIds');
  String get status => text('status');
  String get closureDate => text('closureDate');
  String get closureReason => text('closureReason');
  String get notes => text('notes');

  bool get isActive => status == 'active';
  bool get isSold => status == 'sold';
  bool get isClosed => status == 'closed';

  int get ageDays {
    try {
      final placement = DateTime.parse(placementDate);
      return DateTime.now().difference(placement).inDays.clamp(0, 9999);
    } catch (_) {
      return 0;
    }
  }

  int get mortalityCount => (initialBirdsCount - currentBirdsCount).clamp(0, initialBirdsCount);

  double get mortalityRate =>
      initialBirdsCount > 0 ? mortalityCount / initialBirdsCount * 100 : 0.0;
}
