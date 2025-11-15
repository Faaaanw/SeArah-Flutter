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
      id: json['id'] ?? json['user_id'], // API Laravel pakai user_id
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      isSharingLocation: json['is_sharing_location'] == 1 ||
          json['is_sharing_location'] == true,
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
    );
  }

  void updateLocation(double? lat, double? lng) {
    latitude = lat;
    longitude = lng;
  }
}
