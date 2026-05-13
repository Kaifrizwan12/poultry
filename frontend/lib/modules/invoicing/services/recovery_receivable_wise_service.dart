import '../models/recovery_receivable_wise_model.dart';
import 'invoicing_json_service.dart';

class RecoveryReceivableWiseService extends InvoicingJsonService<RecoveryReceivableWiseModel> {
  RecoveryReceivableWiseService()
      : super(entityPath: 'recovery-receivable-wise', parser: RecoveryReceivableWiseModel.fromMap);

  Future<List<RecoveryReceivableWiseModel>> fetchBySalesman(String salesmanId) =>
      fetchAll(queryString: 'salesmanId=$salesmanId');
}
