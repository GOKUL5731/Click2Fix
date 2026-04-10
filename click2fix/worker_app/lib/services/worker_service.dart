import 'api_client.dart';
import 'push_notification_service.dart';

class WorkerService {
  WorkerService(this._client, this._pushNotificationService);

  final ApiClient _client;
  final PushNotificationService _pushNotificationService;

  Future<void> setAvailability(bool availability) {
    return _client.post('/worker/set-availability',
        {'availability': availability}).then((_) {});
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

  Future<void> registerPushToken(String authToken) {
    return _pushNotificationService.registerDeviceToken(
      apiClient: _client,
      authToken: authToken,
      appVariant: 'worker',
    );
  }
}
