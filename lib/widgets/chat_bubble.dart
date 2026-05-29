import 'package:flutter/material.dart';
  import '../models/knowledge_model.dart';

  class ChatBubble extends StatelessWidget {
    final ChatMessage message;
    const ChatBubble({super.key, required this.message});

    @override
    Widget build(BuildContext context) {
      final isUser = message.isUser;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              CircleAvatar(radius: 14,
                backgroundColor: const Color(0xFF9B59F5),
                child: const Text('AI', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
              const SizedBox(width: 8),
            ],
            Flexible(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF6C3CE1) : const Color(0xFF1E1E32),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18)),
                boxShadow: [BoxShadow(
                  color: (isUser ? const Color(0xFF6C3CE1) : const Color(0xFF9B59F5)).withOpacity(0.18),
                  blurRadius: 6, offset: const Offset(0, 3))],
              ),
              child: Text(message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.white.withOpacity(0.88),
                  fontSize: 14, height: 1.5)),
            )),
            if (isUser) ...[
              const SizedBox(width: 8),
              CircleAvatar(radius: 14,
                backgroundColor: const Color(0xFF3CE1C3).withOpacity(0.2),
                child: const Icon(Icons.person, size: 16, color: Color(0xFF3CE1C3))),
            ],
          ],
        ),
      );
    }
  }
  
