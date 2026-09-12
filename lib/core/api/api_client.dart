import 'dart:async';

import 'package:dio/dio.dart';

import '../config/app_environment.dart';
import '../storage/token_storage.dart';

class ApiClient {
  ApiClient._legacy() : this(const TokenStorage());
  static final instance = ApiClient._legacy();

  ApiClient(this._tokens, {FutureOr<void> Function()? onUnauthorized})
    : _onUnauthorized = onUnauthorized,
      dio = Dio(
        BaseOptions(
          baseUrl: AppEnvironment.apiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          headers: const {
            'Accept': 'application/json',
            if (AppEnvironment.apiHost != '') 'Host': AppEnvironment.apiHost,
          },
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokens.read();
          if (token?.isNotEmpty == true) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _tokens.clear();
            await _onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }
  final TokenStorage _tokens;
  final FutureOr<void> Function()? _onUnauthorized;
  final Dio dio;
  Dio get client => dio;
}
