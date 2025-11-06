class Friend {
  final int id;
  final String name;
  final String email;
  bool isSharingLocation;
  double? latitude;
  double? longitude;

  Friend({
    required this.id,
    required this.name,
    required this.email,
    this.isSharingLocation = false,
    this.latitude,
    this.longitude,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      // konversi 0/1 ke bool
      isSharingLocation: json['is_sharing_location'] == 1,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  void updateLocation(double? lat, double? lng) {
    latitude = lat;
    longitude = lng;
  }
}
