class Device {
  final String id;
  final String name;
  final String macAddress;
  final String? deviceCode;
  final String? currentAgentId;
  final bool isOnline;
  final int? volume;
  final DateTime? lastSeen;
  final DateTime createdAt;
  final String userId;

  Device({
    required this.id,
    required this.name,
    required this.macAddress,
    this.deviceCode,
    this.currentAgentId,
    required this.isOnline,
    this.volume,
    this.lastSeen,
    required this.createdAt,
    required this.userId,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'].toString(),
      name: json['name'] ?? 'Unknown Device',
      macAddress: json['mac_address'] ?? '',
      deviceCode: json['device_code'],
      currentAgentId: json['current_agent_id']?.toString(),
      isOnline: json['is_online'] ?? false,
      volume: json['volume'],
      lastSeen: json['last_seen'] != null 
          ? DateTime.parse(json['last_seen']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      userId: json['user_id'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mac_address': macAddress,
      'device_code': deviceCode,
      'current_agent_id': currentAgentId,
      'is_online': isOnline,
      'volume': volume,
      'last_seen': lastSeen?.toIso8601String(),
      'user_id': userId,
    };
  }

  Device copyWith({
    String? name,
    String? currentAgentId,
    bool? isOnline,
    int? volume,
    DateTime? lastSeen,
  }) {
    return Device(
      id: id,
      name: name ?? this.name,
      macAddress: macAddress,
      deviceCode: deviceCode,
      currentAgentId: currentAgentId ?? this.currentAgentId,
      isOnline: isOnline ?? this.isOnline,
      volume: volume ?? this.volume,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt,
      userId: userId,
    );
  }
}