class ChatMessage {
  final String id;
  final String bookingId;
  final String senderId;
  final String senderRole;
  final String message;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.senderRole,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      bookingId: json['booking_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      senderRole: json['sender_role'] ?? '',
      message: json['message'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']).toLocal() 
          : DateTime.now(),
    );
  }
}
