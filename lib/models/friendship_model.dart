class Friendship {
  final int? id;
  final int userId;
  final int friendId;
  final String status; // pending, accepted, rejected, blocked
  final String? shareType; // location, event, none (nullable supaya aman)
  final String? createdAt;
  final String? updatedAt;

  Friendship({
    this.id,
    required this.userId,
    required this.friendId,
    required this.status,
    this.shareType,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'friend_id': friendId,
      'status': status,
      'share_type': shareType,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Friendship.fromMap(Map<String, dynamic> map) {
    return Friendship(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()),
      userId: map['user_id'] is int ? map['user_id'] : int.tryParse(map['user_id'].toString()) ?? 0,
      friendId: map['friend_id'] is int ? map['friend_id'] : int.tryParse(map['friend_id'].toString()) ?? 0,
      status: map['status'] ?? 'pending',
      shareType: map['share_type'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
}
