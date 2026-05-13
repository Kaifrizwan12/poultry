import 'package:farm_mgt_auth/services/api_service.dart';

import '../models/bank_deposit_model.dart';
import 'invoicing_json_service.dart';

class BankDepositService extends InvoicingJsonService<BankDepositModel> {
  BankDepositService()
      : super(entityPath: 'bank-deposits', parser: BankDepositModel.fromMap);

  final ApiService _apiInstance = ApiService();

  Future<Map<String, dynamic>> confirm(String id) =>
      _apiInstance.patch('/invoicing/bank-deposits/$id/confirm', {}, auth: true);

  Future<Map<String, dynamic>> reconcile(
    String id, {
    String? bankStatementRef,
  }) =>
      _apiInstance.patch(
        '/invoicing/bank-deposits/$id/reconcile',
        {
          if (bankStatementRef != null) 'bankStatementRef': bankStatementRef,
        },
        auth: true,
      );
}
