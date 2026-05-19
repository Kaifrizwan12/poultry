import 'package:farm_mgt_auth/modules/settings/models/base_settings_model.dart';

class SalesInvoiceModel extends BaseSettingsModel {
  SalesInvoiceModel({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory SalesInvoiceModel.fromMap(Map<String, dynamic> map) {
    final d = Map<String, dynamic>.from(map)..remove('id');
    return SalesInvoiceModel(id: '${map['id'] ?? ''}', data: d);
  }

  String get saleId         => text('saleId');
  String get entryDate      => text('entryDate');
  String get customerId     => text('customerId');
  String get customerName   => text('customerName');
  String get townId         => text('townId');
  String get sectorId       => text('sectorId');
  String get salesmanId     => text('salesmanId');
  String get salesmanName   => text('salesmanName');
  double get prevDebit      => number('prevDebit');
  String get status         => text('status');
  String get description              => text('description');
  String get remarks                  => text('remarks');
  String get linkedChickenInvoiceId   => text('linkedChickenInvoiceId');

  double get gross          => number('gross');
  double get disc2Percent   => number('disc2Percent');
  double get discounts      => number('discounts');
  double get invoiceValue   => number('invoiceValue');
  double get salesTax       => number('salesTax');
  double get fTax           => number('fTax');
  double get expense        => number('expense');
  double get totalSED       => number('totalSED');
  double get spcDisc        => number('spcDisc');
  double get netValue       => number('netValue');
  double get totalPayable   => number('totalPayable');
  double get ttlQty         => number('ttlQty');
  double get paidAmount     => number('paidAmount');
  double get remBalance     => number('remBalance');

  List<Map<String, dynamic>> get items {
    final raw = data['items'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }
}
