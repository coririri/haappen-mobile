import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../apis/account_api.dart';
import '../../services/api_client.dart';
import '../../services/storage_service.dart';

class UserInformationPage extends StatefulWidget {
  const UserInformationPage({super.key});

  @override
  State<UserInformationPage> createState() => _UserInformationPageState();
}

class _UserInformationPageState extends State<UserInformationPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  String _nameError = '';
  String _phoneError = '';
  String _passwordError = '';
  String _newPasswordError = '';
  bool _isLoading = true;
  bool _isSaving = false;

  static const _hpRed = Color(0xFFEF4444);

  bool get _hasError =>
      _nameError.isNotEmpty ||
      _phoneError.isNotEmpty ||
      _passwordError.isNotEmpty ||
      _newPasswordError.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _nameController.addListener(_validateName);
    _phoneController.addListener(_validatePhone);
    _passwordController.addListener(_validatePassword);
    _newPasswordController.addListener(_validateNewPassword);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final token = await StorageService.getAccessToken();
      if (token == null) {
        if (mounted) context.go('/login');
        return;
      }
      final info = await AccountApi.getMyInfo(accessToken: token);
      if (mounted) {
        _nameController.text = info.userName;
        _phoneController.text = info.phoneNumber;
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _validateName() {
    setState(() {
      _nameError = _nameController.text.isEmpty ? '이름은 빈칸일 수 없습니다.' : '';
    });
  }

  void _validatePhone() {
    final phone = _phoneController.text;
    final isValid = RegExp(r'^010[0-9]{8}$').hasMatch(phone);
    setState(() {
      _phoneError = isValid ? '' : '전화번호 형식이 올바르지 않습니다. (010 + 8자리)';
    });
  }

  void _validatePassword() {
    final pw = _passwordController.text;
    setState(() {
      if (pw.isEmpty) {
        _passwordError = '기존 비밀번호를 입력해주세요.';
      } else if (pw.length < 8) {
        _passwordError = '비밀번호는 8자리 이상이어야 합니다.';
      } else {
        _passwordError = '';
      }
    });
  }

  void _validateNewPassword() {
    final pw = _newPasswordController.text;
    setState(() {
      if (pw.isEmpty) {
        _newPasswordError = '새 비밀번호를 입력해주세요.';
      } else if (pw.length < 8) {
        _newPasswordError = '비밀번호는 8자리 이상이어야 합니다.';
      } else {
        _newPasswordError = '';
      }
    });
  }

  Future<void> _save() async {
    if (_hasError || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final token = await StorageService.getAccessToken();
      if (token == null) {
        if (mounted) context.go('/login');
        return;
      }
      await AccountApi.updateAccountInfo(
        accessToken: token,
        name: _nameController.text,
        phoneNumber: _phoneController.text,
        password: _passwordController.text,
        newPassword: _newPasswordController.text,
      );
      await StorageService.clear();
      if (mounted) context.go('/login');
    } on ApiException catch (e) {
      if (e.statusCode == 400 || e.statusCode == 401) {
        setState(() => _passwordError = '기존 비밀번호가 틀렸습니다.');
      } else {
        setState(() => _passwordError = e.message);
      }
    } catch (e) {
      setState(() => _passwordError = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    await StorageService.clear();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
        child: Column(
          children: [
            // 폼 카드
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildField(
                    label: '이름',
                    controller: _nameController,
                    errorText: _nameError,
                  ),
                  _buildDivider(),
                  _buildField(
                    label: '전화번호(ID)',
                    controller: _phoneController,
                    errorText: _phoneError,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildDivider(),
                  _buildField(
                    label: '기존 비밀번호',
                    controller: _passwordController,
                    errorText: _passwordError,
                    obscureText: true,
                  ),
                  _buildDivider(),
                  _buildField(
                    label: '새 비밀번호',
                    controller: _newPasswordController,
                    errorText: _newPasswordError,
                    obscureText: true,
                  ),
                  _buildDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      '계정 가입일: 24.08.02',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionButton(
                  label: '저장',
                  onTap: _hasError || _isSaving ? null : _save,
                  isLoading: _isSaving,
                ),
                const SizedBox(width: 16),
                _ActionButton(
                  label: '로그아웃',
                  onTap: _logout,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String errorText,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 110,
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          if (errorText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 110),
              child: Text(
                errorText,
                style: const TextStyle(color: _hpRed, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 0.5, color: Color(0xFF9CA3AF), indent: 16, endIndent: 16);
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const _ActionButton({required this.label, this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: disabled ? Colors.grey.shade300 : Colors.black),
          borderRadius: BorderRadius.circular(8),
        ),
        child: isLoading
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, size: 18, color: disabled ? Colors.grey : Colors.black),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(color: disabled ? Colors.grey : Colors.black, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
      ),
    );
  }
}
