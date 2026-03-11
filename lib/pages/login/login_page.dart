import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haanppen_mobile/apis/auth_api.dart';
import 'package:haanppen_mobile/pages/login/find_password_modal.dart';
import 'package:haanppen_mobile/services/api_client.dart';
import 'package:haanppen_mobile/services/auth_service.dart';
import 'package:haanppen_mobile/services/storage_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  String _errorMessage = '';
  bool _hasInteracted = false;
  bool _isLoading = false;

  static const _hpBlue = Color(0xFF2563EB);
  static const _hpGray = Color(0xFF9CA3AF);
  static const _hpRed = Color(0xFFEF4444);

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validate() {
    final id = _idController.text;
    final password = _passwordController.text;

    String error = _phoneNumberValidation(id);
    if (error.isEmpty) error = _passwordValidation(password);

    setState(() {
      _hasInteracted = true;
      _errorMessage = error;
    });
  }

  String _phoneNumberValidation(String id) {
    if (id.isEmpty) return '아이디(전화번호)를 입력해주세요.';
    final phoneRegex = RegExp(r'^010[0-9]{8}$');
    if (!phoneRegex.hasMatch(id)) return '올바른 전화번호 형식을 입력해주세요.';
    return '';
  }

  String _passwordValidation(String password) {
    if (password.isEmpty) return '비밀번호를 입력해주세요.';
    return '';
  }

  Future<void> _handleLogin() async {
    _validate();
    if (_errorMessage.isNotEmpty) return;

    setState(() => _isLoading = true);

    try {
      final response = await AuthApi.login(
        id: _idController.text,
        password: _passwordController.text,
      );
      if (response.role != 'STUDENT') {
        setState(() => _errorMessage = '학생만 사용할 수 있습니다.');
        return;
      }
      await StorageService.saveLoginData(
        accessToken: response.accessToken,
        userName: response.userName,
        role: response.role,
      );
      AuthService.instance.setLoggedIn();
      if (mounted) context.go('/');
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleFindPassword() {
    showDialog(
      context: context,
      builder: (context) => const FindPasswordModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isButtonEnabled = _errorMessage.isEmpty &&
        _idController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        !_isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 484),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                Image.asset(
                  'lib/assests/haanppen_logo.png',
                  width: 220,
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _idController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration('아이디(전화번호)'),
                  onChanged: (_) => _validate(),
                  onSubmitted: (_) => _handleLogin(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  decoration: _inputDecoration('비밀번호').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: const Color(0xFFBCBCBC),
                      ),
                      onPressed: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                    ),
                  ),
                  onChanged: (_) => _validate(),
                  onSubmitted: (_) => _handleLogin(),
                ),
                SizedBox(
                  height: 40,
                  child: _hasInteracted && _errorMessage.isNotEmpty
                      ? Center(
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                              color: _hpRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : null,
                ),
                SizedBox(
                  width: double.infinity,
                  height: 62,
                  child: ElevatedButton(
                    onPressed: isButtonEnabled ? _handleLogin : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isButtonEnabled ? _hpBlue : _hpGray,
                      disabledBackgroundColor: _hpGray,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            '로그인',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _handleFindPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hpBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    '비밀번호 찾기',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => context.go('/privacy'),
                  child: const Text(
                    '개인정보처리방침',
                    style: TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
      ),
    );
  }
}
