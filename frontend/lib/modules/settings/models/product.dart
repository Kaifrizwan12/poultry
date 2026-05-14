import 'base_settings_model.dart';

class Product extends BaseSettingsModel {
  Product({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory Product.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return Product(id: '${map['id'] ?? ''}', data: data);
  }

  // ── Identity ──────────────────────────────────────────────────────────────────
  String get name        => text('name');
  String get code        => text('code');
  String get description => text('description');
  String get groupId     => text('groupId');
  String get subGroupId  => text('subGroupId');
  String get unitId      => text('unitId');
  String get longName    => text('longName');
  String get companyId   => text('companyId');
  String get purPackingId  => text('purPackingId');
  String get salePackingId => text('salePackingId');
  double get size => number('size');
  double get displayOrder => number('displayOrder');
  double get purchasePrice => number('purchasePrice');
  double get purchaseDiscPercent => number('purchaseDiscPercent');
  double get sale1Price => number('sale1Price');
  double get sale1DiscPercent => number('sale1DiscPercent');
  double get sale2Price => number('sale2Price');
  double get sale2DiscPercent => number('sale2DiscPercent');
  double get sale3Price => number('sale3Price');
  double get sale3DiscPercent => number('sale3DiscPercent');
  double get retailPrice => number('retailPrice');
  // Backward-compat: read salesTaxPercent, fall back to old taxPercent field
  double get salesTaxPercent {
    final v = number('salesTaxPercent');
    return v != 0 ? v : number('taxPercent');
  }
  double get sedValue => number('sedValue');
  bool get isPoultryItem => boolean('isPoultryItem');
  bool get inactiveInAdditions => boolean('inactiveInAdditions');
  bool get inactiveOnBonusForSales => boolean('inactiveOnBonusForSales');
  bool get isActive => boolean('isActive');
}
