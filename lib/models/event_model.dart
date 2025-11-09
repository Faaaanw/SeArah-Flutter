// lib/models/event_model.dart
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
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.createdAt,
    this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      creatorId: json['creator_id'],
      groupId: json['group_id'],
      title: json['title'],
      description: json['description'],
      locationName: json['location_name'],
      locationLatitude: (json['location_latitude'] as num).toDouble(),
      locationLongitude: (json['location_longitude'] as num).toDouble(),
      startTime: DateTime.parse(json['start_time']),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  // Untuk penyimpanan SQLite
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
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updated_at': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  // Untuk dibaca dari SQLite
  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      creatorId: map['creator_id'],
      groupId: map['group_id'],
      title: map['title'],
      description: map['description'],
      locationName: map['location_name'],
      locationLatitude: (map['location_latitude'] as num).toDouble(),
      locationLongitude: (map['location_longitude'] as num).toDouble(),
      startTime: DateTime.parse(map['start_time']),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }
}