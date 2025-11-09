// lib/models/group_model.dart
class User {
  final int id;
  final String name;
  final String email;
  final bool? isAdmin; // Tambahan dari tabel pivot

  User({
    required this.id,
    required this.name,
    required this.email,
    this.isAdmin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      // isAdmin tidak selalu ada di response 'members'
      isAdmin: json['pivot'] != null ? json['pivot']['is_admin'] == 1 : null,
    );
  }
}

class Group {
  final int id;
  final int creatorId;
  final String name;
  final String? description;
  final List<User> members;
  final DateTime createdAt;
  final DateTime updatedAt;

  Group({
    required this.id,
    required this.creatorId,
    required this.name,
    this.description,
    required this.members,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    var membersList = json['members'] as List;
    List<User> members = membersList.map((i) => User.fromJson(i)).toList();

    return Group(
      id: json['id'] as int,
      creatorId: json['creator_id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      members: members,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}