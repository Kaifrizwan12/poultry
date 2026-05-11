import '../models/opening_stock.dart';
import 'json_settings_service.dart';

class OpeningStockService extends JsonSettingsService<OpeningStock> {
  OpeningStockService()
      : super(entity: 'openings/stock', parser: OpeningStock.fromMap);
}
