import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import '../services/worker_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final workerServiceProvider = Provider<WorkerService>((ref) => WorkerService(ref.watch(apiClientProvider)));
final availabilityProvider = StateProvider<bool>((ref) => false);

