import 'package:flutter/foundation.dart';
import '../data/models/bonus_model.dart';
import '../data/models/referral_model.dart';
import '../data/services/api_service.dart';

class ReferralProvider extends ChangeNotifier {
  ReferralCodeModel? _codeInfo;
  ReferralTreeModel? _tree;
  bool _isLoading = false;
  bool _isCodeLoading = false;
  String _searchQuery = '';

  List<BusinessModel> _businesses = [];
  PaginationModel? _businessPagination;
  bool _businessesLoading = false;

  ReferralCodeModel? get codeInfo => _codeInfo;
  ReferralTreeModel? get tree => _tree;
  bool get isLoading => _isLoading;
  bool get isCodeLoading => _isCodeLoading;
  String get searchQuery => _searchQuery;

  List<BusinessModel> get businesses => _businesses;
  PaginationModel? get businessPagination => _businessPagination;
  bool get businessesLoading => _businessesLoading;

  List<ReferralTreeMemberModel> get filteredLevel1 {
    if (_searchQuery.isEmpty) return _tree?.level1 ?? [];
    return (_tree?.level1 ?? [])
        .where((m) => m.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> loadCodeInfo() async {
    _isCodeLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.getReferralCode();
      _codeInfo = ReferralCodeModel.fromJson(res);
    } catch (_) {}
    _isCodeLoading = false;
    notifyListeners();
  }

  Future<void> loadTree({bool refresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.getReferralTree();
      _tree = ReferralTreeModel.fromJson(res);
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadBusinesses({bool refresh = false}) async {
    if (_businessesLoading) return;
    if (refresh) _businesses = [];
    _businessesLoading = true;
    notifyListeners();
    try {
      final page = refresh ? 1 : (_businessPagination?.currentPage ?? 0) + 1;
      final res = await ApiService.getBusinesses(page: page);
      final data = res['data'];
      final list = (data['data'] as List<dynamic>? ?? [])
          .map((e) => BusinessModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (refresh) {
        _businesses = list;
      } else {
        _businesses.addAll(list);
      }
      _businessPagination = PaginationModel(
        currentPage: data['current_page'] ?? 1,
        lastPage: data['last_page'] ?? 1,
        perPage: data['per_page'] ?? 15,
        total: data['total'] ?? 0,
      );
    } catch (_) {}
    _businessesLoading = false;
    notifyListeners();
  }
}
