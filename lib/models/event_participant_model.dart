class EventParticipant {
  final int? id;
  final int eventId;
  final int userId;
  final String role; // 'organizer' atau 'participant'
  final String status; // 'joined', 'pending', 'declined'
  final String createdAt;

  EventParticipant({
    this.id,
    required this.eventId,
    required this.userId,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'role': role,
      'status': status,
      'created_at': createdAt,
    };
  }

  factory EventParticipant.fromMap(Map<String, dynamic> map) {
    return EventParticipant(
      id: map['id'],
      eventId: map['event_id'],
      userId: map['user_id'],
      role: map['role'],
      status: map['status'],
      createdAt: map['created_at'],
    );
  }
}
