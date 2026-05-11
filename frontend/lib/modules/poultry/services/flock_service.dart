import '../models/flock_model.dart';
import 'poultry_json_service.dart';

class FlockService extends PoultryJsonService<FlockModel> {
  FlockService() : super(entityPath: 'flocks', parser: FlockModel.fromMap);

  Future<List<FlockModel>> fetchByStatus(String status) =>
      fetchAll(queryString: 'status=$status');
}
