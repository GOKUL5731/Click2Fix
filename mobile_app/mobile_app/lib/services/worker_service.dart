import 'package:dio/dio.dart';
import 'api_client.dart';

class WorkerService {
  WorkerService(this._client);

  final ApiClient _client;

  /// Get worker profile
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _client.get('/worker/profile');
    return response.data as Map<String, dynamic>;
  }

  /// Toggle availability
  Future<Map<String, dynamic>> setAvailability(bool isAvailable) async {
    final response = await _client.put('/worker/availability', {
      'availability': isAvailable,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Update real-time location
  Future<Map<String, dynamic>> updateLocation(double latitude, double longitude) async {
    final response = await _client.put('/worker/location', {
      'latitude': latitude,
      'longitude': longitude,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Send a quote for an issue
  Future<Map<String, dynamic>> sendQuote(String issueId, double price, int etaMinutes, String? message) async {
    final response = await _client.post('/worker/quote', {
      'issueId': issueId,
      'price': price,
      'estimatedTime': etaMinutes,
      if (message != null && message.isNotEmpty) 'message': message,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Upload a document (Aadhaar or certificate)
  Future<Map<String, dynamic>> uploadDocument(String documentType, String filePath) async {
    final response = await _client.uploadFiles(
      '/worker/document',
      fields: {'documentType': documentType},
      files: [
        MapEntry(
          'file',
          await MultipartFile.fromFile(filePath, filename: 'document_$documentType.jpg'),
        ),
      ],
    );
    return response.data as Map<String, dynamic>;
  }

  /// Fetch dashboard data (nearby issues assigned to category)
  Future<List<dynamic>> getNearbyRequests(double latitude, double longitude, String category) async {
    final response = await _client.get('/worker/nearby', queryParameters: {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'category': category,
    });
    return response.data as List<dynamic>;
  }
}
