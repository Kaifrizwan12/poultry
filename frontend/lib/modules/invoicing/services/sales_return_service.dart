import '../models/sales_return_model.dart';
import 'invoicing_json_service.dart';

class SalesReturnService extends InvoicingJsonService<SalesReturnModel> {
  SalesReturnService()
      : super(entityPath: 'sales-returns', parser: SalesReturnModel.fromMap);

  Future<List<SalesReturnModel>> fetchByCustomer(String customerId) =>
      fetchAll(queryString: 'customerId=$customerId');
}
