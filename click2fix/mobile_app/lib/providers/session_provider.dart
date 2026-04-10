import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/push_notification_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) => PushNotificationService());
final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(
      ref.watch(apiClientProvider), ref.watch(pushNotificationServiceProvider)),
);

final sessionTokenProvider = StateProvider<String?>((ref) => null);
