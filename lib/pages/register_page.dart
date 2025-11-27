import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_services.dart';
import 'package:searah_backend/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import '../Navigation/navbar.dart'; // Tidak dibutuhkan lagi jika navigasi ke Login
// import '../viewmodel/home_viewmodel.dart'; // Tidak dibutuhkan jika tidak langsung login

const Color _kFieldBackgroundColor = Color(0xFFFDE5DC);
const Color _kPrimaryButtonColor = Color(0xFFFA8B60);
const Color _kDividerColor = Color(0xFFE0E0E0);
const Color _kSignUpLinkColor = Color(0xFF2F80ED);

class RegisterViewModel extends ChangeNotifier {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Fungsi untuk menampilkan pop-up hasil
  void _showResultDialog(BuildContext context, String title, String message,
      {bool isSuccess = false}) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false, // User harus klik OK
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? Colors.green : Colors.red),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 18))),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Tutup Dialog
                // Jika sukses, lakukan navigasi keluar dari halaman register
                if (isSuccess) {
                  Navigator.pop(context); // KEMBALI KE LOGIN PAGE
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> register(BuildContext context) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final name = nameController.text.trim();
      final email = emailController.text.trim();
      final pass = passwordController.text.trim();
      final confirm = confirmController.text.trim();

      // 1. Validasi Input Dasar
      if (name.isEmpty || email.isEmpty || pass.isEmpty || confirm.isEmpty) {
        _showResultDialog(context, 'Perhatian', 'Semua field wajib diisi.',
            isSuccess: false);
        return;
      }

      // 2. Validasi Konfirmasi Password
      if (pass != confirm) {
        _showResultDialog(
            context, 'Perhatian', 'Konfirmasi password tidak cocok.',
            isSuccess: false);
        return;
      }

      // 3. Panggilan API
      final result = await ApiService.register(name, email, pass, confirm);
      print("Response Register: $result");

      final token = result['token'];
      // final user = result['user']; // Opsional, tergantung response API
      final messageRaw = result['message']?.toString() ?? '';
      final messageLower = messageRaw.toLowerCase();

      // Cek apakah akun sudah ada
      final bool isAccountExists = messageLower.contains('already exists') ||
          messageLower.contains('terdaftar');

      // Cek apakah sukses (Bisa dari token, ATAU dari pesan 'berhasil'/'created')
      // INI PERBAIKAN UTAMANYA: Kita anggap sukses jika ada kata 'berhasil' atau 'created'
      final bool isSuccessMessage = messageLower.contains('berhasil') ||
          messageLower.contains('created') ||
          messageLower.contains('success');

      if (isAccountExists) {
        // --- KASUS: AKUN SUDAH ADA ---
        if (context.mounted) {
          _showResultDialog(context, 'Registrasi Gagal',
              'Akun dengan email ini sudah terdaftar. Silakan login.',
              isSuccess: false);
        }
      } else if ((token != null) || isSuccessMessage) {
        // --- KASUS: REGISTRASI BERHASIL (Fix Logic) ---
        // Masuk sini jika ada token ATAU pesannya positif (seperti di screenshot Anda)

        if (context.mounted) {
          // Kita tidak perlu simpan sesi login (SharedPreferences) di sini
          // karena user diminta login ulang secara manual.

          _showResultDialog(context, 'Registrasi Berhasil! 🎉',
              'Akun berhasil dibuat. Silakan login dengan akun baru Anda.',
              isSuccess:
                  true // Ini akan memicu navigasi ke Login saat 'OK' ditekan
              );
        }
      } else {
        // --- KASUS: GAGAL LAINNYA ---
        // Jika response 200 tapi pesannya aneh/bukan sukses
        throw Exception(
            messageRaw.isNotEmpty ? messageRaw : 'Gagal mendaftar.');
      }
    } catch (e) {
      if (context.mounted) {
        String errorMessage;
        String errorString = e.toString();

        if (errorString.contains('SocketException') ||
            errorString.contains('network')) {
          errorMessage =
              'Tidak ada koneksi internet. Silakan periksa koneksi Anda.';
        } else if (errorString.contains('message') &&
            errorString.contains('{')) {
          final regex = RegExp(r'"message":"(.*?)"');
          final match = regex.firstMatch(errorString);
          errorMessage = match != null && match.groupCount >= 1
              ? match.group(1)!
              : 'Gagal mendaftar. Format data tidak valid.';
        } else {
          errorMessage = errorString.contains('Exception: ')
              ? errorString.replaceFirst('Exception: ', '')
              : 'Terjadi kesalahan server.';
        }

        _showResultDialog(context, 'Registrasi Gagal 😥', errorMessage,
            isSuccess: false);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class RegisterPageWidget extends StatelessWidget {
  const RegisterPageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegisterViewModel(),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatelessWidget {
  const _RegisterView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegisterViewModel>();
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final panelHeight =
        size.height < 700 ? size.height * 0.72 : size.height * 0.65;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(color: Colors.grey.shade200),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: panelHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                  border: Border.all(color: _kDividerColor),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 12,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          PeachField(
                            icon: Icons.person_outline,
                            hint: 'Full Name',
                            controller: vm.nameController,
                          ),
                          const SizedBox(height: 16),
                          PeachField(
                            icon: Icons.email_outlined,
                            hint: 'Email',
                            controller: vm.emailController,
                          ),
                          const SizedBox(height: 16),
                          PeachField(
                            icon: Icons.lock_outline,
                            hint: 'Password',
                            controller: vm.passwordController,
                            obscure: true,
                          ),
                          const SizedBox(height: 16),
                          PeachField(
                            icon: Icons.lock_outline,
                            hint: 'Confirm Password',
                            controller: vm.confirmController,
                            obscure: true,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 60,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: vm.isLoading
                                  ? null
                                  : () => vm.register(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kPrimaryButtonColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              child: vm.isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : Text(
                                      'Sign Up',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Already have an account? Log in',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: _kSignUpLinkColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reuse komponen dari login
class PeachField extends StatefulWidget {
  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final bool obscure;

  const PeachField({
    super.key,
    required this.icon,
    required this.hint,
    required this.controller,
    this.obscure = false,
  });

  @override
  State<PeachField> createState() => _PeachFieldState();
}

class _PeachFieldState extends State<PeachField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: _kFieldBackgroundColor,
        borderRadius: BorderRadius.circular(100),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(widget.icon, color: _kPrimaryButtonColor),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: widget.controller,
              obscureText: _isObscured,
              style: const TextStyle(color: _kPrimaryButtonColor),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: widget.hint,
                hintStyle: const TextStyle(color: _kPrimaryButtonColor),
                suffixIcon: widget.obscure
                    ? IconButton(
                        icon: Icon(
                          _isObscured
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: _kPrimaryButtonColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _isObscured = !_isObscured;
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
