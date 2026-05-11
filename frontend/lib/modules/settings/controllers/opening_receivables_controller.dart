import '../models/opening_receivable.dart';
import '../services/opening_receivables_service.dart';
import 'base_settings_controller.dart';

class OpeningReceivablesController extends SettingsEntityController<OpeningReceivable> {
  OpeningReceivablesController() : super(service: OpeningReceivablesService(), searchableFields: const ['customerId', 'date', 'notes']);
}
