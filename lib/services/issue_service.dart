import 'dart:typed_data';

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
    Uint8List? imageBytes,
    String imageFilename = 'issue_image.jpg',
    String? voicePath,
    Uint8List? voiceBytes,
    String voiceFilename = 'voice_note.webm',
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

    if (imageBytes != null) {
      files.add(MapEntry(
        'files',
        MultipartFile.fromBytes(imageBytes, filename: imageFilename),
      ));
    } else if (imagePath != null) {
      files.add(MapEntry(
        'files',
        await MultipartFile.fromFile(imagePath, filename: imageFilename),
      ));
    }

    if (voiceBytes != null) {
      files.add(MapEntry(
        'files',
        MultipartFile.fromBytes(voiceBytes, filename: voiceFilename),
      ));
    } else if (voicePath != null) {
      files.add(MapEntry(
        'files',
        await MultipartFile.fromFile(voicePath, filename: voiceFilename),
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

  /// Analyze an image file by uploading it directly to the backend.
  /// Returns AI-detected category and description.
  Future<Map<String, dynamic>> analyzeImageFile({
    String? imagePath,
    Uint8List? imageBytes,
    String filename = 'issue_image.jpg',
  }) async {
    if (imageBytes == null && (imagePath == null || imagePath.isEmpty)) {
      throw ArgumentError('Provide imageBytes or imagePath');
    }
    final MultipartFile file = imageBytes != null
        ? MultipartFile.fromBytes(imageBytes, filename: filename)
        : await MultipartFile.fromFile(imagePath!, filename: filename);
    final formData = FormData.fromMap({'file': file});

    final response =
        await _client.postMultipart('/ai/analyze-image-file', formData);
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((k, v) => MapEntry(k.toString(), v));
    }
    return {
      'category': 'unknown',
      'description': 'Could not parse AI response.',
      'confidence': 0.0,
    };
  }

  /// Get AI analysis for an image URL
  Future<Map<String, dynamic>> analyzeImage(String imageUrl) async {
    final response = await _client.post('/ai/detect-issue', {
      'imageUrl': imageUrl,
    });
    return response.data as Map<String, dynamic>;
  }
}

