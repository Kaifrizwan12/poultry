import '../models/recovery_invoice_wise_model.dart';
import 'invoicing_json_service.dart';

class RecoveryInvoiceWiseService extends InvoicingJsonService<RecoveryInvoiceWiseModel> {
  RecoveryInvoiceWiseService()
      : super(entityPath: 'recovery-invoices-wise', parser: RecoveryInvoiceWiseModel.fromMap);

  Future<List<RecoveryInvoiceWiseModel>> fetchBySalesman(String salesmanId) =>
      fetchAll(queryString: 'salesmanId=$salesmanId');
}
