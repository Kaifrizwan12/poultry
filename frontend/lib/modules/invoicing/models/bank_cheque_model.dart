import 'package:farm_mgt_auth/modules/settings/models/base_settings_model.dart';

class BankChequeModel extends BaseSettingsModel {
  BankChequeModel({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory BankChequeModel.fromMap(Map<String, dynamic> map) {
    final d = Map<String, dynamic>.from(map)..remove('id');
    return BankChequeModel(id: '${map['id'] ?? ''}', data: d);
  }

  String get chequeId          => text('chequeId');
  String get chequeNo          => text('chequeNo');
  String get chequeDate        => text('chequeDate');
  String get bankAccountId     => text('bankAccountId');
  String get bankAcNo          => text('bankAcNo');
  String get bankAccountName   => text('bankAccountName');
  String get payeeType         => text('payeeType');
  String get vendorId          => text('vendorId');
  String get vendorName        => text('vendorName');
  String get payeeAccountId    => text('payeeAccountId');
  String get payeeAccountName  => text('payeeAccountName');
  String get payeeName         => text('payeeName');
  double get amount            => number('amount');
  String get narration         => text('narration');
  bool   get isPostDated       => boolean('isPostDated');
  String get status            => text('status');
  String get clearedDate       => text('clearedDate');
}
