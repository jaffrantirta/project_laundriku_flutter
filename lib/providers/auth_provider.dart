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
  BalanceModel? _balance;
  String? _referralCode;
  bool _isLoading = false;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  BalanceModel? get balance => _balance;
  String? get referralCode => _referralCode;
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
      final res = await ApiService.getProfile();
      final data = res['data'] ?? res;
      _user = UserModel.fromJson(data is Map ? data['user'] ?? data : data);
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
    String? phone,
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
        phone: phone,
        referralCode: referralCode,
      );
      final data = res['data'];
      _user = UserModel.fromJson(data['user']);
      final token = data['token'] as String;
      _referralCode = data['referral_code'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, token);
      await prefs.setString(AppConstants.userKey, jsonEncode(_user!.toJson()));
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return {'success': true, 'data': data};
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
    _balance = null;
    _referralCode = null;
    notifyListeners();
  }

  Future<void> loadBalance() async {
    try {
      final res = await ApiService.getBalance();
      _balance = BalanceModel.fromJson(res);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadReferralCode() async {
    try {
      final res = await ApiService.getReferralCode();
      final data = res['data'] ?? res;
      _referralCode = data['referral_code'];
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshUser() async {
    try {
      final res = await ApiService.getProfile();
      final data = res['data'] ?? res;
      _user = UserModel.fromJson(data is Map ? data['user'] ?? data : data);
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
