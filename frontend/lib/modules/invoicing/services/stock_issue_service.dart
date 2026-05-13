import '../models/stock_issue_model.dart';
import 'invoicing_json_service.dart';

class StockIssueService extends InvoicingJsonService<StockIssueModel> {
  StockIssueService()
      : super(entityPath: 'stock-issues', parser: StockIssueModel.fromMap);

  Future<List<StockIssueModel>> fetchBySalesman(String salesmanId) =>
      fetchAll(queryString: 'salesmanId=$salesmanId');
}
