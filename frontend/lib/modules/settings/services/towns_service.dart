import '../models/town.dart';
import 'json_settings_service.dart';

class TownsService extends JsonSettingsService<Town> {
  TownsService() : super(entity: 'towns', parser: Town.fromMap);
}
