import 'dart:io';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_error_parser.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/app_user.dart';

abstract interface class AuthDataSource {
  Future<AppUser> login(String username, String password);
  Future<AppUser?> restore();
  Future<void> logout();
}

class AuthRepository implements AuthDataSource {
  const AuthRepository(this._api, this._tokens);
  final ApiClient _api;
  final TokenStorage _tokens;

  @override
  Future<AppUser> login(String username, String password) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
          'device_name': '${Platform.operatingSystem}-mix-n-sip-pos',
        },
      );
      final data = response.data!['data'] as Map<String, dynamic>;
      await _tokens.write(data['token'].toString());
      return AppUser.fromJson(data['user'] as Map<String, dynamic>);
    } catch (error) {
      throw ApiErrorParser.parse(error);
    }
  }

  @override
  Future<AppUser?> restore() async {
    if (await _tokens.read() == null) return null;
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('/auth/me');
      return AppUser.fromJson(
        (response.data!['data'] as Map<String, dynamic>)['user']
            as Map<String, dynamic>,
      );
    } catch (_) {
      await _tokens.clear();
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _api.dio.post<void>('/auth/logout');
    } finally {
      await _tokens.clear();
    }
  }
}
