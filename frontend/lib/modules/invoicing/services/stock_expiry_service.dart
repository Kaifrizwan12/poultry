import '../models/stock_expiry_model.dart';
import 'invoicing_json_service.dart';

class StockExpiryService extends InvoicingJsonService<StockExpiryModel> {
  StockExpiryService()
      : super(entityPath: 'stock-expiries', parser: StockExpiryModel.fromMap);
}
