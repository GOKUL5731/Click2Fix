import 'dart:io';
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
      '/issues',
      fields: fields,
      files: files.isNotEmpty ? files : null,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get issue details
  Future<Map<String, dynamic>> getIssue(String issueId) async {
    final response = await _client.get('/issues/$issueId');
    return response.data as Map<String, dynamic>;
  }

  /// Get current user's issues
  Future<List<dynamic>> getMyIssues() async {
    final response = await _client.get('/issues/my');
    return response.data as List<dynamic>;
  }

  /// Get AI analysis for an image URL
  Future<Map<String, dynamic>> analyzeImage(String imageUrl) async {
    final response = await _client.post('/ai/detect-issue', {
      'imageUrl': imageUrl,
    });
    return response.data as Map<String, dynamic>;
  }
}
