import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgController = TextEditingController();
  final _messages = <({String text, bool isMe, String time})>[
    (text: 'Hi, I\'m on my way to your location.', isMe: false, time: '2:30 PM'),
    (text: 'Great! Please come to the main entrance.', isMe: true, time: '2:31 PM'),
    (text: 'Sure, I\'ll be there in about 15 minutes.', isMe: false, time: '2:31 PM'),
    (text: 'Can you bring extra washers? The pipe is old.', isMe: true, time: '2:33 PM'),
    (text: 'Yes, I have all supplies needed. No worries! 👍', isMe: false, time: '2:34 PM'),
  ];

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add((text: text, isMe: true, time: '${TimeOfDay.now().format(context)}'));
      _msgController.clear();
    });
    // Auto reply
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _messages.add((text: 'Got it! 👍', isMe: false, time: TimeOfDay.now().format(context))));
    });
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
          child: ListView.builder(
            reverse: false, padding: const EdgeInsets.all(16), itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return Align(
                alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                  decoration: BoxDecoration(
                    color: msg.isMe ? AppColors.primaryBlue : (isDark ? AppColors.cardDark : AppColors.backgroundLight),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(msg.isMe ? 16 : 4), bottomRight: Radius.circular(msg.isMe ? 4 : 16),
                    ),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(msg.text, style: TextStyle(color: msg.isMe ? Colors.white : null, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(msg.time, style: TextStyle(fontSize: 10, color: msg.isMe ? Colors.white60 : AppColors.textHint)),
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
