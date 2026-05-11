import '../models/chicken_invoice_model.dart';
import 'poultry_json_service.dart';

class ChickenInvoiceService extends PoultryJsonService<ChickenInvoiceModel> {
  ChickenInvoiceService()
      : super(entityPath: 'chicken-invoices', parser: ChickenInvoiceModel.fromMap);

  Future<List<ChickenInvoiceModel>> fetchByFlock(String flockId) =>
      fetchAll(queryString: 'flockId=$flockId');
}
