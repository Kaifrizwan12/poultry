import 'package:farm_mgt_auth/modules/settings/models/base_settings_model.dart';

class ChickenInvoiceModel extends BaseSettingsModel {
  ChickenInvoiceModel({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory ChickenInvoiceModel.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return ChickenInvoiceModel(id: '${map['id'] ?? ''}', data: data);
  }

  String get invoiceNo => text('invoiceNo');
  String get flockId => text('flockId');
  String get customerId => text('customerId');
  String get invoiceDate => text('invoiceDate');
  String get saleType => text('saleType');
  int get birdsCount => number('birdsCount').toInt();
  double get totalLiveWeightKg => number('totalLiveWeightKg');
  double get dressedWeightKg => number('dressedWeightKg');
  double get pricePerKg => number('pricePerKg');
  double get grossAmount => number('grossAmount');
  double get discountPercent => number('discountPercent');
  double get discountAmount => number('discountAmount');
  double get netAmount => number('netAmount');
  double get taxPercent => number('taxPercent');
  double get taxAmount => number('taxAmount');
  double get totalAmount => number('totalAmount');
  double get advanceReceived => number('advanceReceived');
  double get balanceDue => number('balanceDue');
  String get paymentStatus => text('paymentStatus');
  String get vehicleNo => text('vehicleNo');
  String get driverName => text('driverName');
  String get salesmanId => text('salesmanId');
  String get notes => text('notes');
}
