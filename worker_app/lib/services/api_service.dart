import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

class ApiService {
  ApiService._();

  static final Dio client = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json,
      headers: const {
        'Accept': 'application/json',
      },
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          debugPrint('API error: ${error.requestOptions.method} '
              '${error.requestOptions.uri} -> ${error.message}');
          handler.next(error);
        },
      ),
    );

  static String extractMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'] ?? data['error'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Request timed out. Please try again.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Unable to reach the server. Please check your connection.';
      }
      if (error.response?.statusCode == 404) {
        return 'Service endpoint not found.';
      }
      if (error.response?.statusCode == 401) {
        return 'Session expired or unauthorized request.';
      }
      return error.message ?? 'Something went wrong.';
    }
    return error.toString();
  }
}