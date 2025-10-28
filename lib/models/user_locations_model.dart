class UserLocation {
  final int? id;
  final int userId;
  final double latitude;
  final double longitude;
  final String updatedAt;

  UserLocation({
    this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'updated_at': updatedAt,
    };
  }

  factory UserLocation.fromMap(Map<String, dynamic> map) {
    return UserLocation(
      id: map['id'],
      userId: map['user_id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      updatedAt: map['updated_at'],
    );
  }
}
