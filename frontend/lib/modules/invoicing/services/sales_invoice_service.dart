import '../models/sales_invoice_model.dart';
import 'invoicing_json_service.dart';

class SalesInvoiceService extends InvoicingJsonService<SalesInvoiceModel> {
  SalesInvoiceService()
      : super(entityPath: 'sales-invoices', parser: SalesInvoiceModel.fromMap);

  Future<List<SalesInvoiceModel>> fetchPending() =>
      fetchAll(queryString: 'status=pending');

  Future<List<SalesInvoiceModel>> fetchByCustomer(String customerId) =>
      fetchAll(queryString: 'customerId=$customerId');

  Future<List<SalesInvoiceModel>> fetchBySalesman(String salesmanId) =>
      fetchAll(queryString: 'salesmanId=$salesmanId');
}
