import '../models/purchase_return_model.dart';
import 'invoicing_json_service.dart';

class PurchaseReturnService extends InvoicingJsonService<PurchaseReturnModel> {
  PurchaseReturnService()
      : super(entityPath: 'purchase-returns', parser: PurchaseReturnModel.fromMap);

  Future<List<PurchaseReturnModel>> fetchByVendor(String vendorId) =>
      fetchAll(queryString: 'vendorId=$vendorId');
}
