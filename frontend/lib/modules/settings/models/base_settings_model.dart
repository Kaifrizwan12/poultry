class BaseSettingsModel {
  BaseSettingsModel({
    required this.id,
    required Map<String, dynamic> data,
  }) : data = Map<String, dynamic>.from(data);

  final String id;
  final Map<String, dynamic> data;

  String text(String key) => (data[key] ?? '').toString();

  double number(String key) {
    final value = data[key];
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('$value') ?? 0;
  }

  bool boolean(String key) => data[key] == true;

  List<String> stringList(String key) {
    final value = data[key];
    if (value is List) {
      return value.map((item) => '$item').toList();
    }
    return const [];
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
