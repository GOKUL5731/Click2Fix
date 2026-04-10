import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/admin_service.dart';
import '../services/api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final adminServiceProvider = Provider<AdminService>((ref) => AdminService(ref.watch(apiClientProvider)));
final adminTokenProvider = StateProvider<String?>((ref) => null);

