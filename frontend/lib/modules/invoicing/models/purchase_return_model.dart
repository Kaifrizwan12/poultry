import 'package:farm_mgt_auth/modules/settings/models/base_settings_model.dart';

class PurchaseReturnModel extends BaseSettingsModel {
  PurchaseReturnModel({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory PurchaseReturnModel.fromMap(Map<String, dynamic> map) {
    final d = Map<String, dynamic>.from(map)..remove('id');
    return PurchaseReturnModel(id: '${map['id'] ?? ''}', data: d);
  }

  String get returnId          => text('returnId');
  String get returnType        => text('returnType');
  String get returnDate        => text('returnDate');
  String get purchaseInvoiceId => text('purchaseInvoiceId');
  String get vendorId          => text('vendorId');
  String get vendorName        => text('vendorName');

  double get gross             => number('gross');
  double get disc2Percent      => number('disc2Percent');
  double get discounts         => number('discounts');
  double get invoiceValue      => number('invoiceValue');
  double get salesTax          => number('salesTax');
  double get fTaxPercent       => number('fTaxPercent');
  double get furtherTaxValue   => number('furtherTaxValue');
  double get netValue          => number('netValue');

  List<Map<String, dynamic>> get items {
    final raw = data['items'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }
}
