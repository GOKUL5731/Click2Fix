import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import '../services/push_notification_service.dart';
import '../services/worker_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) => PushNotificationService());
final workerServiceProvider = Provider<WorkerService>(
  (ref) => WorkerService(
      ref.watch(apiClientProvider), ref.watch(pushNotificationServiceProvider)),
);
final availabilityProvider = StateProvider<bool>((ref) => false);
