import 'package:flutter/foundation.dart';
import '../data/models/referral_model.dart';
import '../data/services/api_service.dart';

class HomeProvider extends ChangeNotifier {
  ReferralCodeModel? _referralInfo;
  List<BusinessModel> _topBusinesses = [];
  bool _isLoading = false;

  ReferralCodeModel? get referralInfo => _referralInfo;
  List<BusinessModel> get topBusinesses => _topBusinesses;
  bool get isLoading => _isLoading;

  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();
    await Future.wait([
      _loadReferralInfo(),
      _loadTopBusinesses(),
    ]);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadReferralInfo() async {
    try {
      final res = await ApiService.getReferralCode();
      _referralInfo = ReferralCodeModel.fromJson(res);
    } catch (_) {}
  }

  Future<void> _loadTopBusinesses() async {
    try {
      final res = await ApiService.getBusinesses(perPage: 3);
      final data = res['data'];
      final list = (data['data'] as List<dynamic>? ?? [])
          .map((e) => BusinessModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _topBusinesses = list.take(3).toList();
    } catch (_) {}
  }
}
