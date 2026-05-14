import 'base_settings_model.dart';

class Customer extends BaseSettingsModel {
  Customer({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory Customer.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return Customer(id: '${map['id'] ?? ''}', data: data);
  }

  String get name             => text('name');
  String get code             => text('code');
  String get phone            => text('phone');
  String get altPhone         => text('altPhone');
  String get email            => text('email');
  String get address          => text('address');
  String get townId           => text('townId');
  String get sectorId         => text('sectorId');
  String get salesmanId       => text('salesmanId');
  String get companyId        => text('companyId');
  double get creditLimit      => number('creditLimit');
  double get openingBalance   => number('openingBalance');
  String get balanceType      => text('balanceType');
  String get discountSchemeId => text('discountSchemeId');
  bool   get isActive         => boolean('isActive');
  String get notes            => text('notes');
}
