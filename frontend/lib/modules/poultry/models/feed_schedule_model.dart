import 'package:farm_mgt_auth/modules/settings/models/base_settings_model.dart';

class FeedScheduleModel extends BaseSettingsModel {
  FeedScheduleModel({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory FeedScheduleModel.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return FeedScheduleModel(id: '${map['id'] ?? ''}', data: data);
  }

  String get name => text('name');
  String get feedType => text('feedType');
  int get ageFromDays => number('ageFromDays').toInt();
  int get ageToDays => number('ageToDays').toInt();
  double get dailyFeedPerBirdGrams => number('dailyFeedPerBirdGrams');
  String get productId => text('productId');
  String get packingId => text('packingId');
  String get description => text('description');
}
