class UserLocation {
  final int? id;
  final int userId;
  final double latitude;
  final double longitude;
  final String? updatedAt;

  UserLocation({
    this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.updatedAt,
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
      latitude: map['latitude'] * 1.0,
      longitude: map['longitude'] * 1.0,
      updatedAt: map['updated_at'],
    );
  }

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      id: json['id'],
      userId: json['user_id'],
      latitude: double.tryParse(json['latitude'].toString()) ?? 0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0,
      updatedAt: json['updated_at'],
    );
  }
}
