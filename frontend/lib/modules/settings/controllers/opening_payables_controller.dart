import '../models/opening_payable.dart';
import '../services/opening_payables_service.dart';
import 'base_settings_controller.dart';

class OpeningPayablesController extends SettingsEntityController<OpeningPayable> {
  OpeningPayablesController() : super(service: OpeningPayablesService(), searchableFields: const ['vendorId', 'date', 'notes']);
}
