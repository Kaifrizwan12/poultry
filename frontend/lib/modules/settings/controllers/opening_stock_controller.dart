import '../models/opening_stock.dart';
import '../services/opening_stock_service.dart';
import 'base_settings_controller.dart';

class OpeningStockController extends SettingsEntityController<OpeningStock> {
  OpeningStockController() : super(service: OpeningStockService(), searchableFields: const ['productId', 'date']);
}
