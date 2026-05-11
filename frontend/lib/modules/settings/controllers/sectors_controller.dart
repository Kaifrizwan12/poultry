import '../models/sector.dart';
import '../services/sectors_service.dart';
import 'base_settings_controller.dart';

class SectorsController extends SettingsEntityController<Sector> {
  SectorsController() : super(service: SectorsService(), searchableFields: const ['name', 'description']);
}
