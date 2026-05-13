import '../models/salesman_cash_reconciliation_model.dart';
import 'invoicing_json_service.dart';

class SalesmanCashReconciliationService
    extends InvoicingJsonService<SalesmanCashReconciliationModel> {
  SalesmanCashReconciliationService()
      : super(
          entityPath: 'salesman-cash-reconciliations',
          parser: SalesmanCashReconciliationModel.fromMap,
        );

  Future<List<SalesmanCashReconciliationModel>> fetchPending() =>
      fetchAll(queryString: 'status=pending');

  Future<List<SalesmanCashReconciliationModel>> fetchBySalesman(String salesmanId) =>
      fetchAll(queryString: 'salesmanId=$salesmanId');
}
