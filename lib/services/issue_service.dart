import 'package:dio/dio.dart';
import 'api_client.dart';

class IssueService {
  IssueService(this._client);

  final ApiClient _client;

  /// Create an issue with optional file uploads
  Future<Map<String, dynamic>> createIssue({
    String? description,
    double? latitude,
    double? longitude,
    bool isEmergency = false,
    String? imagePath,
    String? voicePath,
    String? uploadToken,
  }) async {
    final fields = <String, dynamic>{
      if (description != null) 'description': description,
      'latitude': latitude ?? 13.0827,
      'longitude': longitude ?? 80.2707,
      'isEmergency': isEmergency.toString(),
      if (uploadToken != null) 'uploadToken': uploadToken,
    };

    final files = <MapEntry<String, MultipartFile>>[];

    if (imagePath != null) {
      files.add(MapEntry(
        'files',
        await MultipartFile.fromFile(imagePath, filename: 'issue_image.jpg'),
      ));
    }

    if (voicePath != null) {
      files.add(MapEntry(
        'files',
        await MultipartFile.fromFile(voicePath, filename: 'voice_note.webm'),
      ));
    }

    final response = await _client.uploadFiles(
      '/api/issues',
      fields: fields,
      files: files.isNotEmpty ? files : null,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get issue details
  Future<Map<String, dynamic>> getIssue(String issueId) async {
    final response = await _client.get('/api/issues/$issueId');
    return response.data as Map<String, dynamic>;
  }

  /// Get current user's issues
  Future<List<dynamic>> getMyIssues() async {
    final response = await _client.get('/api/issues/my');
    return response.data as List<dynamic>;
  }

  /// Analyze an image file by uploading it directly to the backend.
  /// Returns AI-detected category and description.
  Future<Map<String, dynamic>> analyzeImageFile(String imagePath) async {
    final file = await MultipartFile.fromFile(
      imagePath,
      filename: 'issue_image.jpg',
    );
    final formData = FormData.fromMap({'file': file});

    try {
      final dio = Dio(BaseOptions(
        baseUrl: _client.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      ));
      // Copy auth token if present
      final token = _client.token;
      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }
      final response = await dio.post('/api/ai/analyze-image-file', data: formData);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      // Graceful fallback â€” AI unavailable, return placeholder
      return {
        'category': 'unknown',
        'description':
            'AI analysis unavailable. Please describe the problem manually.',
        'confidence': 0.0,
        'details': ['Could not connect to AI service'],
      };
    }
  }

  /// Get AI analysis for an image URL
  Future<Map<String, dynamic>> analyzeImage(String imageUrl) async {
    final response = await _client.post('/api/ai/detect-issue', {
      'imageUrl': imageUrl,
    });
    return response.data as Map<String, dynamic>;
  }
}

