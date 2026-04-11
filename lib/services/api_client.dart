import 'package:dio/dio.dart';
import '../config/app_config.dart';

class ApiClient {
  ApiClient({Dio? dio, String? baseUrl})
      : _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 60),
                sendTimeout: const Duration(seconds: 60),
              ),
            ) {
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) async {
        // Retry once on connection errors (handles Render cold-start delay)
        if (_shouldRetry(error) && error.requestOptions.extra['retryCount'] == null) {
          error.requestOptions.extra['retryCount'] = 1;
          try {
            // Wait 3s for Render to wake up before retrying
            await Future.delayed(const Duration(seconds: 3));
            final response = await _dio.fetch(error.requestOptions);
            return handler.resolve(response);
          } catch (e) {
            return handler.next(error);
          }
        }
        return handler.next(error);
      },
    ));
  }

  final Dio _dio;
  final String _baseUrl;
  String? _token;

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown;
  }

  void setToken(String? token) {
    _token = token;
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  String? get token => _token;
  String get baseUrl => _baseUrl;

  Future<Response<dynamic>> post(String path, dynamic data) {
    return _dio.post(path, data: data);
  }

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response<dynamic>> put(String path, dynamic data) {
    return _dio.put(path, data: data);
  }

  Future<Response<dynamic>> patch(String path, dynamic data) {
    return _dio.patch(path, data: data);
  }

  Future<Response<dynamic>> delete(String path) {
    return _dio.delete(path);
  }

  /// Upload files with multipart form data
  Future<Response<dynamic>> uploadFiles(
    String path, {
    required Map<String, dynamic> fields,
    List<MapEntry<String, MultipartFile>>? files,
  }) async {
    final formData = FormData.fromMap(fields);
    if (files != null) {
      for (final entry in files) {
        formData.files.add(entry);
      }
    }
    return _dio.post(path, data: formData);
  }
}
