import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/referral_model.dart';
import '../../providers/referral_provider.dart';
import '../../widgets/app_widgets.dart';
import '../group/group_detail_screen.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prov = context.read<ReferralProvider>();
    await Future.wait([
      prov.loadCodeInfo(),
      prov.loadTree(),
      prov.loadBusinesses(refresh: true),
    ]);
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kode referral disalin!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareCode(String code) {
    Share.share(
      'Bergabunglah di BisnisKu! Gunakan kode referral saya: $code\nDowload sekarang dan mulai investasi bisnis laundry bersama saya!',
      subject: 'Kode Referral BisnisKu',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Referral & Bisnis'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Referral'),
            Tab(text: 'Bisnis'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReferralTab(),
          _buildBusinessTab(),
        ],
      ),
    );
  }

  Widget _buildReferralTab() {
    return Consumer<ReferralProvider>(
      builder: (_, prov, __) => RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildReferralCodeCard(prov.codeInfo?.referralCode ?? ''),
                  const SizedBox(height: 16),
                  _buildReferralStats(prov),
                  const SizedBox(height: 16),
                  _buildSearchBar(prov),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
            if (prov.isLoading && (prov.tree?.level1.isEmpty ?? true))
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ShimmerLoading(height: 72, borderRadius: BorderRadius.circular(12)),
                  ),
                  childCount: 6,
                ),
              )
            else if (prov.filteredLevel1.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  title: 'Belum ada referral',
                  subtitle: 'Bagikan kode referral Anda untuk mengundang orang bergabung',
                  icon: Icons.group_add_outlined,
                  actionLabel: 'Bagikan Kode',
                  onAction: () => _shareCode(prov.codeInfo?.referralCode ?? ''),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildReferralItem(prov.filteredLevel1[i]),
                    ),
                    childCount: prov.filteredLevel1.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralCodeCard(String code) {
    return GradientCard(
      colors: const [AppColors.primary, Color(0xFF00897B)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kode Referral Anda', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Text(
                  code.isEmpty ? '---' : code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: code.isEmpty ? null : () => _copyCode(code),
                  child: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: code.isEmpty ? null : () => _shareCode(code),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share_rounded, color: AppColors.primary, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Bagikan',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReferralStats(ReferralProvider prov) {
    final info = prov.codeInfo;
    return Row(
      children: [
        _statCard('Total', info?.totalReferrals ?? 0, AppColors.primary, Icons.people_rounded),
        const SizedBox(width: 10),
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                const Icon(Icons.card_giftcard_rounded, color: AppColors.success, size: 22),
                const SizedBox(height: 6),
                Text(
                  info != null ? CurrencyFormatter.compact(info.totalRewarded) : '-',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.success),
                ),
                const Text('Total Reward', style: TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _statCard('Langsung', prov.tree?.directReferrals ?? 0, AppColors.info, Icons.person_add_rounded),
      ],
    );
  }

  Widget _statCard(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ReferralProvider prov) {
    return TextField(
      controller: _searchCtrl,
      decoration: InputDecoration(
        hintText: 'Cari nama...',
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
        suffixIcon: _searchCtrl.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  _searchCtrl.clear();
                  prov.setSearch('');
                },
              )
            : null,
      ),
      onChanged: (v) => prov.setSearch(v),
    );
  }

  Widget _buildReferralItem(ReferralTreeMemberModel member) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(
                  'Bergabung ${DateFormatter.formatDate(member.joinedAt)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (member.hasInitialDeposit ? AppColors.success : AppColors.textHint).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              member.hasInitialDeposit ? 'Aktif' : 'Belum Deposit',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: member.hasInitialDeposit ? AppColors.success : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessTab() {
    return Consumer<ReferralProvider>(
      builder: (_, prov, __) => RefreshIndicator(
        onRefresh: () => prov.loadBusinesses(refresh: true),
        color: AppColors.primary,
        child: prov.businessesLoading && prov.businesses.isEmpty
            ? ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ShimmerLoading(height: 80, borderRadius: BorderRadius.circular(16)),
                ),
              )
            : prov.businesses.isEmpty
                ? const EmptyState(
                    title: 'Belum ada bisnis',
                    subtitle: 'Bisnis yang tersedia untuk investasi akan tampil di sini',
                    icon: Icons.business_outlined,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: prov.businesses.length + (prov.businessPagination?.hasNextPage == true ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= prov.businesses.length) {
                        prov.loadBusinesses();
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final biz = prov.businesses[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GroupDetailScreen(businessId: biz.id, businessName: biz.name),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.business_rounded, color: AppColors.primary, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(biz.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text(
                                      biz.category,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: 6),
                                    LinearProgressIndicator(
                                      value: biz.investorProgress,
                                      backgroundColor: AppColors.divider,
                                      color: AppColors.primary,
                                      minHeight: 4,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${biz.currentInvestors} / ${biz.targetInvestors} investor',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
