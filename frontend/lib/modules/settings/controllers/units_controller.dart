import '../models/unit.dart';
import '../services/units_service.dart';
import 'base_settings_controller.dart';

class UnitsController extends SettingsEntityController<Unit> {
  UnitsController() : super(service: UnitsService(), searchableFields: const ['name', 'abbreviation', 'description']);
}
