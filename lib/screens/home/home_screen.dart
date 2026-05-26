import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../widgets/app_widgets.dart';
import '../payment/topup_screen.dart';
import '../withdrawal/withdrawal_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../identity/identity_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final home = context.read<HomeProvider>();
    await Future.wait([auth.loadWallet(), home.loadDashboard()]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  _buildWalletCard(),
                  const SizedBox(height: 20),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildIdentityBanner(),
                  const SizedBox(height: 24),
                  _buildBonusSummary(),
                  const SizedBox(height: 24),
                  _buildReferralStats(),
                  const SizedBox(height: 24),
                  _buildLeaderboardPreview(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: false,
      backgroundColor: AppColors.primary,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(color: AppColors.primary),
      ),
      title: Consumer<AuthProvider>(
        builder: (_, auth, __) => Row(
          children: [
            const Icon(Icons.local_laundry_service_rounded, color: Colors.white, size: 26),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'LaundriKu',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Halo, ${auth.user?.name.split(' ').first ?? 'Member'}!',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildWalletCard() {
    return Consumer<AuthProvider>(
      builder: (_, auth, __) => GradientCard(
        colors: const [AppColors.primary, AppColors.primaryLight],
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Saldo Dompet',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        auth.user?.isActiveReferral == true
                            ? Icons.verified_rounded
                            : Icons.pending_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        auth.user?.isActiveReferral == true ? 'Aktif' : 'Tidak Aktif',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              auth.wallet?.balanceFormatted ?? 'Rp 0',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 16),
            Row(
              children: [
                _walletAction(
                  Icons.add_rounded,
                  'Topup',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TopupScreen())),
                ),
                const SizedBox(width: 16),
                _walletAction(
                  Icons.arrow_upward_rounded,
                  'Tarik',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WithdrawalScreen())),
                ),
                const SizedBox(width: 16),
                _walletAction(
                  Icons.history_rounded,
                  'Riwayat',
                  () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _walletAction(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.share_rounded, 'label': 'Bagikan\nReferral', 'color': AppColors.primary},
      {'icon': Icons.people_outline_rounded, 'label': 'Tim\nSaya', 'color': AppColors.accent},
      {'icon': Icons.leaderboard_rounded, 'label': 'Papan\nPesat', 'color': AppColors.info},
      {'icon': Icons.receipt_long_rounded, 'label': 'Pembayaran', 'color': AppColors.warning},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Aksi Cepat'),
        const SizedBox(height: 12),
        Row(
          children: actions.map((a) {
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (a['label'] == 'Papan\nPesat') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
                  }
                },
                child: AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: (a['color'] as Color).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(a['icon'] as IconData, color: a['color'] as Color, size: 22),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        a['label'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).expand((w) => [w, const SizedBox(width: 10)]).toList()
            ..removeLast(),
        ),
      ],
    );
  }

  Widget _buildIdentityBanner() {
    return FutureBuilder(
      future: _getIdentityStatus(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final status = snapshot.data as int?;
        if (status == 1) return const SizedBox.shrink();

        Color bgColor;
        IconData icon;
        String title, subtitle;

        if (status == null) {
          bgColor = AppColors.warning;
          icon = Icons.badge_outlined;
          title = 'Verifikasi Identitas';
          subtitle = 'Lengkapi KTP untuk bisa melakukan penarikan';
        } else if (status == 0) {
          bgColor = AppColors.info;
          icon = Icons.hourglass_empty_rounded;
          title = 'Identitas Sedang Diverifikasi';
          subtitle = 'Mohon tunggu, proses sedang berlangsung';
        } else {
          bgColor = AppColors.error;
          icon = Icons.error_outline_rounded;
          title = 'Identitas Ditolak';
          subtitle = 'Klik untuk melihat alasan dan submit ulang';
        }

        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IdentityScreen())),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: bgColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: bgColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: bgColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: bgColor, fontSize: 14)),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: bgColor),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<int?> _getIdentityStatus() async {
    try {
      final res = await ApiService.getIdentityStatus();
      return res['data']['status'];
    } catch (_) {
      return null;
    }
  }

  Widget _buildBonusSummary() {
    return Consumer<HomeProvider>(
      builder: (_, home, __) {
        final summary = home.bonusSummary;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Ringkasan Bonus', actionLabel: 'Lihat Semua'),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      _bonusStat(
                        'Total Bonus',
                        summary != null ? CurrencyFormatter.compact(summary.totalBonus) : '-',
                        AppColors.primary,
                        Icons.account_balance_wallet_rounded,
                      ),
                      const SizedBox(width: 12),
                      _bonusStat(
                        'Transaksi',
                        summary?.totalTransactions.toString() ?? '-',
                        AppColors.accent,
                        Icons.swap_horiz_rounded,
                      ),
                    ],
                  ),
                  if (summary != null && summary.bonusByLevel.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    ...summary.bonusByLevel.map((b) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    'L${b.level}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Level ${b.level}',
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                              const Spacer(),
                              Text(
                                CurrencyFormatter.format(b.totalAmount),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${b.count}x)',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _bonusStat(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralStats() {
    return Consumer<HomeProvider>(
      builder: (_, home, __) {
        final summary = home.referralSummary;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Referral Saya'),
            const SizedBox(height: 12),
            Row(
              children: [
                _referralStat('Total', summary?.totalReferrals ?? 0, AppColors.primary),
                const SizedBox(width: 12),
                _referralStat('Aktif', summary?.activeReferrals ?? 0, AppColors.success),
                const SizedBox(width: 12),
                _referralStat('Tidak Aktif', summary?.inactiveReferrals ?? 0, AppColors.warning),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _referralStat(String label, int count, Color color) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardPreview() {
    return Consumer<HomeProvider>(
      builder: (_, home, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Papan Peringkat',
              actionLabel: 'Lihat Semua',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: home.topLeaderboard.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Belum ada data', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    )
                  : Column(
                      children: home.topLeaderboard.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        return _leaderboardRow(item.rank, item.user.name, item.amount, i < 2);
                      }).toList(),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _leaderboardRow(int rank, String name, int amount, bool divider) {
    final rankColors = [
      const Color(0xFFFFD700),
      const Color(0xFFC0C0C0),
      const Color(0xFFCD7F32),
    ];
    final color = rank <= 3 ? rankColors[rank - 1] : AppColors.textSecondary;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                CurrencyFormatter.compact(amount),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        if (divider) const Divider(height: 1),
      ],
    );
  }
}

