class Friend {
  final int id;
  final String name;
  final String email;
  final int groupId;
  bool isSharingLocation;
  double? latitude;
  double? longitude;
  final bool isFriend;
  final bool isMe;

  Friend({
    required this.id,
    required this.name,
    required this.email,
    required this.groupId,
    this.isSharingLocation = false,
    this.latitude,
    this.longitude,
    this.isFriend = false,
    this.isMe = false,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        return value == '1' || value.toLowerCase() == 'true';
      }
      return false;
    }

    return Friend(
      id: parseInt(json['id'] ?? json['user_id']),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      groupId: parseInt(json['group_id']),
      isSharingLocation: parseBool(json['is_sharing_location']),
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      isFriend: parseBool(json['is_friend']),
      isMe: parseBool(json['is_me']),
    );
  }

  void updateLocation(double? lat, double? lng) {
    latitude = lat;
    longitude = lng;
  }
}
