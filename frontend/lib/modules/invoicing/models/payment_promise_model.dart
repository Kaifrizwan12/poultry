import 'package:farm_mgt_auth/modules/settings/models/base_settings_model.dart';

class PaymentPromiseModel extends BaseSettingsModel {
  PaymentPromiseModel({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory PaymentPromiseModel.fromMap(Map<String, dynamic> map) {
    final d = Map<String, dynamic>.from(map)..remove('id');
    return PaymentPromiseModel(id: '${map['id'] ?? ''}', data: d);
  }

  String get promiseId     => text('promiseId');
  String get promiseType   => text('promiseType');
  String get entryDate     => text('entryDate');
  String get promiseDate   => text('promiseDate');
  String get customerId    => text('customerId');
  String get customerName  => text('customerName');
  String get vendorId      => text('vendorId');
  String get vendorName    => text('vendorName');
  String get salesmanId    => text('salesmanId');
  String get salesmanName  => text('salesmanName');
  String get chequeNo      => text('chequeNo');
  String get bankName      => text('bankName');
  double get amount        => number('amount');
  String get narration     => text('narration');
  String get status        => text('status');
  String get processedDate => text('processedDate');

  List<String> get linkedSaleIds     => stringList('linkedSaleIds');
  List<String> get linkedPurchaseIds => stringList('linkedPurchaseIds');
}
