import 'api_client.dart';

class AdminService {
  AdminService(this._client);

  final ApiClient _client;

  Future<dynamic> dashboard() => _client.get('/admin/dashboard');

  Future<dynamic> pendingWorkers() => _client.get('/admin/workers/pending');

  Future<dynamic> approveWorker(String workerId, bool approved) {
    return _client.post('/admin/approve-worker', {'workerId': workerId, 'approved': approved});
  }
}

