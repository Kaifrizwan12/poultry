import '../models/flock_vaccine_model.dart';
import 'poultry_json_service.dart';

class FlockVaccineService extends PoultryJsonService<FlockVaccineModel> {
  FlockVaccineService()
      : super(entityPath: 'flock-vaccines', parser: FlockVaccineModel.fromMap);

  Future<List<FlockVaccineModel>> fetchByFlock(String flockId) =>
      fetchAll(queryString: 'flockId=$flockId');
}
