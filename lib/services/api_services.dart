import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ⚠️ Ganti dengan IP komputer kamu di jaringan lokal (bukan localhost)
  // Misal: http://192.168.2.140:8000/api
  static const String baseUrl = "http://192.168.1.13:8000/api";

  // 🔐 LOGIN MANUAL
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

  // 🌐 LOGIN/REGISTER DENGAN GOOGLE
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

  // 🧾 REGISTER
  static Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Registrasi gagal: ${response.body}');
    }
  }

  // 🚪 LOGOUT
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

  // 👥 Ambil daftar teman (otomatis berdasarkan token)
  static Future<List<dynamic>> getFriends(String token) async {
    print("Calling getFriends with token: $token");
    final res = await http.get(
      Uri.parse('$baseUrl/friends/list'),
      headers: {'Authorization': 'Bearer $token'},
    );

    print("Status: ${res.statusCode}");
    print("Response: ${res.body}");

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Gagal mengambil daftar teman: ${res.body}');
    }
  }

  // ➕ Kirim permintaan pertemanan
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

  // 👥 Ambil daftar grup user
  static Future<List<dynamic>> getUserGroups(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/groups'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal mengambil grup');
    }
  }

  // 🆕 Buat grup baru
  static Future<Map<String, dynamic>> createGroup({
    required String token,
    required String name,
    String? description,
    required List<int> memberIds,
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
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal membuat grup: ${response.body}');
    }
  }

  // 📍 Update lokasi user
  static Future<void> updateLocation({
    required String token,
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/location/update'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal memperbarui lokasi: ${response.body}');
    }
  }

  // 📍 Ambil lokasi teman-teman
  static Future<List<dynamic>> getFriendLocations(
      int userId, String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/location/friends/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Gagal mengambil lokasi teman: ${res.body}');
    }
  }
}
