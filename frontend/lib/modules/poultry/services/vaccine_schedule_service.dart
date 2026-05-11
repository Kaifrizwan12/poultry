import '../models/vaccine_schedule_model.dart';
import 'poultry_json_service.dart';

class VaccineScheduleService extends PoultryJsonService<VaccineScheduleModel> {
  VaccineScheduleService()
      : super(entityPath: 'vaccine-schedules', parser: VaccineScheduleModel.fromMap);
}
