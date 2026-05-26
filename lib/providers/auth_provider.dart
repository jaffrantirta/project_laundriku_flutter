import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../data/models/user_model.dart';
import '../data/services/api_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  WalletModel? _wallet;
  bool _isLoading = false;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  WalletModel? get wallet => _wallet;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    if (token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    final userData = prefs.getString(AppConstants.userKey);
    if (userData != null) {
      _user = UserModel.fromJson(jsonDecode(userData));
    }
    try {
      final res = await ApiService.getUser();
      _user = UserModel.fromJson(res['data']);
      await prefs.setString(AppConstants.userKey, jsonEncode(_user!.toJson()));
      _status = AuthStatus.authenticated;
    } catch (_) {
      await _clearSession(prefs);
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiService.login(email, password);
      final data = res['data'];
      _user = UserModel.fromJson(data['user']);
      final token = data['token'] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, token);
      await prefs.setString(AppConstants.userKey, jsonEncode(_user!.toJson()));
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? referralCode,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        referralCode: referralCode,
      );
      _isLoading = false;
      notifyListeners();
      return {'success': true, 'data': res['data']};
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await _clearSession(prefs);
    _status = AuthStatus.unauthenticated;
    _user = null;
    _wallet = null;
    notifyListeners();
  }

  Future<void> loadWallet() async {
    try {
      final res = await ApiService.getWallet();
      _wallet = WalletModel.fromJson(res['data']);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshUser() async {
    try {
      final res = await ApiService.getUser();
      _user = UserModel.fromJson(res['data']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userKey, jsonEncode(_user!.toJson()));
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _clearSession(SharedPreferences prefs) async {
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
