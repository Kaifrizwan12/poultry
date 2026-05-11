import '../models/discount_scheme.dart';
import '../services/discount_schemes_service.dart';
import 'base_settings_controller.dart';

class DiscountSchemesController extends SettingsEntityController<DiscountScheme> {
  DiscountSchemesController() : super(service: DiscountSchemesService(), searchableFields: const ['name', 'type', 'notes']);
}
