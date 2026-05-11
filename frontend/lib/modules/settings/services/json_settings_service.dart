import 'package:farm_mgt_auth/core/app_exception.dart';
import 'package:farm_mgt_auth/modules/settings/services/settings_service_base.dart';
import 'package:farm_mgt_auth/services/api_service.dart';

class JsonSettingsService<T> extends SettingsServiceBase<T> {
  JsonSettingsService({
    required String entity,
    required T Function(Map<String, dynamic>) parser,
  })  : _parser = parser,
        _apiService = ApiService(),
        super(entity);

  final ApiService _apiService;
  final T Function(Map<String, dynamic>) _parser;

  String get _path => '/settings/$entity';

  @override
  Future<List<T>> fetchAll() async {
    final response = await _apiService.get(_path, auth: true);
    final data = _unwrapList(response);
    return data.map(_parser).toList();
  }

  @override
  Future<T> create(Map<String, dynamic> body) async {
    final response = await _apiService.post(_path, body, auth: true);
    return _parser(_unwrapItem(response));
  }

  @override
  Future<T> update(String id, Map<String, dynamic> body) async {
    final response = await _apiService.put('$_path/$id', body, auth: true);
    return _parser(_unwrapItem(response));
  }

  @override
  Future<void> delete(String id) async {
    final response = await _apiService.delete('$_path/$id', auth: true);
    if (response['success'] != true) {
      throw AppException(_mapError(response, 'Unable to delete record'));
    }
  }

  List<Map<String, dynamic>> _unwrapList(Map<String, dynamic> response) {
    if (response['success'] != true) {
      throw AppException(_mapError(response, 'Unable to fetch records'));
    }
    final raw = response['data'];
    if (raw is! List) {
      return const [];
    }
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, dynamic> _unwrapItem(Map<String, dynamic> response) {
    if (response['success'] != true) {
      throw AppException(_mapError(response, 'Request failed'));
    }
    final raw = response['data'];
    if (raw is! Map) {
      throw AppException('Malformed response');
    }
    return Map<String, dynamic>.from(raw);
  }

  String _mapError(Map<String, dynamic> response, String fallback) {
    final raw = '${response['error'] ?? fallback}'.trim();
    if (raw == 'not found') {
      return 'Settings API route was not found. Restart the backend server and try again.';
    }
    return raw;
  }
}
