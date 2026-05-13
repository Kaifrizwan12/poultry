import 'package:farm_mgt_auth/services/api_service.dart';

import '../models/bank_cheque_model.dart';
import 'invoicing_json_service.dart';

class BankChequeService extends InvoicingJsonService<BankChequeModel> {
  BankChequeService()
      : super(entityPath: 'bank-cheques', parser: BankChequeModel.fromMap);

  final ApiService _apiInstance = ApiService();

  Future<List<BankChequeModel>> fetchByStatus(String status) =>
      fetchAll(queryString: 'status=$status');

  Future<Map<String, dynamic>> updateStatus(
    String id,
    String status, {
    String? clearedDate,
  }) =>
      _apiInstance.patch(
        '/invoicing/bank-cheques/$id/status',
        {
          'status': status,
          if (clearedDate != null) 'clearedDate': clearedDate,
        },
        auth: true,
      );
}
