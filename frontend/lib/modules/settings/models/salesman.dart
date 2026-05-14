import 'base_settings_model.dart';

class Salesman extends BaseSettingsModel {
  Salesman({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory Salesman.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map)..remove('id');
    return Salesman(id: '${map['id'] ?? ''}', data: data);
  }

  String get name             => text('name');
  String get code             => text('code');
  String get phone            => text('phone');
  String get email            => text('email');
  String get address          => text('address');
  String get joiningDate      => text('joiningDate');
  double get baseSalary       => number('baseSalary');
  String get commissionType   => text('commissionType');
  double get commissionValue  => number('commissionValue');
  List<String> get assignedTowns => stringList('assignedTowns');
  bool   get isActive         => boolean('isActive');
  String get notes            => text('notes');
}
