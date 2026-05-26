import 'package:flutter/foundation.dart';
import '../data/models/bonus_model.dart';
import '../data/models/referral_model.dart';
import '../data/services/api_service.dart';

class ReferralProvider extends ChangeNotifier {
  ReferralSummaryModel? _summary;
  List<ReferralModel> _referrals = [];
  PaginationModel? _pagination;
  bool _isLoading = false;
  bool _isSummaryLoading = false;
  String _searchQuery = '';

  List<GroupModel> _groups = [];
  PaginationModel? _groupPagination;
  bool _groupsLoading = false;

  ReferralSummaryModel? get summary => _summary;
  List<ReferralModel> get referrals => _referrals;
  PaginationModel? get pagination => _pagination;
  bool get isLoading => _isLoading;
  bool get isSummaryLoading => _isSummaryLoading;
  String get searchQuery => _searchQuery;

  List<GroupModel> get groups => _groups;
  PaginationModel? get groupPagination => _groupPagination;
  bool get groupsLoading => _groupsLoading;

  Future<void> loadSummary() async {
    _isSummaryLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.getReferralSummary();
      _summary = ReferralSummaryModel.fromJson(res['data']);
    } catch (_) {}
    _isSummaryLoading = false;
    notifyListeners();
  }

  Future<void> loadReferrals({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) _referrals = [];
    _isLoading = true;
    notifyListeners();
    try {
      final page = refresh ? 1 : (_pagination?.currentPage ?? 0) + 1;
      final res = await ApiService.getReferrals(
        page: page,
        name: _searchQuery.isEmpty ? null : _searchQuery,
      );
      final data = res['data'];
      final list = (data['referrals'] as List).map((e) => ReferralModel.fromJson(e)).toList();
      if (refresh) {
        _referrals = list;
      } else {
        _referrals.addAll(list);
      }
      _pagination = PaginationModel.fromJson(data['pagination']);
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    loadReferrals(refresh: true);
  }

  Future<void> loadGroups({bool refresh = false}) async {
    if (_groupsLoading) return;
    if (refresh) _groups = [];
    _groupsLoading = true;
    notifyListeners();
    try {
      final page = refresh ? 1 : (_groupPagination?.currentPage ?? 0) + 1;
      final res = await ApiService.getGroups(page: page);
      final data = res['data'];
      final list = (data['groups'] as List).map((e) => GroupModel.fromJson(e)).toList();
      if (refresh) {
        _groups = list;
      } else {
        _groups.addAll(list);
      }
      _groupPagination = PaginationModel.fromJson(data['pagination']);
    } catch (_) {}
    _groupsLoading = false;
    notifyListeners();
  }
}
