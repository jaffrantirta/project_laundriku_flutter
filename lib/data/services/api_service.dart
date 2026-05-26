import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => message;
}

class ApiService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  static Map<String, String> _headers({bool auth = true, bool json = true}) {
    return {
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  static Future<Map<String, String>> _authHeaders({bool json = true}) async {
    final token = await _getToken();
    return {
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _parseResponse(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    final message = body['message'] ?? 'Terjadi kesalahan';
    final errors = body['errors'];
    throw ApiException(message, statusCode: response.statusCode, errors: errors);
  }

  // Auth
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${AppConstants.apiUrl}/login'),
      headers: _headers(auth: false),
      body: jsonEncode({
        'email': email,
        'password': password,
        'device_name': AppConstants.deviceName,
      }),
    );
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? referralCode,
  }) async {
    final body = {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'device_name': AppConstants.deviceName,
      if (referralCode != null && referralCode.isNotEmpty) 'referral_code': referralCode,
    };
    final response = await http.post(
      Uri.parse('${AppConstants.apiUrl}/register'),
      headers: _headers(auth: false),
      body: jsonEncode(body),
    );
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> resendVerification(String email) async {
    final response = await http.post(
      Uri.parse('${AppConstants.apiUrl}/resend-verification'),
      headers: _headers(auth: false),
      body: jsonEncode({'email': email}),
    );
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> logout() async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('${AppConstants.apiUrl}/logout'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  // User
  static Future<Map<String, dynamic>> getUser() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${AppConstants.apiUrl}/user'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> getWallet() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${AppConstants.apiUrl}/wallet'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  // Identity
  static Future<Map<String, dynamic>> getIdentityStatus() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${AppConstants.apiUrl}/identity-status'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> submitIdentity({
    required String name,
    required String phone,
    required String nik,
    required String address,
    required String province,
    required String district,
    required String subDistrict,
    required String occupation,
    required String position,
    required File ktpPhoto,
    required File selfiePhoto,
  }) async {
    final token = await _getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConstants.apiUrl}/identity'),
    );
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    request.fields.addAll({
      'name': name,
      'phone': phone,
      'nik': nik,
      'address': address,
      'province': province,
      'district': district,
      'sub_district': subDistrict,
      'occupation': occupation,
      'position': position,
    });
    request.files.add(await http.MultipartFile.fromPath('ktp_photo', ktpPhoto.path));
    request.files.add(await http.MultipartFile.fromPath('selfie_photo', selfiePhoto.path));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _parseResponse(response);
  }

  // Bonuses
  static Future<Map<String, dynamic>> getBonuses({int page = 1, int perPage = 15}) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${AppConstants.apiUrl}/bonuses?page=$page&per_page=$perPage'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> getBonusSummary() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${AppConstants.apiUrl}/bonuses/summary'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  // Payments
  static Future<Map<String, dynamic>> getPayments({
    int page = 1,
    int perPage = 15,
    int? status,
    int? type,
    String? paymentType,
    String order = 'desc',
  }) async {
    final headers = await _authHeaders();
    final params = {
      'page': '$page',
      'per_page': '$perPage',
      'order': order,
      if (status != null) 'status': '$status',
      if (type != null) 'type': '$type',
      if (paymentType != null) 'payment_type': paymentType,
    };
    final uri = Uri.parse('${AppConstants.apiUrl}/payments').replace(queryParameters: params);
    final response = await http.get(uri, headers: headers);
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> getPaymentDetail(String orderId) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${AppConstants.apiUrl}/payments/$orderId'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> getTopupConfig() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${AppConstants.apiUrl}/payments/topup-config'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> createTopup(int amount) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('${AppConstants.apiUrl}/payments/topup'),
      headers: headers,
      body: jsonEncode({'amount': amount}),
    );
    return _parseResponse(response);
  }

  // Withdrawals
  static Future<Map<String, dynamic>> getWithdrawals({
    int page = 1,
    int perPage = 15,
    int? status,
    String order = 'desc',
  }) async {
    final headers = await _authHeaders();
    final params = {
      'page': '$page',
      'per_page': '$perPage',
      'order': order,
      if (status != null) 'status': '$status',
    };
    final uri = Uri.parse('${AppConstants.apiUrl}/withdrawals').replace(queryParameters: params);
    final response = await http.get(uri, headers: headers);
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> getWithdrawalConfig() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${AppConstants.apiUrl}/withdrawals/config'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> createWithdrawal(int amount) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('${AppConstants.apiUrl}/withdrawals'),
      headers: headers,
      body: jsonEncode({'amount': amount}),
    );
    return _parseResponse(response);
  }

  // Referrals
  static Future<Map<String, dynamic>> getReferrals({
    int page = 1,
    int perPage = 15,
    String? name,
    String order = 'desc',
  }) async {
    final headers = await _authHeaders();
    final params = {
      'page': '$page',
      'per_page': '$perPage',
      'order': order,
      if (name != null && name.isNotEmpty) 'name': name,
    };
    final uri = Uri.parse('${AppConstants.apiUrl}/referrals').replace(queryParameters: params);
    final response = await http.get(uri, headers: headers);
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> getReferralSummary() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${AppConstants.apiUrl}/referrals/summary'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  // Groups
  static Future<Map<String, dynamic>> getGroups({
    int page = 1,
    int perPage = 15,
    String? name,
  }) async {
    final headers = await _authHeaders();
    final params = {
      'page': '$page',
      'per_page': '$perPage',
      if (name != null && name.isNotEmpty) 'name': name,
    };
    final uri = Uri.parse('${AppConstants.apiUrl}/groups').replace(queryParameters: params);
    final response = await http.get(uri, headers: headers);
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> getGroupDetail(int id) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${AppConstants.apiUrl}/groups/$id'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  // Leaderboard
  static Future<Map<String, dynamic>> getLeaderboard({
    String? month,
    int page = 1,
    int perPage = 20,
    String order = 'asc',
  }) async {
    final headers = await _authHeaders();
    final params = {
      'page': '$page',
      'per_page': '$perPage',
      'order': order,
      if (month != null) 'month': month,
    };
    final uri = Uri.parse('${AppConstants.apiUrl}/leaderboard').replace(queryParameters: params);
    final response = await http.get(uri, headers: headers);
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> getLeaderboardMonths() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${AppConstants.apiUrl}/leaderboard/months'),
      headers: headers,
    );
    return _parseResponse(response);
  }
}
