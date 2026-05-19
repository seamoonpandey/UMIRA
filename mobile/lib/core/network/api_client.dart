import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';
import 'api_exception.dart';

const _baseUrl = String.fromEnvironment(
  'UMIRA_API_URL',
  defaultValue: 'http://10.0.2.2:4000/v1',
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(storage);
});

class ApiClient {
  final SecureStorage _storage;
  late final Dio dio;

  ApiClient(this._storage) {
    dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'content-type': 'application/json'},
    ),);

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.readToken();
        if (token != null) options.headers['authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (e, handler) {
        if (kDebugMode) debugPrint('[UMIRA API ERR] ${e.message}');
        handler.next(e);
      },
    ),);
  }

  Future<Map<String, dynamic>> getJson(String path,
      {Map<String, dynamic>? query,}) async {
    try {
      final r =
          await dio.get<Map<String, dynamic>>(path, queryParameters: query);
      return r.data ?? {};
    } on DioException catch (e) {
      throw _toApi(e);
    }
  }

  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    try {
      final r = await dio.post<Map<String, dynamic>>(path, data: body);
      return r.data ?? {};
    } on DioException catch (e) {
      throw _toApi(e);
    }
  }

  Future<Map<String, dynamic>> patchJson(String path, {Object? body}) async {
    try {
      final r = await dio.patch<Map<String, dynamic>>(path, data: body);
      return r.data ?? {};
    } on DioException catch (e) {
      throw _toApi(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await dio.delete(path);
    } on DioException catch (e) {
      throw _toApi(e);
    }
  }

  ApiException _toApi(DioException e) {
    final code = e.response?.statusCode ?? 0;
    final data = e.response?.data;
    final msg = (data is Map && data['error'] is String)
        ? data['error'] as String
        : e.message ?? 'network_error';
    return ApiException(code, msg);
  }
}
