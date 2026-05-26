import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/referral_provider.dart';
import '../../providers/auth_provider.dart';
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
      prov.loadSummary(),
      prov.loadReferrals(refresh: true),
      prov.loadGroups(refresh: true),
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
      'Bergabunglah di LaundriKu! Gunakan kode referral saya: $code\nDowload sekarang dan mulai investasi bisnis laundry bersama saya!',
      subject: 'Kode Referral LaundriKu',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Referral & Tim'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Referral'),
            Tab(text: 'Grup'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReferralTab(),
          _buildGroupTab(),
        ],
      ),
    );
  }

  Widget _buildReferralTab() {
    return Consumer2<ReferralProvider, AuthProvider>(
      builder: (_, ref, auth, __) => RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildReferralCodeCard(auth.user?.referralCode ?? ''),
                  const SizedBox(height: 16),
                  _buildReferralStats(ref),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
            if (ref.isLoading && ref.referrals.isEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ShimmerLoading(height: 72, borderRadius: BorderRadius.circular(12)),
                  ),
                  childCount: 6,
                ),
              )
            else if (ref.referrals.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  title: 'Belum ada referral',
                  subtitle: 'Bagikan kode referral Anda untuk mengundang orang bergabung',
                  icon: Icons.group_add_outlined,
                  actionLabel: 'Bagikan Kode',
                  onAction: () => _shareCode(auth.user?.referralCode ?? ''),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      if (i == ref.referrals.length) {
                        if (ref.pagination?.hasNextPage == true) {
                          ref.loadReferrals();
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return null;
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildReferralItem(ref.referrals[i]),
                      );
                    },
                    childCount: ref.referrals.length + (ref.pagination?.hasNextPage == true ? 1 : 0),
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
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
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

  Widget _buildReferralStats(ReferralProvider ref) {
    final summary = ref.summary;
    return Row(
      children: [
        _statCard('Total', summary?.totalReferrals ?? 0, AppColors.primary, Icons.people_rounded),
        const SizedBox(width: 10),
        _statCard('Aktif', summary?.activeReferrals ?? 0, AppColors.success, Icons.verified_user_rounded),
        const SizedBox(width: 10),
        _statCard('Tidak Aktif', summary?.inactiveReferrals ?? 0, AppColors.warning, Icons.person_off_rounded),
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

  Widget _buildSearchBar() {
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
                  context.read<ReferralProvider>().setSearch('');
                },
              )
            : null,
      ),
      onChanged: (v) => context.read<ReferralProvider>().setSearch(v),
    );
  }

  Widget _buildReferralItem(referral) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              referral.name.isNotEmpty ? referral.name[0].toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(referral.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(referral.email, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  DateFormatter.timeAgo(referral.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (referral.isActiveReferral ? AppColors.success : AppColors.textHint).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              referral.isActiveReferral ? 'Aktif' : 'Tidak Aktif',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: referral.isActiveReferral ? AppColors.success : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTab() {
    return Consumer<ReferralProvider>(
      builder: (_, prov, __) => RefreshIndicator(
        onRefresh: () => prov.loadGroups(refresh: true),
        color: AppColors.primary,
        child: prov.groupsLoading && prov.groups.isEmpty
            ? ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ShimmerLoading(height: 80, borderRadius: BorderRadius.circular(16)),
                ),
              )
            : prov.groups.isEmpty
                ? const EmptyState(
                    title: 'Belum ada grup',
                    subtitle: 'Grup akan muncul saat Anda bergabung dalam jaringan referral',
                    icon: Icons.groups_outlined,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: prov.groups.length,
                    itemBuilder: (_, i) {
                      final group = prov.groups[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: group.id, groupName: group.name)),
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
                                child: const Icon(Icons.groups_rounded, color: AppColors.primary, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(group.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${group.membersCount} anggota',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
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
