import '../models/recovery_invoice_model.dart';
import 'invoicing_json_service.dart';

class RecoveryInvoiceService extends InvoicingJsonService<RecoveryInvoiceModel> {
  RecoveryInvoiceService()
      : super(entityPath: 'recovery-invoices', parser: RecoveryInvoiceModel.fromMap);

  Future<List<RecoveryInvoiceModel>> fetchBySalesman(String salesmanId) =>
      fetchAll(queryString: 'salesmanId=$salesmanId');
}
