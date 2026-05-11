import '../models/salesman.dart';
import '../services/salesmen_service.dart';
import 'base_settings_controller.dart';

class SalesmenController extends SettingsEntityController<Salesman> {
  SalesmenController() : super(service: SalesmenService(), searchableFields: const ['name', 'code', 'phone', 'email']);
}
