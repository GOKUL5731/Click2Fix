import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                connectTimeout: const Duration(seconds: 45),
                receiveTimeout: const Duration(seconds: 90),
                sendTimeout: const Duration(seconds: 90),
                headers: const {'Accept': 'application/json'},
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          final attempt =
              error.requestOptions.extra['retryCount'] as int? ?? 0;
          if (_shouldRetry(error) && attempt < _maxRetries) {
            error.requestOptions.extra['retryCount'] = attempt + 1;
            try {
              // Progressive back-off: 3s, 7s, 15s
              final delayMs = [3000, 7000, 15000][attempt];
              await Future.delayed(Duration(milliseconds: delayMs));
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

  final Dio _dio;
  String? _token;

  bool _shouldRetry(DioException error) {
    final code = error.response?.statusCode;
    if (code == 502 || code == 503 || code == 504) return true;
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
  String get baseUrl => _dio.options.baseUrl;

  Future<Response<dynamic>> post(String path, dynamic data) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Response<dynamic>> put(String path, dynamic data) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Response<dynamic>> patch(String path, dynamic data) async {
    try {
      return await _dio.patch(path, data: data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Response<dynamic>> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw _mapDioError(e);
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
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  ApiException _mapDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    if (statusCode != null) {
      if (data is Map<String, dynamic>) {
        final msg = data['message'] ?? data['error'] ?? data['detail'] ??
            'Request failed ($statusCode)';
        return ApiException(msg.toString(), statusCode: statusCode, raw: data);
      }
      if (data is String && data.trim().isNotEmpty) {
        return ApiException(data, statusCode: statusCode, raw: data);
      }
      return ApiException('Request failed ($statusCode)',
          statusCode: statusCode, raw: data);
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return ApiException(
            'Connection timed out. The server may be waking up — please retry in a few seconds.',
            raw: error);
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          final se = error.error as SocketException;
          final msg = se.message.toLowerCase();
          if (msg.contains('failed host lookup') ||
              msg.contains('nodename nor servname') ||
              msg.contains('name or service not known')) {
            return ApiException(
              'Cannot reach the server. Check your internet connection or try again in 30–60 seconds (server may be starting up).',
              raw: error,
            );
          }
          return ApiException(
              'No internet connection. Please check your network and retry.',
              raw: error);
        }
        if (error.error is TimeoutException) {
          return ApiException('Connection timed out. Please try again.',
              raw: error);
        }
        return ApiException(
            'Something went wrong contacting the server. Please retry.',
            raw: error);
      case DioExceptionType.cancel:
        return ApiException('Request cancelled.', raw: error);
      case DioExceptionType.badCertificate:
        return ApiException('SSL error. Please try again later.', raw: error);
      case DioExceptionType.badResponse:
        return ApiException('Unexpected server response.',
            statusCode: statusCode, raw: error);
    }
  }
}
