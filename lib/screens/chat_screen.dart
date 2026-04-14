import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../services/api_client.dart';
import '../providers/session_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.bookingId});
  
  final String bookingId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgController = TextEditingController();
  final List<dynamic> _messages = [];
  bool _isLoading = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // Poll for new messages every 5 seconds since Socket.IO is not yet implemented
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages(silent: true));
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (widget.bookingId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get('/chat/${widget.bookingId}');
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(response.data['messages'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!silent && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || widget.bookingId.isEmpty) return;
    
    _msgController.clear();
    
    try {
      final client = ref.read(apiClientProvider);
      await client.post('/chat/send', {
        'bookingId': widget.bookingId,
        'message': text,
        'type': 'text'
      });
      _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
      }
    }
  }

  @override
  void dispose() { 
    _pollingTimer?.cancel();
    _msgController.dispose(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bookingId.isEmpty) {
      return const Scaffold(body: Center(child: Text("Invalid Booking ID")));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = ref.watch(sessionProvider);
    final myId = session.user?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
        title: Row(children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Icon(Icons.person, color: Colors.white, size: 20))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Booking Chat', style: Theme.of(context).textTheme.titleSmall),
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
                reverse: false, 
                padding: const EdgeInsets.all(16), 
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMe = msg['sender_id'] == myId;
                  
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
                        Text(msg['message'] ?? '', style: TextStyle(color: isMe ? Colors.white : null, fontSize: 14)),
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
