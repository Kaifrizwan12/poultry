import '../models/packing.dart';
import 'json_settings_service.dart';

class PackingsService extends JsonSettingsService<Packing> {
  PackingsService() : super(entity: 'packings', parser: Packing.fromMap);
}
