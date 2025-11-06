class SmartZone {
  // Properti yang sesuai dengan kolom tabel
  final int? id; // PRIMARY KEY
  final int userId;
  final String name;
  final double centerLatitude;
  final double centerLongitude;
  final int radiusM;
  final int? associatedEventId;
  final String? createdAt; // Untuk waktu pembuatan (opsional)
  final String? updatedAt; // Untuk waktu pembaruan (opsional)

  // Konstruktor
  SmartZone({
    this.id,
    required this.userId,
    required this.name,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radiusM,
    this.associatedEventId,
    this.createdAt,
    this.updatedAt,
  });

  // --- Metode Konversi untuk sqflite ---

  /// Konversi objek SmartZone menjadi Map (untuk operasi INSERT/UPDATE)
  Map<String, dynamic> toMap() {
    return {
      // 'id' dihilangkan jika AUTOINCREMENT (untuk INSERT)
      // atau disertakan jika ingin UPDATE
      'id': id, 
      'user_id': userId,
      'name': name,
      'center_latitude': centerLatitude,
      'center_longitude': centerLongitude,
      'radius_m': radiusM,
      'associated_event_id': associatedEventId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Factory constructor untuk membuat objek SmartZone dari Map (hasil query database)
  factory SmartZone.fromMap(Map<String, dynamic> map) {
    return SmartZone(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      centerLatitude: map['center_latitude'] as double,
      centerLongitude: map['center_longitude'] as double,
      radiusM: map['radius_m'] as int,
      associatedEventId: map['associated_event_id'] as int?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  // Metode copyWith untuk kemudahan membuat instance baru dengan perubahan
  SmartZone copyWith({
    int? id,
    int? userId,
    String? name,
    double? centerLatitude,
    double? centerLongitude,
    int? radiusM,
    int? associatedEventId,
    String? createdAt,
    String? updatedAt,
  }) {
    return SmartZone(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      centerLatitude: centerLatitude ?? this.centerLatitude,
      centerLongitude: centerLongitude ?? this.centerLongitude,
      radiusM: radiusM ?? this.radiusM,
      associatedEventId: associatedEventId ?? this.associatedEventId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SmartZone(id: $id, userId: $userId, name: $name, centerLat: $centerLatitude, centerLng: $centerLongitude, radius: $radiusM, eventId: $associatedEventId)';
  }
}