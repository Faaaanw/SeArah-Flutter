
class Event {
  final int? id;
  final int creatorId;
  final String title;
  final String description;
  final String locationName;
  final double latitude;
  final double longitude;
  final String startTime;
  final String createdAt;
  final String updatedAt;

  Event({
    this.id,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.startTime,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'creator_id': creatorId,
      'title': title,
      'description': description,
      'location_name': locationName,
      'location_latitude': latitude,
      'location_longitude': longitude,
      'start_time': startTime,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      creatorId: map['creator_id'],
      title: map['title'],
      description: map['description'],
      locationName: map['location_name'],
      latitude: map['location_latitude'],
      longitude: map['location_longitude'],
      startTime: map['start_time'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
}
