import 'base_settings_model.dart';

class Account extends BaseSettingsModel {
  Account({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory Account.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return Account(id: '${map['id'] ?? ''}', data: data);
  }

  String get accountName     => text('accountName');
  String get accountCode     => text('accountCode');
  String get accountType     => text('accountType');
  String get parentAccountId => text('parentAccountId');
  double get openingBalance  => number('openingBalance');
  String get balanceType     => text('balanceType');
  bool   get isActive        => boolean('isActive');
  String get description     => text('description');
}
