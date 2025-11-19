import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:searah_backend/models/event_model.dart';
import 'package:searah_backend/models/friend_model.dart';
import 'package:searah_backend/models/group_model.dart';
import 'package:geolocator/geolocator.dart';

class ApiService {
  //api route
  static const String baseUrl = "http://192.168.1.7:8003/api";

  //  LOGIN MANUAL
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Login gagal: ${response.body}');
    }
  }

  //  LOGIN/REGISTER DENGAN GOOGLE
  static Future<Map<String, dynamic>> googleLogin(String token,
      {bool useAccessToken = false}) async {
    final body = useAccessToken ? {'access_token': token} : {'id_token': token};

    final response = await http.post(
      Uri.parse('$baseUrl/google-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    return jsonDecode(response.body);
  }

  //   REGISTER
  static Future<Map<String, dynamic>> register(String name, String email,
      String password, String confirmPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': confirmPassword,
      }),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Registrasi gagal: ${response.body}');
    }
  }

  static Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          jsonDecode(response.body)['message'] ?? 'Gagal mengganti password');
    }
  }

  //   LOGOUT
  static Future<void> logout(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Logout gagal: ${response.body}');
    }
  }

  //   Ambil profil user
  static Future<Map<String, dynamic>> getCurrentUser(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal mengambil data user: ${response.body}');
    }
  }

  static Future<void> updateName({
    required String token,
    required String name,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/update-name'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal update nama: ${response.body}');
    }
  }

  //   Ambil daftar teman (otomatis berdasarkan token)
  static Future<List<dynamic>> getFriends(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/friends/list'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body['success'] == true && body['data'] != null) {
        return body['data']; // Ambil list dari key 'data'
      } else {
        return [];
      }
    } else {
      throw Exception('Gagal mengambil daftar teman: ${res.body}');
    }
  }

  //   Kirim permintaan pertemanan
  static Future<Map<String, dynamic>> addFriend({
    required int userId,
    required int friendId,
    required String token,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/friends/add'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
        'friend_id': friendId,
      }),
    );

    if (res.statusCode == 201) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Gagal mengirim permintaan teman: ${res.body}');
    }
  }

  // ✅ Terima permintaan pertemanan
  static Future<void> acceptFriend(int friendshipId, String token) async {
    final res = await http.post(
      Uri.parse('$baseUrl/friends/accept/$friendshipId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) {
      throw Exception('Gagal menerima permintaan: ${res.body}');
    }
  }

  // 📍 Ambil lokasi teman-teman
  // 📍 Ambil lokasi teman-teman
  static Future<List<dynamic>> getFriendLocations(
      int userId, String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/location/friends/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body is Map && body['friends'] != null) {
        return body['friends']; // ✅ ambil array "friends" saja
      } else if (body is List) {
        return body;
      } else {
        return [];
      }
    } else {
      throw Exception('Gagal mengambil lokasi teman: ${res.body}');
    }
  }

  static Future<List<Group>> getUserGroups(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/groups'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      // Mapping dari List<Map> ke List<Group>
      return jsonList.map((json) => Group.fromJson(json)).toList();
    } else {
      throw Exception('Gagal mengambil grup: ${response.body}');
    }
  }

  // 🆕 Buat grup baru
  // Menggunakan Model Group untuk return value
  static Future<Group> createGroup({
    required String token,
    required String name,
    String? description,
    required List<int> memberIds, // ID teman yang akan diundang
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/groups'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'description': description,
        'member_ids': memberIds,
      }),
    );

    if (response.statusCode == 201) {
      // API mengembalikan objek {'message': '...', 'group': {...}}
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Group.fromJson(data['group']);
    } else {
      throw Exception('Gagal membuat grup: ${response.body}');
    }
  }

  // ➕ Tambah Anggota ke Grup
  static Future<void> addMemberToGroup({
    required String token,
    required int groupId,
    required int memberUserId, // ID pengguna yang akan ditambahkan
  }) async {
    final response = await http.post(
      // URL: /groups/{group}/members
      Uri.parse('$baseUrl/groups/$groupId/members'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': memberUserId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal menambah anggota: ${response.body}');
    }
    // Jika berhasil (status 200), tidak ada data yang dikembalikan (void)
  }

  static Future<Event> createEvent({
    required String token,
    required int groupId,
    required String title,
    String? description,
    String? locationName,
    required double lat,
    required double lng,
    required DateTime startTime,
  }) async {
    final eventData = {
      'title': title,
      'description': description,
      'location_name': locationName,
      'location_latitude': lat,
      'location_longitude': lng,
      'start_time': startTime
          .toIso8601String()
          .substring(0, 19)
          .replaceFirst('T', ' '), // Format Laravel: Y-m-d H:i:s
    };

    final response = await http.post(
      Uri.parse('$baseUrl/groups/$groupId/events'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: jsonEncode(eventData),
    );

    if (response.statusCode == 201) {
      return Event.fromJson(jsonDecode(response.body)['event']);
    } else {
      // Tangani error validasi atau 403
      throw Exception(
          jsonDecode(response.body)['message'] ?? 'Gagal membuat event.');
    }
  }

// 2. 🔍 Ambil Semua Event Grup dari Server
  static Future<List<Event>> getGroupEvents(int groupId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/groups/$groupId/events'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Event.fromJson(json)).toList();
    } else {
      throw Exception(
          'Gagal mengambil event grup: ${jsonDecode(response.body)['message'] ?? 'Error server.'}');
    }
  }

  // 🌐 GET Request Umum (bisa digunakan untuk endpoint seperti /search-user)
  static Future<Map<String, dynamic>> getRequest(
      String endpoint, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal melakukan GET ke $endpoint: ${response.body}');
    }
  }

  static Future<List<dynamic>> getGroupMembersWithLocation({
    required int groupId,
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/groups/$groupId/members-location'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // API mengembalikan {"members": [...]}
      if (data["success"] == true && data["members"] != null) {
        return data["members"];
      } else {
        return [];
      }
    } else {
      throw Exception("Gagal mengambil anggota grup: ${response.body}");
    }
  }

  // 🚦 Ambil daftar permintaan teman yang belum diterima
  static Future<List<dynamic>> getPendingRequests(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/friends/requests/pending'),
      headers: {'Authorization': 'Bearer $token'},
    );

    print("Pending Friends Status: ${res.statusCode}");
    print("Pending Friends Response: ${res.body}");

    if (res.statusCode == 200) {
      // Pastikan API mengembalikan list
      final body = jsonDecode(res.body);
      if (body is List) {
        return body;
      } else if (body['data'] != null) {
        return body['data'];
      } else {
        throw Exception('Format respons tidak dikenal: ${res.body}');
      }
    } else {
      throw Exception('Gagal mengambil permintaan teman: ${res.body}');
    }
  }

  static Future<void> updateUserLocation({
    required int userId,
    required String token,
    required double latitude,
    required double longitude,
    required bool isSharing,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/location/update'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
        'is_sharing_location': isSharing,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal update lokasi: ${response.body}');
    }
  }

  // Di dalam class ApiService
  static Future<List<dynamic>> searchLocation(String query,
      {double? lat, double? lon}) async {
    try {
      String url = '$baseUrl/search-location?q=$query';
      if (lat != null && lon != null) {
        url += '&lat=$lat&lon=$lon';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
      } else {
        print('Gagal memuat lokasi (${response.statusCode})');
      }
    } catch (e) {
      print('Error mencari lokasi: $e');
    }
    return [];
  }

  static Future<List<Friend>> getFriendsByGroup({
    required int groupId,
    required String token,
  }) async {
    final res = await http.get(
      Uri.parse('$baseUrl/groups/$groupId/members-location'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      // API: { success: true, members: [...] }
      final list = data['members'] as List;

      return list.map((json) {
        // ⬅️ inject groupId secara manual
        json['group_id'] = groupId;
        return Friend.fromJson(json);
      }).toList();
    } else {
      throw Exception('Gagal ambil anggota grup: ${res.body}');
    }
  }
}
