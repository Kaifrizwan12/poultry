import '../models/purchase_order_model.dart';
import 'invoicing_json_service.dart';

class PurchaseOrderService extends InvoicingJsonService<PurchaseOrderModel> {
  PurchaseOrderService()
      : super(entityPath: 'purchase-orders', parser: PurchaseOrderModel.fromMap);

  Future<List<PurchaseOrderModel>> fetchPending() =>
      fetchAll(queryString: 'status=pending');

  Future<List<PurchaseOrderModel>> fetchByVendor(String vendorId) =>
      fetchAll(queryString: 'vendorId=$vendorId');
}
