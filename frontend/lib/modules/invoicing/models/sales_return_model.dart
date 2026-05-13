import 'package:farm_mgt_auth/modules/settings/models/base_settings_model.dart';

class SalesReturnModel extends BaseSettingsModel {
  SalesReturnModel({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory SalesReturnModel.fromMap(Map<String, dynamic> map) {
    final d = Map<String, dynamic>.from(map)..remove('id');
    return SalesReturnModel(id: '${map['id'] ?? ''}', data: d);
  }

  String get returnId       => text('returnId');
  String get returnType     => text('returnType');
  String get returnDate     => text('returnDate');
  String get saleId         => text('saleId');
  String get saleDate       => text('saleDate');
  bool   get isFullReturn   => boolean('isFullReturn');
  String get customerId     => text('customerId');
  String get customerName   => text('customerName');
  String get townId         => text('townId');
  String get sectorId       => text('sectorId');
  String get salesmanId     => text('salesmanId');
  String get salesmanName   => text('salesmanName');
  bool   get toMainStore    => boolean('toMainStore');
  String get description    => text('description');

  double get disc2Percent   => number('disc2Percent');
  double get invoiceValue   => number('invoiceValue');
  double get salesTax       => number('salesTax');
  double get fTaxPercent    => number('fTaxPercent');
  double get furtherTaxValue => number('furtherTaxValue');
  double get sed            => number('sed');
  double get specialDiscount => number('specialDiscount');
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
