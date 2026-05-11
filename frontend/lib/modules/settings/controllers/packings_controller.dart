import '../models/packing.dart';
import '../services/packings_service.dart';
import 'base_settings_controller.dart';

class PackingsController extends SettingsEntityController<Packing> {
  PackingsController() : super(service: PackingsService(), searchableFields: const ['name', 'description']);
}
