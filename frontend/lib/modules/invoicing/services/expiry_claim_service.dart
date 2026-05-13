import '../models/expiry_claim_model.dart';
import 'invoicing_json_service.dart';

class ExpiryClaimService extends InvoicingJsonService<ExpiryClaimModel> {
  ExpiryClaimService()
      : super(entityPath: 'expiry-claims', parser: ExpiryClaimModel.fromMap);

  Future<List<ExpiryClaimModel>> fetchByCustomer(String customerId) =>
      fetchAll(queryString: 'customerId=$customerId');

  Future<List<ExpiryClaimModel>> fetchByVendor(String vendorId) =>
      fetchAll(queryString: 'vendorId=$vendorId');
}
