import '../models/purchase_invoice_model.dart';
import 'invoicing_json_service.dart';

class PurchaseInvoiceService extends InvoicingJsonService<PurchaseInvoiceModel> {
  PurchaseInvoiceService()
      : super(entityPath: 'purchase-invoices', parser: PurchaseInvoiceModel.fromMap);

  Future<List<PurchaseInvoiceModel>> fetchPending() =>
      fetchAll(queryString: 'status=pending');

  Future<List<PurchaseInvoiceModel>> fetchByVendor(String vendorId) =>
      fetchAll(queryString: 'vendorId=$vendorId');
}
