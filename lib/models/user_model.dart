class User {
  final int id;
  final String name;
  final String email;
  final String? photo;
  final bool isSharingLocation;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.photo,
    required this.isSharingLocation,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        photo: json['photo'],
        isSharingLocation: json['is_sharing_location'] == 1 ||
            json['is_sharing_location'] == true,
      );
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? photo,
    bool? isSharingLocation,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photo: photo ?? this.photo,
      isSharingLocation: isSharingLocation ?? this.isSharingLocation,
    );
  }
}
