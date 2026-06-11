class Agent {
  final String id;
  final String name;
  final String description;
  final String systemPrompt;
  final String? voiceId;
  final String? avatarUrl;
  final DateTime createdAt;
  final String userId;

  Agent({
    required this.id,
    required this.name,
    required this.description,
    required this.systemPrompt,
    this.voiceId,
    this.avatarUrl,
    required this.createdAt,
    required this.userId,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      systemPrompt: json['system_prompt'] ?? '',
      voiceId: json['voice_id'],
      avatarUrl: json['avatar_url'],
      createdAt: DateTime.parse(json['created_at']),
      userId: json['user_id'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'system_prompt': systemPrompt,
      'voice_id': voiceId,
      'avatar_url': avatarUrl,
      'user_id': userId,
    };
  }
}