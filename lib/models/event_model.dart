class Event {
  final int? id;
  final int creatorId;
  final int groupId;
  final String title;
  final String? description;
  final String? locationName;
  final double locationLatitude;
  final double locationLongitude;
  final DateTime startTime;
  final DateTime endTime; // 🆕 WAJIB ADA
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isJoined;
  final int participantsCount;

  Event({
    this.id,
    required this.creatorId,
    required this.groupId,
    required this.title,
    this.description,
    this.locationName,
    required this.locationLatitude,
    required this.locationLongitude,
    required this.startTime,
    required this.endTime, // 🆕
    this.createdAt,
    this.updatedAt,
    this.isJoined = false,
    this.participantsCount = 0,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      creatorId: json['creator_id'],
      groupId: json['group_id'],
      title: json['title'],
      description: json['description'],
      locationName: json['location_name'],
      locationLatitude: _parseDouble(json['location_latitude']),
      locationLongitude: _parseDouble(json['location_longitude']),
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      isJoined: json['is_joined'] ?? false,
      participantsCount: json['participants_count'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'creator_id': creatorId,
      'group_id': groupId,
      'title': title,
      'description': description,
      'location_name': locationName,
      'location_latitude': locationLatitude,
      'location_longitude': locationLongitude,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(), // 🆕
      'is_joined': isJoined,
      'participants_count': participantsCount,
      'created_at':
          createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updated_at':
          updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      creatorId: map['creator_id'],
      groupId: map['group_id'],
      title: map['title'],
      description: map['description'],
      locationName: map['location_name'],
      locationLatitude: _parseDouble(map['location_latitude']),
      locationLongitude: _parseDouble(map['location_longitude']),
      startTime: DateTime.parse(map['start_time']),
      endTime: DateTime.parse(map['end_time']),
      isJoined: map['is_joined'] ?? false,
      participantsCount: map['participants_count'] ?? 0,
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
