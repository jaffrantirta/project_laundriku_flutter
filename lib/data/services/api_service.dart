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

  static Map<String, String> _headers({bool json = true}) {
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
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    String? referralCode,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (referralCode != null && referralCode.isNotEmpty) 'referral_code': referralCode,
    };
    final response = await http.post(
      Uri.parse('${AppConstants.apiUrl}/register'),
      headers: _headers(),
      body: jsonEncode(body),
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

  // Profile
  static Future<Map<String, dynamic>> getProfile() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${AppConstants.apiUrl}/profile'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? password,
    String? passwordConfirmation,
  }) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (password != null) 'password': password,
      if (passwordConfirmation != null) 'password_confirmation': passwordConfirmation,
    };
    final response = await http.put(
      Uri.parse('${AppConstants.apiUrl}/profile'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _parseResponse(response);
  }

  // Balance
  static Future<Map<String, dynamic>> getBalance() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${AppConstants.apiUrl}/balance'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> getBalanceHistory({
    String? type,
    int page = 1,
    int perPage = 15,
  }) async {
    final headers = await _authHeaders();
    final params = {
      'page': '$page',
      'per_page': '$perPage',
      if (type != null) 'type': type,
    };
    final uri = Uri.parse('${AppConstants.apiUrl}/balance/history').replace(queryParameters: params);
    final response = await http.get(uri, headers: headers);
    return _parseResponse(response);
  }

  // Verification / Onboarding
  static Future<Map<String, dynamic>> getVerificationStatus() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${AppConstants.apiUrl}/verification/status'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> uploadVerification({
    required String idType,
    required String idNumber,
    required File idPhoto,
    File? selfiePhoto,
  }) async {
    final token = await _getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConstants.apiUrl}/verification/upload'),
    );
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    request.fields['id_type'] = idType;
    request.fields['id_number'] = idNumber;
    request.files.add(await http.MultipartFile.fromPath('id_photo', idPhoto.path));
    if (selfiePhoto != null) {
      request.files.add(await http.MultipartFile.fromPath('selfie_photo', selfiePhoto.path));
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> payInitialDeposit(String paymentMethod) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('${AppConstants.apiUrl}/initial-deposit/pay'),
      headers: headers,
      body: jsonEncode({'payment_method': paymentMethod}),
    );
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> uploadPaymentProof({
    required int transactionId,
    required File proofImage,
  }) async {
    final token = await _getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConstants.apiUrl}/payments/manual'),
    );
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    request.fields['transaction_id'] = transactionId.toString();
    request.files.add(await http.MultipartFile.fromPath('proof_image', proofImage.path));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _parseResponse(response);
  }

  // Businesses
  static Future<Map<String, dynamic>> getBusinesses({int perPage = 15, int page = 1}) async {
    final headers = await _authHeaders();
    final params = {'per_page': '$perPage', 'page': '$page'};
    final uri = Uri.parse('${AppConstants.apiUrl}/businesses').replace(queryParameters: params);
    final response = await http.get(uri, headers: headers);
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> getBusinessDetail(int id) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${AppConstants.apiUrl}/businesses/$id'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> investInBusiness({
    required int businessId,
    required String paymentType,
    int? tenureMonths,
    required String paymentMethod,
  }) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{
      'payment_type': paymentType,
      'payment_method': paymentMethod,
      if (tenureMonths != null) 'tenure_months': tenureMonths,
    };
    final response = await http.post(
      Uri.parse('${AppConstants.apiUrl}/businesses/$businessId/invest'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _parseResponse(response);
  }

  // Payments
  static Future<Map<String, dynamic>> getPaymentHistory({int page = 1, int perPage = 15, String? type}) async {
    final headers = await _authHeaders();
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (type != null) params['type'] = type;
    final uri = Uri.parse('${AppConstants.apiUrl}/payments/history').replace(queryParameters: params);
    final response = await http.get(uri, headers: headers);
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> getPaymentStatus(int transactionId) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${AppConstants.apiUrl}/payments/$transactionId/status'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> payInstallment({
    required int investmentId,
    required String paymentMethod,
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('${AppConstants.apiUrl}/payments/installment/$investmentId'),
      headers: headers,
      body: jsonEncode({'payment_method': paymentMethod}),
    );
    return _parseResponse(response);
  }

  // Withdrawals
  static Future<Map<String, dynamic>> getWithdrawalHistory({int page = 1, int perPage = 15}) async {
    final headers = await _authHeaders();
    final params = {'page': '$page', 'per_page': '$perPage'};
    final uri = Uri.parse('${AppConstants.apiUrl}/withdrawal/history').replace(queryParameters: params);
    final response = await http.get(uri, headers: headers);
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> requestWithdrawal({
    required int amount,
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('${AppConstants.apiUrl}/withdrawal/request'),
      headers: headers,
      body: jsonEncode({
        'amount': amount,
        'bank_name': bankName,
        'account_number': accountNumber,
        'account_name': accountName,
      }),
    );
    return _parseResponse(response);
  }

  // Referral
  static Future<Map<String, dynamic>> getReferralCode() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${AppConstants.apiUrl}/referral/code'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> getReferralTree() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${AppConstants.apiUrl}/referral/tree'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> getReferralRewards({int page = 1, int perPage = 15}) async {
    final headers = await _authHeaders();
    final params = {'page': '$page', 'per_page': '$perPage'};
    final uri = Uri.parse('${AppConstants.apiUrl}/referral/rewards').replace(queryParameters: params);
    final response = await http.get(uri, headers: headers);
    return _parseResponse(response);
  }

  // Notifications
  static Future<Map<String, dynamic>> getNotifications({int page = 1}) async {
    final headers = await _authHeaders();
    final params = {'page': '$page'};
    final uri = Uri.parse('${AppConstants.apiUrl}/notifications').replace(queryParameters: params);
    final response = await http.get(uri, headers: headers);
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> markNotificationRead(String id) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('${AppConstants.apiUrl}/notifications/$id/read'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> markAllNotificationsRead() async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('${AppConstants.apiUrl}/notifications/mark-all-read'),
      headers: headers,
    );
    return _parseResponse(response);
  }
}
