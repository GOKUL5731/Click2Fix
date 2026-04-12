import 'api_client.dart';

class BookingService {
  BookingService(this._client);

  final ApiClient _client;

  /// Create a booking — backend: POST /booking/create
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

  /// Get booking history — backend: GET /booking/history
  Future<List<dynamic>> getHistory() async {
    final response = await _client.get('/booking/history');
    final data = response.data;
    if (data is List) return data;
    if (data is Map && data['bookings'] is List) return data['bookings'] as List;
    return [];
  }

  /// Get live worker location — backend: GET /booking/live-location?bookingId=...
  Future<Map<String, dynamic>?> getLiveLocation(String bookingId) async {
    final response = await _client.get(
      '/booking/live-location',
      queryParameters: {'bookingId': bookingId},
    );
    return response.data as Map<String, dynamic>?;
  }

  /// Complete a booking with OTP — backend: POST /booking/complete
  Future<Map<String, dynamic>> completeBooking(
    String bookingId, {
    String? otp,
  }) async {
    final response = await _client.post('/booking/complete', {
      'bookingId': bookingId,
      if (otp != null) 'completionOtp': otp,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Get nearby workers — backend: GET /worker/nearby
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
    final data = response.data;
    if (data is List) return data;
    if (data is Map && data['workers'] is List) return data['workers'] as List;
    return [];
  }

  /// Get quotations for an issue — backend: GET /worker/quotations/:issueId
  Future<List<dynamic>> getQuotations(String issueId) async {
    final response = await _client.get('/worker/quotations/$issueId');
    final data = response.data;
    if (data is List) return data;
    if (data is Map && data['quotations'] is List) return data['quotations'] as List;
    return [];
  }
}
