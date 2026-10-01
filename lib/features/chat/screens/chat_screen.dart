import 'package:flutter/material.dart';
import '../../../models/chat_message_model.dart';
import '../../../models/user_model.dart';
import '../../../services/chat_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/request_queue.dart';

class ChatScreen extends StatefulWidget {
  final String lobbyId;
  final UserModel user;
  final bool isDJ;

  const ChatScreen({
    super.key,
    required this.lobbyId,
    required this.user,
    required this.isDJ,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  bool _sending = false;

  // Track message count to detect genuinely new messages
  int _lastMessageCount = 0;
  // Track whether user is near bottom
  bool _isNearBottom = true;
  // Whether we've done the initial jump-to-bottom
  bool _initialScrollDone = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    _isNearBottom = pos.maxScrollExtent - pos.pixels < 80;
  }

  // Called only when we know new messages have arrived AND user is near bottom
  void _scrollToBottom({bool jump = false}) {
    if (!_scrollController.hasClients) return;
    if (jump) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    } else {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    _controller.clear();
    setState(() => _sending = true);

    try {
      if (text.toLowerCase().startsWith('/request ')) {
        final query = text.substring('/request '.length).trim();
        if (query.isEmpty) {
          _showHint();
          return;
        }
        await _chatService.sendRequest(
          lobbyId: widget.lobbyId,
          uid: widget.user.uid,
          requesterName: widget.user.fullName,
          songQuery: query,
        );
      } else {
        await _chatService.sendMessage(
          lobbyId: widget.lobbyId,
          uid: widget.user.uid,
          senderName: widget.user.fullName,
          message: text,
        );
      }
      // Force scroll after sending — user always wants to see their own message
      _isNearBottom = true;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Usage: /request <song name>'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  bool _shouldShowSenderName(List<ChatMessageModel> messages, int index) {
    if (index == 0) return true;
    final current = messages[index];
    final previous = messages[index - 1];
    return current.uid != previous.uid ||
        current.isRequest ||
        previous.isRequest;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F0F1A),
      child: Column(
        children: [
          RequestQueue(lobbyId: widget.lobbyId, isDJ: widget.isDJ),

          // Messages
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: _chatService.chatStream(widget.lobbyId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                  );
                }

                final messages = snap.data ?? [];

                if (messages.isEmpty) {
                  return const _EmptyChat();
                }

                final isNewMessage = messages.length > _lastMessageCount;
                final isFirstLoad = !_initialScrollDone;

                if (isFirstLoad || (isNewMessage && _isNearBottom)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!_scrollController.hasClients) return;
                    if (isFirstLoad) {
                      _scrollController
                          .jumpTo(_scrollController.position.maxScrollExtent);
                      _initialScrollDone = true;
                    } else {
                      _scrollToBottom();
                    }
                  });
                }

                _lastMessageCount = messages.length;

                return ListView.builder(
                  controller: _scrollController,
                  // Keep items pinned to bottom naturally
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.uid == widget.user.uid;
                    final showName = _shouldShowSenderName(messages, index);

                    final display = ChatMessageModel(
                      id: message.id,
                      uid: message.uid,
                      senderName: showName ? message.senderName : '',
                      message: message.message,
                      sentAt: message.sentAt,
                      isRequest: message.isRequest,
                      requestSongQuery: message.requestSongQuery,
                    );

                    return ChatBubble(message: display, isMe: isMe);
                  },
                );
              },
            ),
          ),

          // Input bar
          _ChatInput(
            controller: _controller,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _ChatInput({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        border: Border(top: BorderSide(color: Color(0xFF222240))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                onSubmitted: (_) => onSend(),
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: 'Message or /request <song>...',
                  hintStyle:
                      const TextStyle(color: Color(0xFF5A5A80), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF222240),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: sending ? null : onSend,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: sending
                      ? const Color(0xFF6C63FF).withValues(alpha: 0.5)
                      : const Color(0xFF6C63FF),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, color: Color(0xFF9E9EC8), size: 40),
          SizedBox(height: 10),
          Text(
            'No messages yet.\nSay hi or use /request <song>',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9E9EC8), fontSize: 13),
          ),
        ],
      ),
    );
  }
}