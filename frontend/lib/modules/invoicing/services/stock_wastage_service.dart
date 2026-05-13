import '../models/stock_wastage_model.dart';
import 'invoicing_json_service.dart';

class StockWastageService extends InvoicingJsonService<StockWastageModel> {
  StockWastageService()
      : super(entityPath: 'stock-wastages', parser: StockWastageModel.fromMap);
}
