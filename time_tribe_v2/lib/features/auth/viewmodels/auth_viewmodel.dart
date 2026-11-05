import 'package:flutter/material.dart';

/// Mã lỗi xác thực; câu chữ hiển thị nằm ở giao diện (đa ngôn ngữ).
enum AuthError {
  identifierRequired,
  passwordRequired,
  wrongCredentials,
  nameRequired,
  emailRequired,
  createPasswordRequired,
  passwordMismatch,
}

class AuthViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AuthError? _identifierError; // Email hoặc Username
  AuthError? _passwordError;
  AuthError? _nameError;
  AuthError? _confirmPasswordError;

  AuthError? get emailError => _identifierError;
  AuthError? get passwordError => _passwordError;
  AuthError? get nameError => _nameError;
  AuthError? get confirmPasswordError => _confirmPasswordError;

  bool _rememberMe = true;
  bool get rememberMe => _rememberMe;

  void toggleRememberMe() {
    _rememberMe = !_rememberMe;
    notifyListeners();
  }

  void _clearErrors() {
    _identifierError = null;
    _passwordError = null;
    _nameError = null;
    _confirmPasswordError = null;
  }

  /// Đăng nhập bằng email hoặc tên người dùng.
  /// Tài khoản mẫu: admin / admin@timetribe.com, mật khẩu 123456.
  Future<bool> login(String emailOrUsername, String password) async {
    _clearErrors();
    if (emailOrUsername.trim().isEmpty) {
      _identifierError = AuthError.identifierRequired;
    }
    if (password.trim().isEmpty) _passwordError = AuthError.passwordRequired;
    if (_identifierError != null || _passwordError != null) {
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();
    await Future.delayed(
      const Duration(seconds: 1),
    ); // TODO(backend): POST /auth/login

    final id = emailOrUsername.trim();
    final ok =
        (id == 'admin' || id == 'admin@timetribe.com') && password == '123456';
    _isLoading = false;
    if (!ok) {
      // Gom chung lỗi tài khoản/mật khẩu để tránh bị dò tài khoản
      _passwordError = AuthError.wrongCredentials;
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }

  Future<bool> register(
    String name,
    String email,
    String password,
    String confirm,
  ) async {
    _clearErrors();
    if (name.trim().isEmpty) _nameError = AuthError.nameRequired;
    if (email.trim().isEmpty) _identifierError = AuthError.emailRequired;
    if (password.trim().isEmpty) {
      _passwordError = AuthError.createPasswordRequired;
    }
    if (confirm != password) _confirmPasswordError = AuthError.passwordMismatch;
    if (_nameError != null ||
        _identifierError != null ||
        _passwordError != null ||
        _confirmPasswordError != null) {
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();
    await Future.delayed(
      const Duration(seconds: 1),
    ); // TODO(backend): POST /auth/register
    _isLoading = false;
    notifyListeners();
    return true;
  }

  void logout() {
    _clearErrors();
    // TODO(backend): xoá refresh token (user_tokens)
    notifyListeners();
  }

  /// Xoá tài khoản: ghi `user_securities.delete_at` + `delete_reason`.
  Future<void> deleteAccount(String reason) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(
      const Duration(milliseconds: 800),
    ); // TODO(backend): DELETE /users/me { reason }
    _isLoading = false;
    _clearErrors();
    notifyListeners();
  }
}
