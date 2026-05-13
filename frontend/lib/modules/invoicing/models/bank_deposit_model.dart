import 'package:farm_mgt_auth/modules/settings/models/base_settings_model.dart';

class BankDepositModel extends BaseSettingsModel {
  BankDepositModel({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory BankDepositModel.fromMap(Map<String, dynamic> map) {
    final d = Map<String, dynamic>.from(map)..remove('id');
    return BankDepositModel(id: '${map['id'] ?? ''}', data: d);
  }

  String get depositId        => text('depositId');
  String get depositType      => text('depositType');
  String get depositDate      => text('depositDate');
  String get bankAccountId    => text('bankAccountId');
  String get bankAccountName  => text('bankAccountName');
  String get depositSlipNo    => text('depositSlipNo');
  double get amount           => number('amount');
  String get fromAccountId    => text('fromAccountId');
  String get fromAccountName  => text('fromAccountName');
  String get narration        => text('narration');
  bool   get isConfirmed      => boolean('isConfirmed');
  String get confirmedDate    => text('confirmedDate');
  bool   get isReconciled     => boolean('isReconciled');
  String get reconciledDate   => text('reconciledDate');
  String get bankStatementRef => text('bankStatementRef');
  String get chequeNo         => text('chequeNo');
  String get chequeDate       => text('chequeDate');
  String get drawerName       => text('drawerName');
  String get drawerBankName   => text('drawerBankName');
}
