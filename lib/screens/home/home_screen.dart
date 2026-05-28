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
import '../business/business_screen.dart';
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
    await Future.wait([auth.loadBalance(), home.loadDashboard()]);
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
                  _buildVerificationBanner(),
                  const SizedBox(height: 24),
                  _buildBalanceBreakdown(),
                  const SizedBox(height: 24),
                  _buildReferralStats(),
                  const SizedBox(height: 24),
                  _buildBusinessesPreview(),
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
                        auth.balance?.isVerified == true
                            ? Icons.verified_rounded
                            : Icons.pending_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        auth.balance?.isVerified == true ? 'Terverifikasi' : 'Belum Verifikasi',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              CurrencyFormatter.format(auth.balance?.balance ?? 0),
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
                  'Deposit',
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
                  Icons.business_center_rounded,
                  'Bisnis',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessScreen())),
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
      {'icon': Icons.business_rounded, 'label': 'Bisnis\nTerbuka', 'color': AppColors.info},
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
                  if (a['label'] == 'Bisnis\nTerbuka') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessScreen()));
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

  Widget _buildVerificationBanner() {
    return FutureBuilder<int?>(
      future: _getVerificationStatus(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final status = snapshot.data;
        if (status == 1) return const SizedBox.shrink();

        Color bgColor;
        IconData icon;
        String title, subtitle;
        VoidCallback onTap;

        if (status == 2) {
          bgColor = AppColors.info;
          icon = Icons.payments_rounded;
          title = 'Lengkapi Deposit Awal';
          subtitle = 'Selesaikan deposit awal untuk mulai berinvestasi';
          onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TopupScreen()));
        } else if (status == null) {
          bgColor = AppColors.warning;
          icon = Icons.badge_outlined;
          title = 'Verifikasi Identitas';
          subtitle = 'Lengkapi identitas untuk mengakses semua fitur';
          onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IdentityScreen()));
        } else if (status == 0) {
          bgColor = AppColors.info;
          icon = Icons.hourglass_empty_rounded;
          title = 'Identitas Sedang Diverifikasi';
          subtitle = 'Mohon tunggu, proses sedang berlangsung';
          onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IdentityScreen()));
        } else {
          bgColor = AppColors.error;
          icon = Icons.error_outline_rounded;
          title = 'Identitas Ditolak';
          subtitle = 'Klik untuk melihat alasan dan submit ulang';
          onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IdentityScreen()));
        }

        return GestureDetector(
          onTap: onTap,
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

  Future<int?> _getVerificationStatus() async {
    try {
      final res = await ApiService.getVerificationStatus();
      final data = res['data'] ?? res;
      final isVerified = data['is_verified'] == true;
      final hasDeposit = data['has_initial_deposit'] == true;
      if (isVerified && hasDeposit) return 1; // fully onboarded
      if (isVerified) return 2; // verified but no deposit
      final vStatus = data['verification_status'];
      if (vStatus == 'pending') return 0;
      if (vStatus == 'rejected') return -1;
      return null; // not submitted
    } catch (_) {
      return null;
    }
  }

  Widget _buildBalanceBreakdown() {
    return Consumer<AuthProvider>(
      builder: (_, auth, __) {
        final balance = auth.balance;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Ringkasan Saldo'),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      _balanceStat(
                        'Profit Investasi',
                        balance != null ? CurrencyFormatter.compact(balance.investmentProfit) : '-',
                        AppColors.primary,
                        Icons.trending_up_rounded,
                      ),
                      const SizedBox(width: 12),
                      _balanceStat(
                        'Reward Referral',
                        balance != null ? CurrencyFormatter.compact(balance.referralReward) : '-',
                        AppColors.accent,
                        Icons.card_giftcard_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _balanceStat(String label, String value, Color color, IconData icon) {
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
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
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
        final info = home.referralInfo;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Referral Saya'),
            const SizedBox(height: 12),
            Row(
              children: [
                _referralStat('Total Referral', info?.totalReferrals ?? 0, AppColors.primary),
                const SizedBox(width: 12),
                _referralStatCurrency(
                  'Total Reward',
                  info != null ? CurrencyFormatter.compact(info.totalRewarded) : '-',
                  AppColors.success,
                ),
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
            Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _referralStatCurrency(String label, String value, Color color) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessesPreview() {
    return Consumer<HomeProvider>(
      builder: (_, home, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Bisnis Terbuka',
              actionLabel: 'Lihat Semua',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BusinessScreen()),
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: home.topBusinesses.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Belum ada bisnis tersedia', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    )
                  : Column(
                      children: home.topBusinesses.asMap().entries.map((entry) {
                        final i = entry.key;
                        final b = entry.value;
                        return _businessRow(b, i < home.topBusinesses.length - 1);
                      }).toList(),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _businessRow(business, bool divider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.business_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      business.category,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${business.currentInvestors}/${business.targetInvestors}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success),
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
