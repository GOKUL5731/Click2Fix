import 'api_client.dart';

class WorkerService {
  WorkerService(this._client);

  final ApiClient _client;

  Future<void> setAvailability(bool availability) {
    return _client.post('/worker/set-availability', {'availability': availability}).then((_) {});
  }

  Future<void> sendQuote({
    required String issueId,
    required int price,
    required int estimatedTime,
    required String message,
  }) {
    return _client.post('/worker/send-quote', {
      'issueId': issueId,
      'price': price,
      'estimatedTime': estimatedTime,
      'message': message,
    }).then((_) {});
  }
}

