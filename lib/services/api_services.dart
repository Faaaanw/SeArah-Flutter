import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Ganti dengan IP lokal kamu
 static const String baseUrl = "http://localhost:8000/api";
  // 🔐 LOGIN MANUAL
  static Future<Map<String, dynamic>> login(String email, String password) async {
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

  // 🌐 LOGIN/REGISTER DENGAN GOOGLE (BARU DITAMBAHKAN)
  static Future<Map<String, dynamic>> googleLogin(String token, {bool useAccessToken = false}) async {
  final body = useAccessToken
      ? {'access_token': token}
      : {'id_token': token};

  final response = await http.post(
    Uri.parse('http://localhost:8000/api/google-login'),
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

  // 👥 Ambil daftar teman
  static Future<List<dynamic>> getFriends(int userId, String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/friends/list/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Gagal mengambil daftar teman: ${res.body}');
    }
  }

  // 📍 Ambil lokasi teman
  static Future<List<dynamic>> getFriendLocations(
      int userId, String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/friend-locations/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Gagal mengambil lokasi teman: ${res.body}');
    }
  }
}
