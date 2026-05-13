import 'package:farm_mgt_auth/services/api_service.dart';

import '../models/payment_promise_model.dart';
import 'invoicing_json_service.dart';

class PaymentPromiseService extends InvoicingJsonService<PaymentPromiseModel> {
  PaymentPromiseService()
      : super(entityPath: 'payment-promises', parser: PaymentPromiseModel.fromMap);

  final ApiService _apiInstance = ApiService();

  Future<List<PaymentPromiseModel>> fetchPending() =>
      fetchAll(queryString: 'status=pending');

  Future<Map<String, dynamic>> updateStatus(
    String id,
    String status, {
    String? processedDate,
  }) =>
      _apiInstance.patch(
        '/invoicing/payment-promises/$id/status',
        {
          'status': status,
          if (processedDate != null) 'processedDate': processedDate,
        },
        auth: true,
      );
}
