import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../config/app_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.raw});

  final String message;
  final int? statusCode;
  final Object? raw;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({Dio? dio, String? baseUrl})
      : _baseUrl = _trimBaseUrl(baseUrl ?? AppConfig.apiBaseUrl),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _trimBaseUrl(baseUrl ?? AppConfig.apiBaseUrl),
                connectTimeout: const Duration(seconds: 45),
                receiveTimeout: const Duration(seconds: 90),
                sendTimeout: const Duration(seconds: 90),
                headers: const {
                  'Accept': 'application/json',
                },
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          final attempt = error.requestOptions.extra['retryCount'] as int? ?? 0;
          if (_shouldRetry(error) && attempt < _maxRetries) {
            error.requestOptions.extra['retryCount'] = attempt + 1;
            try {
              final delayMs = 2500 * (attempt + 1) * (attempt + 1);
              await Future.delayed(Duration(milliseconds: delayMs.clamp(2500, 15000)));
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (_) {
              return handler.next(error);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  static const _maxRetries = 3;

  static String _trimBaseUrl(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  final Dio _dio;
  final String _baseUrl;
  String? _token;

  bool _shouldRetry(DioException error) {
    final code = error.response?.statusCode;
    if (code == 502 || code == 503 || code == 504) {
      return true;
    }
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown;
  }

  void setToken(String? token) {
    _token = token;
    if (token != null && token.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  String? get token => _token;
  String get baseUrl => _baseUrl;

  Future<Response<dynamic>> post(String path, dynamic data) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<Response<dynamic>> put(String path, dynamic data) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<Response<dynamic>> patch(String path, dynamic data) async {
    try {
      return await _dio.patch(path, data: data);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<Response<dynamic>> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<Response<dynamic>> uploadFiles(
    String path, {
    required Map<String, dynamic> fields,
    List<MapEntry<String, MultipartFile>>? files,
  }) async {
    try {
      final formData = FormData.fromMap(fields);
      if (files != null) {
        for (final entry in files) {
          formData.files.add(entry);
        }
      }
      return await _dio.post(
        path,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 120),
        ),
      );
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  /// Single multipart POST (e.g. AI image analyze). Lets Dio set the boundary.
  Future<Response<dynamic>> postMultipart(String path, FormData data) async {
    try {
      return await _dio.post(
        path,
        data: data,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 120),
        ),
      );
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  ApiException _mapDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    if (statusCode != null) {
      if (data is Map<String, dynamic>) {
        final message = data['message'] ??
            data['error'] ??
            data['detail'] ??
            'Request failed with status $statusCode';
        return ApiException(
          message.toString(),
          statusCode: statusCode,
          raw: data,
        );
      }

      if (data is String && data.trim().isNotEmpty) {
        return ApiException(
          data,
          statusCode: statusCode,
          raw: data,
        );
      }

      return ApiException(
        'Request failed with status $statusCode',
        statusCode: statusCode,
        raw: data,
      );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return ApiException(
          'Connection timed out. Please try again.',
          raw: error,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          'Unable to connect to the server. Please check your internet connection.',
          raw: error,
        );
      case DioExceptionType.cancel:
        return ApiException('Request was cancelled.', raw: error);
      case DioExceptionType.badCertificate:
        return ApiException(
          'Secure connection failed. Please try again later.',
          raw: error,
        );
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          final se = error.error as SocketException;
          final msg = se.message.toLowerCase();
          if (msg.contains('failed host lookup') ||
              msg.contains('nodename nor servname') ||
              msg.contains('name or service not known')) {
            return ApiException(
              'Could not reach the server (${_dio.options.baseUrl}). Check the API URL, your connection, or whether the backend is waking up (cold start can take ~30–60s on first request).',
              raw: error,
            );
          }
          return ApiException(
            'No internet connection. Please try again when you are online.',
            raw: error,
          );
        }
        if (error.error is TimeoutException) {
          return ApiException(
            'Connection timed out. Please try again.',
            raw: error,
          );
        }
        return ApiException(
          'Something went wrong while contacting the server.',
          raw: error,
        );
      case DioExceptionType.badResponse:
        return ApiException(
          'Server returned an unexpected response.',
          statusCode: statusCode,
          raw: error,
        );
    }
  }
}