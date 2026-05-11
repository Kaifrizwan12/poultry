import '../models/vendor.dart';
import '../services/vendors_service.dart';
import 'base_settings_controller.dart';

class VendorsController extends SettingsEntityController<Vendor> {
  VendorsController() : super(service: VendorsService(), searchableFields: const ['name', 'phone', 'email', 'town']);
}
