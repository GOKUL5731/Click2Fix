import 'package:dio/dio.dart';
import '../models/chat_message.dart';
import 'api_client.dart';

class ChatService {
  final ApiClient _apiClient;

  ChatService(this._apiClient);

  Future<List<ChatMessage>> getMessages(String bookingId) async {
    try {
      final res = await _apiClient.get('/chat/$bookingId');
      if (res.data['success'] == true && res.data['messages'] != null) {
        return (res.data['messages'] as List)
            .map((e) => ChatMessage.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load chat history: $e');
    }
  }

  Future<ChatMessage> sendMessage(String bookingId, String message) async {
    try {
      final res = await _apiClient.post('/chat/send', {
        'bookingId': bookingId,
        'message': message,
      });
      if (res.data['success'] == true && res.data['message'] != null) {
        return ChatMessage.fromJson(res.data['message']);
      }
      throw Exception('Server returned false');
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }
}
