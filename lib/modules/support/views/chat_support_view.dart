import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';

class ChatSupportView extends StatefulWidget {
  const ChatSupportView({super.key});

  @override
  State<ChatSupportView> createState() => _ChatSupportViewState();
}

class _ChatSupportViewState extends State<ChatSupportView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'agent',
      'text': 'Hello! Welcome to All Stars Arena Support. How can we help you today?',
      'time': 'Just now',
    },
  ];

  final List<String> _suggestions = [
    'Issue with booking',
    'Refund status',
    'Wallet top-up issue',
    'Turf location inquiry',
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final userText = text.trim();
    _messageController.clear();

    setState(() {
      _messages.add({
        'sender': 'user',
        'text': userText,
        'time': 'Just now',
      });
    });

    _scrollToBottom();

    // Simulate Agent Automated Response after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'sender': 'agent',
          'text': _generateResponse(userText),
          'time': 'Just now',
        });
      });
      _scrollToBottom();
    });
  }

  String _generateResponse(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('booking') || lower.contains('slot')) {
      return 'For booking inquiries, you can check your booking status under "My Requests". If a slot was charged but not confirmed, it will auto-refund to your wallet within 10 minutes.';
    } else if (lower.contains('refund') || lower.contains('money') || lower.contains('wallet')) {
      return 'Wallet refunds are processed instantly for canceled slots. Bank refunds via Razorpay take 3-5 business days to reflect in your original payment source.';
    } else if (lower.contains('turf') || lower.contains('location') || lower.contains('court')) {
      return 'All Stars Arena turfs are equipped with FIFA-approved turf grass and high-intensity LED floodlights. Directions are available on the Court Details screen.';
    } else {
      return 'Thank you for contacting us! A support specialist has received your query and will assist you shortly.';
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userName = AuthService.to.currentUser.value?.name ?? 'User';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Arena Support Bot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                SizedBox(height: 2),
                Row(
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: Colors.green),
                    SizedBox(width: 4),
                    Text('Online • Ready to help', style: TextStyle(fontSize: 11, color: Colors.green)),
                  ],
                ),
              ],
            ),
          ],
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // SUGGESTION CHIPS
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              color: isDark ? const Color(0xFF130722) : const Color(0xFFF8FAFC),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _suggestions.map((suggestion) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(suggestion),
                        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                        onPressed: () => _sendMessage(suggestion),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // CHAT MESSAGES
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['sender'] == 'user';

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isUser
                            ? AppColors.primary
                            : (isDark ? const Color(0xFF1E1035) : Colors.grey.shade200),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isUser ? 16 : 2),
                          bottomRight: Radius.circular(isUser ? 2 : 16),
                        ),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUser ? userName : 'Arena Support',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isUser ? Colors.white70 : AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            msg['text']!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isUser
                                  ? Colors.white
                                  : (isDark ? AppColors.textPrimaryDark : Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            msg['time']!,
                            style: TextStyle(
                              fontSize: 9,
                              color: isUser ? Colors.white60 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // MESSAGE INPUT BAR
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: _sendMessage,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E1035) : Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: () => _sendMessage(_messageController.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
