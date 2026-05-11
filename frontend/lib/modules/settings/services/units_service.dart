import '../models/unit.dart';
import 'json_settings_service.dart';

class UnitsService extends JsonSettingsService<Unit> {
  UnitsService() : super(entity: 'units', parser: Unit.fromMap);
}
