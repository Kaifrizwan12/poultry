import '../models/sector.dart';
import 'json_settings_service.dart';

class SectorsService extends JsonSettingsService<Sector> {
  SectorsService() : super(entity: 'sectors', parser: Sector.fromMap);
}
