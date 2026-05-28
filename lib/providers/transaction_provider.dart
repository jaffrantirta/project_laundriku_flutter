import 'package:flutter/foundation.dart';
import '../data/models/bonus_model.dart';
import '../data/models/payment_model.dart';
import '../data/models/referral_model.dart';
import '../data/models/withdrawal_model.dart';
import '../data/services/api_service.dart';

class TransactionProvider extends ChangeNotifier {
  // Payments
  List<TransactionModel> _payments = [];
  PaginationModel? _paymentPagination;
  bool _paymentsLoading = false;

  // Withdrawals
  List<WithdrawalModel> _withdrawals = [];
  PaginationModel? _withdrawalPagination;
  bool _withdrawalsLoading = false;

  // Referral rewards
  List<ReferralRewardModel> _rewards = [];
  PaginationModel? _rewardPagination;
  bool _rewardsLoading = false;

  // Getters
  List<TransactionModel> get payments => _payments;
  PaginationModel? get paymentPagination => _paymentPagination;
  bool get paymentsLoading => _paymentsLoading;

  List<WithdrawalModel> get withdrawals => _withdrawals;
  PaginationModel? get withdrawalPagination => _withdrawalPagination;
  bool get withdrawalsLoading => _withdrawalsLoading;

  List<ReferralRewardModel> get rewards => _rewards;
  PaginationModel? get rewardPagination => _rewardPagination;
  bool get rewardsLoading => _rewardsLoading;

  Future<void> loadPayments({bool refresh = false}) async {
    if (_paymentsLoading) return;
    if (refresh) _payments = [];
    _paymentsLoading = true;
    notifyListeners();
    try {
      final page = refresh ? 1 : (_paymentPagination?.currentPage ?? 0) + 1;
      final res = await ApiService.getPaymentHistory(page: page);
      final data = res['data'];
      final list = (data['data'] as List<dynamic>? ?? [])
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (refresh) {
        _payments = list;
      } else {
        _payments.addAll(list);
      }
      _paymentPagination = PaginationModel(
        currentPage: data['current_page'] ?? 1,
        lastPage: data['last_page'] ?? 1,
        perPage: data['per_page'] ?? 15,
        total: data['total'] ?? 0,
      );
    } catch (_) {}
    _paymentsLoading = false;
    notifyListeners();
  }

  Future<void> loadWithdrawals({bool refresh = false}) async {
    if (_withdrawalsLoading) return;
    if (refresh) _withdrawals = [];
    _withdrawalsLoading = true;
    notifyListeners();
    try {
      final page = refresh ? 1 : (_withdrawalPagination?.currentPage ?? 0) + 1;
      final res = await ApiService.getWithdrawalHistory(page: page);
      final data = res['data'];
      final list = (data['data'] as List<dynamic>? ?? [])
          .map((e) => WithdrawalModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (refresh) {
        _withdrawals = list;
      } else {
        _withdrawals.addAll(list);
      }
      _withdrawalPagination = PaginationModel(
        currentPage: data['current_page'] ?? 1,
        lastPage: data['last_page'] ?? 1,
        perPage: data['per_page'] ?? 15,
        total: data['total'] ?? 0,
      );
    } catch (_) {}
    _withdrawalsLoading = false;
    notifyListeners();
  }

  Future<void> loadRewards({bool refresh = false}) async {
    if (_rewardsLoading) return;
    if (refresh) _rewards = [];
    _rewardsLoading = true;
    notifyListeners();
    try {
      final page = refresh ? 1 : (_rewardPagination?.currentPage ?? 0) + 1;
      final res = await ApiService.getReferralRewards(page: page);
      final data = res['data'];
      final list = (data['data'] as List<dynamic>? ?? [])
          .map((e) => ReferralRewardModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (refresh) {
        _rewards = list;
      } else {
        _rewards.addAll(list);
      }
      _rewardPagination = PaginationModel(
        currentPage: data['current_page'] ?? 1,
        lastPage: data['last_page'] ?? 1,
        perPage: data['per_page'] ?? 15,
        total: data['total'] ?? 0,
      );
    } catch (_) {}
    _rewardsLoading = false;
    notifyListeners();
  }
}
