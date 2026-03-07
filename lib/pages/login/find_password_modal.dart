import 'package:flutter/material.dart';
import 'package:haanppen_mobile/apis/auth_api.dart';
import 'package:haanppen_mobile/services/api_client.dart';

class FindPasswordModal extends StatefulWidget {
  const FindPasswordModal({super.key});

  @override
  State<FindPasswordModal> createState() => _FindPasswordModalState();
}

class _FindPasswordModalState extends State<FindPasswordModal> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isCodeSent = false;
  bool _isLoading = false;
  String _errorMessage = '';
  String _phoneErrorMessage = '';

  static const _hpBlue = Color(0xFF2563EB);

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool _isValidPhone(String value) => RegExp(r'^\d+$').hasMatch(value);

  void _onPhoneChanged(String value) {
    setState(() {
      _phoneErrorMessage =
          value.isNotEmpty && !_isValidPhone(value) ? '전화번호는 숫자만 입력할 수 있습니다.' : '';
    });
  }

  Future<void> _handleSendCode() async {
    if (!_isValidPhone(_phoneController.text) || _phoneController.text.isEmpty) {
      setState(() => _errorMessage = '유효한 전화번호를 입력하세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await AuthApi.sendPasswordResetCode(phoneNumber: _phoneController.text);
      setState(() => _isCodeSent = true);
      setState(() => _errorMessage = '인증 코드가 전송되었습니다.');
    } on ApiException catch (e) {
      setState(() => _errorMessage =
          e.statusCode >= 500 ? '서버 오류가 발생했습니다. 잠시 후 다시 시도하세요.' : '존재하지 않는 사용자입니다.');
    } catch (_) {
      setState(() => _errorMessage = '오류가 발생했습니다. 다시 시도하세요.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final newPassword = await AuthApi.verifyPasswordCode(
        phoneNumber: _phoneController.text,
        code: _codeController.text,
      );
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('비밀번호 찾기 완료'),
            content: Text('재설정 비밀번호: $newPassword\n화면을 캡처하세요.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } on ApiException {
      setState(() => _errorMessage = '인증 코드가 잘못되었습니다. 다시 시도하세요.');
    } catch (_) {
      setState(() => _errorMessage = '오류가 발생했습니다. 다시 시도하세요.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: SizedBox(
        width: 330,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Text(
                '비밀번호 찾기',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox(
                    width: 110,
                    child: Text(
                      '학생 연락처(ID)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.number,
                      enabled: !_isCodeSent,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: '숫자만 입력해주세요.',
                        hintStyle: const TextStyle(fontSize: 12),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onChanged: _onPhoneChanged,
                    ),
                  ),
                ],
              ),
              if (_phoneErrorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _phoneErrorMessage,
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              if (_isCodeSent) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    hintText: '인증 코드 입력',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : (_isCodeSent ? _handleVerifyCode : _handleSendCode),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCodeSent ? Colors.green : _hpBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _isCodeSent ? '인증 코드 확인' : '인증 코드 전송',
                        style: const TextStyle(color: Colors.white),
                      ),
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(
                      color: _isCodeSent && _errorMessage.contains('전송')
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
