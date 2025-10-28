class Friendship {
  final int? id;
  final int userId;
  final int friendId;
  final String status; // pending, accepted, rejected, blocked
  final String shareType; // location, event, none
  final String createdAt;
  final String updatedAt;

  Friendship({
    this.id,
    required this.userId,
    required this.friendId,
    required this.status,
    required this.shareType,
    required this.createdAt,
    required this.updatedAt,
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
      id: map['id'],
      userId: map['user_id'],
      friendId: map['friend_id'],
      status: map['status'],
      shareType: map['share_type'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
}
