// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  String? get error => _error;

  final DatabaseService _db = DatabaseService();

  Future<void> tryAutoLogin() async {
    final user = await _db.getSessionUser();
    if (user != null) {
      _currentUser = user;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _db.login(username, password);
      if (user != null) {
        _currentUser = user;
        await _db.saveSession(user.id!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Tên đăng nhập hoặc mật khẩu không đúng';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Đã xảy ra lỗi. Vui lòng thử lại.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (await _db.usernameExists(username)) {
        _error = 'Tên người dùng đã tồn tại';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      if (await _db.emailExists(email)) {
        _error = 'Email đã được sử dụng';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final success = await _db.register(username, email, password);
      if (success) {
        await login(username, password);
        return true;
      }
      _error = 'Đăng ký thất bại. Vui lòng thử lại.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Đã xảy ra lỗi. Vui lòng thử lại.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await _db.clearSession();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}