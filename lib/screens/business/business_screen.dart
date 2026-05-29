import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/referral_model.dart';
import '../../data/services/api_service.dart';
import '../../widgets/app_widgets.dart';
import '../group/group_detail_screen.dart';

class BusinessScreen extends StatefulWidget {
  const BusinessScreen({super.key});

  @override
  State<BusinessScreen> createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  List<BusinessModel> _businesses = [];
  bool _loading = true;
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 &&
        _hasMore && !_loadingMore) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _page = 1;
      _businesses = [];
      _hasMore = true;
    });
    try {
      final res = await ApiService.getBusinesses(page: 1);
      final data = res['data'];
      final items = (data['data'] as List).map((e) => BusinessModel.fromJson(e)).toList();
      final meta = data['meta'] as Map<String, dynamic>?;
      setState(() {
        _businesses = items;
        _page = 1;
        _hasMore = meta != null ? (meta['current_page'] < meta['last_page']) : false;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final res = await ApiService.getBusinesses(page: _page + 1);
      final data = res['data'];
      final items = (data['data'] as List).map((e) => BusinessModel.fromJson(e)).toList();
      final meta = data['meta'] as Map<String, dynamic>?;
      setState(() {
        _businesses.addAll(items);
        _page++;
        _hasMore = meta != null ? (meta['current_page'] < meta['last_page']) : false;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Bisnis')),
      body: _loading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 6,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ShimmerLoading(height: 110, borderRadius: BorderRadius.circular(16)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: _businesses.isEmpty
                  ? const CustomScrollView(
                      slivers: [
                        SliverFillRemaining(
                          child: EmptyState(
                            title: 'Belum ada bisnis',
                            subtitle: 'Bisnis yang tersedia untuk investasi akan tampil di sini',
                            icon: Icons.business_outlined,
                          ),
                        ),
                      ],
                    )
                  : CustomScrollView(
                      controller: _scrollCtrl,
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: GradientCard(
                              colors: const [AppColors.primary, AppColors.primaryLight],
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.business_center_rounded, color: Colors.white, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Peluang Investasi',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                                        ),
                                        Text(
                                          '${_businesses.where((b) => b.isOpen).length} bisnis tersedia',
                                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) {
                                if (i == _businesses.length) {
                                  return _loadingMore
                                      ? const Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Center(child: CircularProgressIndicator()),
                                        )
                                      : const SizedBox.shrink();
                                }
                                final biz = _businesses[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildBusinessCard(biz),
                                );
                              },
                              childCount: _businesses.length + (_hasMore ? 1 : 0),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }

  Widget _buildBusinessCard(BusinessModel biz) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GroupDetailScreen(businessId: biz.id, businessName: biz.name),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image header
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: biz.imageUrl != null && biz.imageUrl!.isNotEmpty
                  ? Image.network(
                      biz.imageUrl!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(biz.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            const SizedBox(height: 2),
                            Text(biz.category, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (biz.isOpen ? AppColors.success : AppColors.textHint).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          biz.isOpen ? 'Terbuka' : 'Penuh',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: biz.isOpen ? AppColors.success : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.people_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${biz.currentInvestors} / ${biz.targetInvestors} investor',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      Text(
                        '${(biz.investorProgress * 100).toStringAsFixed(0)}% terisi',
                        style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: biz.investorProgress,
                      backgroundColor: AppColors.divider,
                      color: biz.isOpen ? AppColors.primary : AppColors.textHint,
                      minHeight: 6,
                    ),
                  ),
                  if (biz.isOpen) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupDetailScreen(businessId: biz.id, businessName: biz.name),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Investasi Sekarang', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.business_rounded, color: Colors.white54, size: 48),
      ),
    );
  }
}
