import '../models/flock_feed_model.dart';
import 'poultry_json_service.dart';

class FlockFeedService extends PoultryJsonService<FlockFeedModel> {
  FlockFeedService()
      : super(entityPath: 'flock-feeds', parser: FlockFeedModel.fromMap);

  Future<List<FlockFeedModel>> fetchByFlock(String flockId) =>
      fetchAll(queryString: 'flockId=$flockId');
}
