import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:searah_backend/Navigation/navbar.dart';
import 'package:searah_backend/pages/dashboard_page.dart';
import 'package:searah_backend/pages/register_page.dart';
import 'package:searah_backend/viewmodel/home_viewmodel.dart';
import '../services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:searah_backend/main.dart'; // supaya bisa akses navigatorKey

// ====== Konstanta Warna ======
const Color _kPeachIconColor = Color(0xFFBFA4A0);
const Color _kFieldBackgroundColor = Color(0xFFFDE5DC);
const Color _kPrimaryButtonColor = Color(0xFFFA8B60);
const Color _kDividerColor = Color(0xFFE0E0E0);
const Color _kGoogleButtonColor = Color(0xFFF2F2F2);
const Color _kSignUpLinkColor = Color(0xFF2F80ED);

// ====== VIEWMODEL ======
class LoginViewModel extends ChangeNotifier {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        "977543867365-oqbmmmqtmdat1vsl2oud0srqr1v70prc.apps.googleusercontent.com", // Web Client ID dari Google Console
    scopes: ['email', 'profile', 'openid'],
  );

  // ===== Login Email/Password =====
  Future<void> login(BuildContext context) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        // ... (SnackBar error handling)
        _isLoading = false;
        notifyListeners();
        return;
      }

      final result = await ApiService.login(email, password);
      print("Response Login: $result");

      final bool isSuccess = result['success'] == true ||
          result['status'] == true ||
          result['token'] != null; // Cek token juga

      if (isSuccess) {
        final token = result['token'];
        final user = result['user'];
        final userId = user?['id'];
        final userName = user?['name'];
        final userEmail = user?['email'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setInt('user_id', userId);
        if (userName != null) await prefs.setString('user_name', userName);
        if (userEmail != null) await prefs.setString('user_email', userEmail);

        if (token == null || userId == null) {
          throw Exception('Token atau userId tidak ditemukan dalam response.');
        }

        // 1. Ambil HomeViewModel dari tree
        final vm = context.read<HomeViewModel>();
        vm.setUserSession(userId: userId, token: token);

        // 2. Muat data awal (penting agar HomeViewModel siap)
        await vm.loadInitialData();

        // 3. NAVIGASI TO THE POINT MENGGUNAKAN GLOBAL KEY
        // Ini adalah cara paling andal untuk navigasi setelah operasi async
        // 3. NAVIGASI TO THE POINT MENGGUNAKAN GLOBAL KEY
        final navigator = navigatorKey.currentState;

        if (navigator != null) {
          print("✅ Navigating to MainNavigationPage using GlobalKey...");
          navigator.pushReplacement(
            MaterialPageRoute(builder: (_) => const Navbar()),
          );
        } else if (context.mounted) {
          // Fallback, jika GlobalKey gagal
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const Navbar()),
          );
        }
      } else {
        // ... (Handle login gagal jika respons 200 tapi isSuccess false)
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login gagal: $e')),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===== Login Google =====
  Future<void> loginWithGoogle(BuildContext context) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final googleAuth = await googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null && accessToken == null) {
        throw Exception('Token Google tidak ditemukan.');
      }

      final result = await ApiService.googleLogin(
        idToken ?? accessToken!,
        useAccessToken: idToken == null,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Login Google berhasil')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Google gagal: $e')),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

// ====== LOGIN PAGE ======
class LoginPageWidget extends StatelessWidget {
  const LoginPageWidget({super.key});

  static String routeName = 'LoginPage';
  static String routePath = '/loginPage';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  void _unfocus(BuildContext context) => FocusScope.of(context).unfocus();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final panelHeight =
        size.height < 700 ? size.height * 0.72 : size.height * 0.65;

    return GestureDetector(
      onTap: () => _unfocus(context),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                  child: Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/2/2f/Google_2015_logo.svg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: Colors.grey.shade200),
              )),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  height: panelHeight,
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
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 12),
                              PeachField(
                                icon: Icons.person_outline,
                                hint: 'Username / Email',
                                controller: vm.emailController,
                              ),
                              const SizedBox(height: 16),
                              PeachField(
                                icon: Icons.lock_outline,
                                hint: 'Password',
                                controller: vm.passwordController,
                                obscure: true,
                              ),
                              const SizedBox(height: 12),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(
                                    'Forgot Password?',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // ===== Tombol Login =====
                              SizedBox(
                                height: 60,
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: vm.isLoading
                                      ? null
                                      : () => vm.login(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _kPrimaryButtonColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: vm.isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : Text(
                                          'Log in',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.black87,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const RegisterPageWidget()),
                                      );
                                    },
                                    child: Text(
                                      'Sign up here',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: _kSignUpLinkColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // ===== Login With Google =====
                              SizedBox(
                                height: 64,
                                child: ElevatedButton(
                                  onPressed: vm.isLoading
                                      ? null
                                      : () => vm.loginWithGoogle(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _kGoogleButtonColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: vm.isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.black)
                                      : FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Image.asset(
                                                'assets/images/google.png',
                                                height: 28,
                                                width: 28,
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Login With Google',
                                                style: theme.textTheme.bodyLarge
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== PeachField Widget =====
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
          Flexible(
            flex: 0,
            child: Icon(widget.icon, color: _kPrimaryButtonColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: widget.controller,
              obscureText: _isObscured,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(color: _kPrimaryButtonColor),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(color: _kPrimaryButtonColor),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
