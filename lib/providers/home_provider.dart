import 'package:flutter/foundation.dart';
import '../data/models/bonus_model.dart';
import '../data/models/leaderboard_model.dart';
import '../data/models/referral_model.dart';
import '../data/services/api_service.dart';

class HomeProvider extends ChangeNotifier {
  BonusSummaryModel? _bonusSummary;
  ReferralSummaryModel? _referralSummary;
  List<LeaderboardModel> _topLeaderboard = [];
  bool _isLoading = false;

  BonusSummaryModel? get bonusSummary => _bonusSummary;
  ReferralSummaryModel? get referralSummary => _referralSummary;
  List<LeaderboardModel> get topLeaderboard => _topLeaderboard;
  bool get isLoading => _isLoading;

  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();
    await Future.wait([
      _loadBonusSummary(),
      _loadReferralSummary(),
      _loadLeaderboard(),
    ]);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadBonusSummary() async {
    try {
      final res = await ApiService.getBonusSummary();
      _bonusSummary = BonusSummaryModel.fromJson(res['data']);
    } catch (_) {}
  }

  Future<void> _loadReferralSummary() async {
    try {
      final res = await ApiService.getReferralSummary();
      _referralSummary = ReferralSummaryModel.fromJson(res['data']);
    } catch (_) {}
  }

  Future<void> _loadLeaderboard() async {
    try {
      final res = await ApiService.getLeaderboard(perPage: 3);
      final list = res['data']['leaderboard'] as List<dynamic>;
      _topLeaderboard = list.map((e) => LeaderboardModel.fromJson(e)).toList();
    } catch (_) {}
  }
}
