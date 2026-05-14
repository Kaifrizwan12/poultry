import 'base_settings_model.dart';

class Vendor extends BaseSettingsModel {
  Vendor({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory Vendor.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return Vendor(id: '${map['id'] ?? ''}', data: data);
  }

  String get name           => text('name');
  String get companyId      => text('companyId');
  String get phone          => text('phone');
  String get email          => text('email');
  String get address        => text('address');
  String get town           => text('town');
  double get openingBalance => number('openingBalance');
  String get balanceType    => text('balanceType');
  String get notes          => text('notes');
}
