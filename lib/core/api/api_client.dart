import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_config.dart';

import 'global_message_provider.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref));

class ApiClient {
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  final Ref _ref;

  ApiClient(this._ref) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiConfig.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConfig.receiveTimeout),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: ApiConfig.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          print('🌐 API Request: ${options.method} ${options.baseUrl}${options.path} [TOKEN FOUND]');
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        String errorMessage = 'Une erreur est survenue';
        
        if (e.type == DioExceptionType.connectionTimeout || 
            e.type == DioExceptionType.receiveTimeout || 
            e.type == DioExceptionType.sendTimeout) {
          errorMessage = 'Délai d\'attente dépassé. Vérifiez votre connexion ou le serveur.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = 'Impossible de contacter le serveur. Vérifiez votre connexion.';
        } else if (e.response?.statusCode == 401) {
          errorMessage = 'Session expirée. Veuillez vous reconnecter.';
        } else if (e.response?.statusCode != null) {
          errorMessage = 'Erreur serveur (${e.response?.statusCode})';
        }

        // Notify the UI through the provider
        _ref.read(globalMessageProvider.notifier).state = GlobalMessage(message: errorMessage);

        print('❌ API Error [${e.response?.statusCode}]: ${e.message}');
        print('🔗 Failed URL: ${e.requestOptions.baseUrl}${e.requestOptions.path}');
        return handler.next(e);
      },
    ));
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? params}) =>
      _dio.get<T>(path, queryParameters: params);

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> put<T>(String path, {dynamic data}) =>
      _dio.put<T>(path, data: data);

  Future<Response<T>> patch<T>(String path, {dynamic data}) =>
      _dio.patch<T>(path, data: data);

  Future<Response<T>> delete<T>(String path) => _dio.delete<T>(path);
}
