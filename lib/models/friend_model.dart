// File: lib/models/friend_model.dart

class Friend {
  final int id;
  final String name;
  final String email;
  final bool isSharingLocation;
  // Tambahkan lokasi
  double? latitude;
  double? longitude;

  Friend({
    required this.id,
    required this.name,
    required this.email,
    required this.isSharingLocation,
    this.latitude,
    this.longitude,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      isSharingLocation: json['is_sharing_location'] ?? false,
    );
  }

  // Metode untuk menambahkan lokasi
  void updateLocation(double lat, double lng) {
    latitude = lat;
    longitude = lng;
  }
}