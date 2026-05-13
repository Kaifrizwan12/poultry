import '../models/send_order_model.dart';
import 'invoicing_json_service.dart';

class SendOrderService extends InvoicingJsonService<SendOrderModel> {
  SendOrderService()
      : super(entityPath: 'send-orders', parser: SendOrderModel.fromMap);

  Future<List<SendOrderModel>> fetchByVendor(String vendorId) =>
      fetchAll(queryString: 'vendorId=$vendorId');
}
