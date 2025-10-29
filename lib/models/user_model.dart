class User {
  final int id;
  final String name;
  final String email;
  final bool isSharingLocation;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.isSharingLocation,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        isSharingLocation: json['is_sharing_location'] == 1 || json['is_sharing_location'] == true,
      );
}
