import 'package:flutter/foundation.dart';
import '../data/models/bonus_model.dart';
import '../data/models/payment_model.dart';
import '../data/models/withdrawal_model.dart';
import '../data/services/api_service.dart';

class TransactionProvider extends ChangeNotifier {
  // Payments
  List<PaymentModel> _payments = [];
  PaginationModel? _paymentPagination;
  bool _paymentsLoading = false;
  int? _paymentStatusFilter;
  int? _paymentTypeFilter;

  // Withdrawals
  List<WithdrawalModel> _withdrawals = [];
  PaginationModel? _withdrawalPagination;
  bool _withdrawalsLoading = false;
  int? _withdrawalStatusFilter;

  // Bonuses
  List<BonusModel> _bonuses = [];
  PaginationModel? _bonusPagination;
  bool _bonusesLoading = false;
  int _bonusTotal = 0;

  // Getters
  List<PaymentModel> get payments => _payments;
  PaginationModel? get paymentPagination => _paymentPagination;
  bool get paymentsLoading => _paymentsLoading;
  int? get paymentStatusFilter => _paymentStatusFilter;
  int? get paymentTypeFilter => _paymentTypeFilter;

  List<WithdrawalModel> get withdrawals => _withdrawals;
  PaginationModel? get withdrawalPagination => _withdrawalPagination;
  bool get withdrawalsLoading => _withdrawalsLoading;
  int? get withdrawalStatusFilter => _withdrawalStatusFilter;

  List<BonusModel> get bonuses => _bonuses;
  PaginationModel? get bonusPagination => _bonusPagination;
  bool get bonusesLoading => _bonusesLoading;
  int get bonusTotal => _bonusTotal;

  Future<void> loadPayments({bool refresh = false}) async {
    if (_paymentsLoading) return;
    if (refresh) _payments = [];
    _paymentsLoading = true;
    notifyListeners();
    try {
      final page = refresh ? 1 : (_paymentPagination?.currentPage ?? 0) + 1;
      final res = await ApiService.getPayments(
        page: page,
        status: _paymentStatusFilter,
        type: _paymentTypeFilter,
      );
      final data = res['data'];
      final list = (data['payments'] as List).map((e) => PaymentModel.fromJson(e)).toList();
      if (refresh) {
        _payments = list;
      } else {
        _payments.addAll(list);
      }
      _paymentPagination = PaginationModel.fromJson(data['pagination']);
    } catch (_) {}
    _paymentsLoading = false;
    notifyListeners();
  }

  void setPaymentFilter({int? status, int? type}) {
    _paymentStatusFilter = status;
    _paymentTypeFilter = type;
    loadPayments(refresh: true);
  }

  Future<void> loadWithdrawals({bool refresh = false}) async {
    if (_withdrawalsLoading) return;
    if (refresh) _withdrawals = [];
    _withdrawalsLoading = true;
    notifyListeners();
    try {
      final page = refresh ? 1 : (_withdrawalPagination?.currentPage ?? 0) + 1;
      final res = await ApiService.getWithdrawals(
        page: page,
        status: _withdrawalStatusFilter,
      );
      final data = res['data'];
      final list = (data['withdrawals'] as List).map((e) => WithdrawalModel.fromJson(e)).toList();
      if (refresh) {
        _withdrawals = list;
      } else {
        _withdrawals.addAll(list);
      }
      _withdrawalPagination = PaginationModel.fromJson(data['pagination']);
    } catch (_) {}
    _withdrawalsLoading = false;
    notifyListeners();
  }

  void setWithdrawalFilter(int? status) {
    _withdrawalStatusFilter = status;
    loadWithdrawals(refresh: true);
  }

  Future<void> loadBonuses({bool refresh = false}) async {
    if (_bonusesLoading) return;
    if (refresh) _bonuses = [];
    _bonusesLoading = true;
    notifyListeners();
    try {
      final page = refresh ? 1 : (_bonusPagination?.currentPage ?? 0) + 1;
      final res = await ApiService.getBonuses(page: page);
      final data = res['data'];
      final list = (data['bonuses'] as List).map((e) => BonusModel.fromJson(e)).toList();
      if (refresh) {
        _bonuses = list;
      } else {
        _bonuses.addAll(list);
      }
      _bonusPagination = PaginationModel.fromJson(data['pagination']);
      _bonusTotal = data['total_bonus'] ?? 0;
    } catch (_) {}
    _bonusesLoading = false;
    notifyListeners();
  }
}
