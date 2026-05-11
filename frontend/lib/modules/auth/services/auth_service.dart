import 'package:farm_mgt_auth/services/api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    return _api.post('/auth/login', {'email': email, 'password': password});
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    return _api.post('/auth/register', payload);
  }

  Future<Map<String, dynamic>> me(String token) async {
    return _api.get('/auth/me', auth: true);
  }

  Future<Map<String, dynamic>> forgot(String email) async {
    return _api.post('/auth/forgot', {'email': email});
  }

  Future<Map<String, dynamic>> reset(String token, String newPassword) async {
    return _api
        .post('/auth/reset', {'token': token, 'newPassword': newPassword});
  }

  Future<Map<String, dynamic>> changePassword(
      String token, String oldPassword, String newPassword) async {
    return _api.post(
      '/auth/change',
      {'oldPassword': oldPassword, 'newPassword': newPassword},
      auth: true,
    );
  }

  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    return _api.post('/auth/refresh', {'refreshToken': refreshToken});
  }

  Future<Map<String, dynamic>> logout() async {
    return _api.post('/auth/logout', {}, auth: true);
  }
}
