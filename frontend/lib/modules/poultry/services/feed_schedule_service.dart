import '../models/feed_schedule_model.dart';
import 'poultry_json_service.dart';

class FeedScheduleService extends PoultryJsonService<FeedScheduleModel> {
  FeedScheduleService()
      : super(entityPath: 'feed-schedules', parser: FeedScheduleModel.fromMap);
}
