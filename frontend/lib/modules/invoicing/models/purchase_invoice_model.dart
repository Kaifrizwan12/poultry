import 'package:farm_mgt_auth/modules/settings/models/base_settings_model.dart';

class PurchaseInvoiceModel extends BaseSettingsModel {
  PurchaseInvoiceModel({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory PurchaseInvoiceModel.fromMap(Map<String, dynamic> map) {
    final d = Map<String, dynamic>.from(map)..remove('id');
    return PurchaseInvoiceModel(id: '${map['id'] ?? ''}', data: d);
  }

  String get purchaseId     => text('purchaseId');
  String get entryDate      => text('entryDate');
  String get vendorBillNo   => text('vendorBillNo');
  String get billDate       => text('billDate');
  String get orderId        => text('orderId');
  String get orderDate      => text('orderDate');
  String get vendorId       => text('vendorId');
  String get vendorName     => text('vendorName');
  String get city           => text('city');
  String get status         => text('status');
  String get description    => text('description');

  double get gross          => number('gross');
  double get disc2Percent   => number('disc2Percent');
  double get discounts      => number('discounts');
  double get invoiceValue   => number('invoiceValue');
  double get salesTax       => number('salesTax');
  double get fTax           => number('fTax');
  double get totalSED       => number('totalSED');
  double get spcDisc        => number('spcDisc');
  double get netValue       => number('netValue');
  double get prevCredit     => number('prevCredit');
  double get totalPayable   => number('totalPayable');
  double get paidAmount     => number('paidAmount');
  double get remBalance     => number('remBalance');

  List<Map<String, dynamic>> get items {
    final raw = data['items'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }
}
