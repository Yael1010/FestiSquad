import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../security/token_storage.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseUrl: _apiBaseUrl,
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

String get _apiBaseUrl {
  if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000/api/v1';
  }
  return 'http://127.0.0.1:8000/api/v1';
}

class ApiClient {
  ApiClient({
    required String baseUrl,
    required TokenStorage tokenStorage,
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
            headers: const {'Accept': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final request = error.requestOptions;
          final shouldRefresh = error.response?.statusCode == 401 &&
              request.extra['session_retry'] != true &&
              request.path != '/auth/refresh';
          if (!shouldRefresh) {
            handler.next(error);
            return;
          }

          final stored = await tokenStorage.readSession();
          if (stored == null) {
            handler.next(error);
            return;
          }

          try {
            final refreshClient = Dio(BaseOptions(baseUrl: baseUrl));
            final response = await refreshClient.post<dynamic>(
              '/auth/refresh',
              data: {'refresh_token': stored.refreshToken},
            );
            final data = Map<String, dynamic>.from(response.data as Map);
            final refreshed = StoredSession(
              userId: data['user_id'] as String,
              accessToken: data['access_token'] as String,
              refreshToken: data['refresh_token'] as String,
            );
            await tokenStorage.writeSession(refreshed);
            request.headers['Authorization'] =
                'Bearer ${refreshed.accessToken}';
            request.extra['session_retry'] = true;
            handler.resolve(await _dio.fetch<dynamic>(request));
          } catch (_) {
            await tokenStorage.clear();
            handler.next(error);
          }
        },
      ),
    );
  }

  final Dio _dio;

  Future<Response<dynamic>> get(String path) => _dio.get(path);

  Future<Response<dynamic>> post(String path, {Object? data}) =>
      _dio.post(path, data: data);
}

String apiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return data['detail'] as String;
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'No se pudo conectar con FestiSquad. Revisa la red y el backend.';
    }
  }
  return 'Ocurrió un error inesperado. Intenta nuevamente.';
}
