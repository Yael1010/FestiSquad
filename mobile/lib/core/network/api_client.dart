import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: 'http://127.0.0.1:8000/api/v1');
});

class ApiClient {
  ApiClient({required String baseUrl})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        );

  final Dio _dio;

  Future<Response<dynamic>> get(String path) => _dio.get(path);

  Future<Response<dynamic>> post(String path, {Object? data}) => _dio.post(path, data: data);
}

