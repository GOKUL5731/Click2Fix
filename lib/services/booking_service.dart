import 'api_client.dart';

class BookingService {
  BookingService(this._client);

  final ApiClient _client;

  /// Create a booking
  Future<Map<String, dynamic>> createBooking({
    required String issueId,
    required String workerId,
    String? quotationId,
  }) async {
    final response = await _client.post('/booking/create', {
      'issueId': issueId,
      'workerId': workerId,
      if (quotationId != null) 'quotationId': quotationId,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Get booking history
  Future<List<dynamic>> getHistory() async {
    final response = await _client.get('/booking/history');
    return response.data as List<dynamic>;
  }

  /// Get live worker location for a booking
  Future<Map<String, dynamic>?> getLiveLocation(String bookingId) async {
    final response = await _client.get(
      '/booking/live-location',
      queryParameters: {'bookingId': bookingId},
    );
    return response.data as Map<String, dynamic>?;
  }

  /// Complete a booking (worker calls this)
  Future<Map<String, dynamic>> completeBooking(String bookingId, {String? otp}) async {
    final response = await _client.post('/booking/complete', {
      'bookingId': bookingId,
      if (otp != null) 'completionOtp': otp,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Submit a rating for a completed booking
  Future<Map<String, dynamic>> submitRating({
    required String bookingId,
    required String workerId,
    required int rating,
    String? comment,
  }) async {
    final response = await _client.post('/review/add', {
      'bookingId': bookingId,
      'workerId': workerId,
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Get nearby workers for an issue
  Future<List<dynamic>> getNearbyWorkers({
    String? issueId,
    double? latitude,
    double? longitude,
    String? category,
  }) async {
    final response = await _client.get('/worker/nearby', queryParameters: {
      if (issueId != null) 'issueId': issueId,
      if (latitude != null) 'latitude': latitude.toString(),
      if (longitude != null) 'longitude': longitude.toString(),
      if (category != null) 'category': category,
    });
    return response.data as List<dynamic>;
  }

  /// Get quotations for an issue
  Future<List<dynamic>> getQuotations(String issueId) async {
    final response = await _client.get('/worker/quotations/$issueId');
    return response.data as List<dynamic>;
  }
}

