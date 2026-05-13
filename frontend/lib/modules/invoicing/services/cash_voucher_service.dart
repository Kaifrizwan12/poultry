import 'package:farm_mgt_auth/services/api_service.dart';

import '../models/cash_voucher_model.dart';
import 'invoicing_json_service.dart';

class CashVoucherService extends InvoicingJsonService<CashVoucherModel> {
  CashVoucherService()
      : super(entityPath: 'cash-vouchers', parser: CashVoucherModel.fromMap);

  Future<List<CashVoucherModel>> fetchByType(String voucherType) =>
      fetchAll(queryString: 'voucherType=$voucherType');

  Future<Map<String, dynamic>> confirm(String id) =>
      _apiInstance.patch('/invoicing/cash-vouchers/$id/confirm', {}, auth: true);

  // Expose api instance for PATCH — InvoicingJsonService wraps it privately,
  // so we create our own for the extra PATCH call.
  final ApiService _apiInstance = ApiService();
}
