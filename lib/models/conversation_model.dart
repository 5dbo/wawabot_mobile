class Conversation {
  final String id;
  final String agentId;
  final String message;
  final String role; // 'user' or 'assistant'
  final DateTime createdAt;
  final String? userId;

  Conversation({
    required this.id,
    required this.agentId,
    required this.message,
    required this.role,
    required this.createdAt,
    this.userId,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'].toString(),
      agentId: json['agent_id'].toString(),
      message: json['message'] ?? '',
      role: json['role'] ?? 'user',
      createdAt: DateTime.parse(json['created_at']),
      userId: json['user_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agent_id': agentId,
      'message': message,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
    };
  }

  bool get isUserMessage => role == 'user';
  bool get isAssistantMessage => role == 'assistant';
}