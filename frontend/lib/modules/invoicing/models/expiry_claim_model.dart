import 'package:farm_mgt_auth/modules/settings/models/base_settings_model.dart';

class ExpiryClaimModel extends BaseSettingsModel {
  ExpiryClaimModel({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory ExpiryClaimModel.fromMap(Map<String, dynamic> map) {
    final d = Map<String, dynamic>.from(map)..remove('id');
    return ExpiryClaimModel(id: '${map['id'] ?? ''}', data: d);
  }

  String get claimId           => text('claimId');
  String get direction         => text('direction');
  String get claimDate         => text('claimDate');
  String get customerId        => text('customerId');
  String get customerName      => text('customerName');
  String get vendorId          => text('vendorId');
  String get vendorName        => text('vendorName');
  double get netValue          => number('netValue');
  String get replyDate         => text('replyDate');
  bool   get returnSameProducts => boolean('returnSameProducts');
  double get replyNetValue     => number('replyNetValue');
  double get repliedAmount     => number('repliedAmount');

  List<Map<String, dynamic>> get items {
    final raw = data['items'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }

  List<Map<String, dynamic>> get replyItems {
    final raw = data['replyItems'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }
}
