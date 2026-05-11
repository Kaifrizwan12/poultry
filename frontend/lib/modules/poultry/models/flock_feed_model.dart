import 'package:farm_mgt_auth/modules/settings/models/base_settings_model.dart';

class FlockFeedModel extends BaseSettingsModel {
  FlockFeedModel({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory FlockFeedModel.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return FlockFeedModel(id: '${map['id'] ?? ''}', data: data);
  }

  String get flockId => text('flockId');
  String get feedScheduleId => text('feedScheduleId');
  String get date => text('date');
  int get ageDays => number('ageDays').toInt();
  int get birdsCount => number('birdsCount').toInt();
  int get mortalityCount => number('mortalityCount').toInt();
  double get feedConsumedKg => number('feedConsumedKg');
  double get standardFeedKg => number('standardFeedKg');
  double get feedVarianceKg => number('feedVarianceKg');
  double get averageWeightKg => number('averageWeightKg');
  String get productId => text('productId');
  String get batchNo => text('batchNo');
  String get notes => text('notes');
}
