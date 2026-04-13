import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../models/chat_message.dart';
import '../services/api_client.dart';
import '../services/chat_service.dart';
import '../services/socket_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

  final _msgController = TextEditingController();
  bool _isLoading = true;
  final _messages = <ChatMessage>[];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    SocketService().joinBooking('hardcoded_booking_id_for_now');
    SocketService().onMessage((data) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage.fromJson(data));
      });
    });
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await ChatService(ApiClient()).getMessages('hardcoded_booking_id_for_now');
      if (mounted) setState(() {
        _messages.addAll(msgs);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    
    _msgController.clear();
    
    // Optimistic UI
    final tempMsg = ChatMessage(
      id: DateTime.now().toString(),
      bookingId: 'hardcoded_booking_id_for_now',
      senderId: 'me',
      senderRole: 'user',
      message: text,
      createdAt: DateTime.now(),
    );
    setState(() {
      _messages.add(tempMsg);
    });

    try {
      await ChatService(ApiClient()).sendMessage('hardcoded_booking_id_for_now', text);
      SocketService().sendMessage('hardcoded_booking_id_for_now', text);
    } catch (e) {
      // Revert if failed
      setState(() {
        _messages.remove(tempMsg);
      });
    }
  }

  @override
  void dispose() { _msgController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.go('/tracking')),
        title: Row(children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Text('R', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Ravi Kumar', style: Theme.of(context).textTheme.titleSmall),
            Text('Online', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.successGreen)),
          ]),
        ]),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.call, size: 20))],
      ),
      body: Column(children: [
        Expanded(
          child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  reverse: false, padding: const EdgeInsets.all(16), itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isMe = msg.senderRole == 'user'; // Assume this is user app
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.primaryBlue : (isDark ? AppColors.cardDark : AppColors.backgroundLight),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4), bottomRight: Radius.circular(isMe ? 4 : 16),
                          ),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(msg.message, style: TextStyle(color: isMe ? Colors.white : null, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('${msg.createdAt.hour}:${msg.createdAt.minute}', style: TextStyle(fontSize: 10, color: isMe ? Colors.white60 : AppColors.textHint)),
                        ]),
                      ),
                    );
                  },
                ),
        ),
        // Input
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
          decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : Colors.white, border: Border(top: BorderSide(color: AppColors.divider.withAlpha(80)))),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _msgController,
              decoration: InputDecoration(hintText: 'Type a message...', filled: true, fillColor: isDark ? AppColors.cardDark : AppColors.backgroundLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              onSubmitted: (_) => _sendMessage(),
            )),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(24)),
              child: IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20)),
            ),
          ]),
        ),
      ]),
    );
  }
}
