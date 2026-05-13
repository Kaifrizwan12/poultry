import 'package:farm_mgt_auth/modules/settings/models/base_settings_model.dart';

class StockIssueModel extends BaseSettingsModel {
  StockIssueModel({required String id, required Map<String, dynamic> data})
      : super(id: id, data: data);

  factory StockIssueModel.fromMap(Map<String, dynamic> map) {
    final d = Map<String, dynamic>.from(map)..remove('id');
    return StockIssueModel(id: '${map['id'] ?? ''}', data: d);
  }

  String get issueId          => text('issueId');
  String get issueType        => text('issueType');
  String get date             => text('date');
  String get salesmanId       => text('salesmanId');
  String get salesmanName     => text('salesmanName');
  String get originalIssueId  => text('originalIssueId');
  bool   get returnAll        => boolean('returnAll');
  double get netValue         => number('netValue');

  List<Map<String, dynamic>> get items {
    final raw = data['items'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }
}
