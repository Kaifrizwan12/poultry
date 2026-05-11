import '../models/salesman.dart';
import 'json_settings_service.dart';

class SalesmenService extends JsonSettingsService<Salesman> {
  SalesmenService() : super(entity: 'salesmen', parser: Salesman.fromMap);
}
