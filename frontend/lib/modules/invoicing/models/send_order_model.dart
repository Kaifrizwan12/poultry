import 'package:farm_mgt_auth/modules/settings/models/base_settings_model.dart';

class SendOrderModel extends BaseSettingsModel {
  SendOrderModel({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory SendOrderModel.fromMap(Map<String, dynamic> map) {
    final d = Map<String, dynamic>.from(map)..remove('id');
    return SendOrderModel(id: '${map['id'] ?? ''}', data: d);
  }

  String get sendOrderId    => text('sendOrderId');
  String get orderId        => text('orderId');
  String get vendorId       => text('vendorId');
  String get vendorName     => text('vendorName');
  String get draftNo        => text('draftNo');
  String get draftDate      => text('draftDate');
  double get draftAmount    => number('draftAmount');
  String get bankAccountId  => text('bankAccountId');
  String get bankAcNo       => text('bankAcNo');
  String get bankAccountName => text('bankAccountName');
  String get description    => text('description');
  bool   get includeAllProductsWhenPrinting => boolean('includeAllProductsWhenPrinting');
  double get totalOrderValue => number('totalOrderValue');

  List<Map<String, dynamic>> get items {
    final raw = data['items'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }
}
