class KnowledgeItem {
    final int? id;
    final String topic;
    final String content;
    final String? appName;
    final DateTime createdAt;

    KnowledgeItem({this.id, required this.topic, required this.content, this.appName, required this.createdAt});

    Map<String, dynamic> toMap() => {
      if (id != null) 'id': id,
      'topic': topic,
      'content': content,
      'app_name': appName,
      'created_at': createdAt.toIso8601String(),
    };

    factory KnowledgeItem.fromMap(Map<String, dynamic> m) => KnowledgeItem(
      id: m['id'] as int?,
      topic: m['topic'] as String,
      content: m['content'] as String,
      appName: m['app_name'] as String?,
      createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  class ChatMessage {
    final int? id;
    final String text;
    final bool isUser;
    final DateTime createdAt;

    const ChatMessage({this.id, required this.text, required this.isUser, required this.createdAt});

    Map<String, dynamic> toMap() => {
      if (id != null) 'id': id,
      'text': text,
      'is_user': isUser ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };

    factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
      id: m['id'] as int?,
      text: m['text'] as String,
      isUser: (m['is_user'] as int?) == 1,
      createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
  
