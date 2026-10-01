import 'package:flutter/material.dart';
import '../../../models/chat_message_model.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isRequest) return _RequestBubble(message: message, isMe: isMe);
    return _NormalBubble(message: message, isMe: isMe);
  }
}

class _NormalBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;

  const _NormalBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Only show sender name if it's not empty
          if (!isMe && message.senderName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 3),
              child: Text(
                message.senderName,
                style: const TextStyle(
                  color: Color(0xFF9E9EC8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF6C63FF) : const Color(0xFF222240),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
            ),
            child: Text(
              message.message,
              style: TextStyle(
                color: isMe ? Colors.white : const Color(0xFFE0E0FF),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;

  const _RequestBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.queue_music, color: Color(0xFF6C63FF), size: 16),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${message.senderName} requested "${message.requestSongQuery}"',
                  style: const TextStyle(
                    color: Color(0xFF9E9EC8),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}