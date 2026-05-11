import '../models/vendor.dart';
import 'json_settings_service.dart';

class VendorsService extends JsonSettingsService<Vendor> {
  VendorsService() : super(entity: 'vendors', parser: Vendor.fromMap);
}
