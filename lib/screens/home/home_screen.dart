import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/portfolio_model.dart';
import '../../data/models/referral_model.dart';
import '../../data/services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../widgets/app_widgets.dart';
import '../payment/initial_deposit_terms_screen.dart';
import '../payment/topup_screen.dart';
import '../payment/transactions_screen.dart';
import '../withdrawal/withdrawal_screen.dart';
import '../business/business_screen.dart';
import '../identity/identity_screen.dart';
import '../portfolio/portfolio_screen.dart';
import '../referral/referral_screen.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PortfolioSummaryModel? _portfolioSummary;
  bool? _isVerified; // null = loading, true = verified, false = not verified
  bool _balanceHidden = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final home = context.read<HomeProvider>();
    await Future.wait([
      auth.loadBalance(),
      home.loadDashboard(),
      _loadPortfolioSummary(),
      _loadVerificationStatus(),
    ]);
  }

  Future<void> _loadPortfolioSummary() async {
    try {
      final res = await ApiService.getPortfolio();
      final portfolio = PortfolioModel.fromJson(res);
      if (mounted) setState(() => _portfolioSummary = portfolio.summary);
    } catch (_) {}
  }

  Future<void> _loadVerificationStatus() async {
    try {
      final res = await ApiService.getVerificationStatus();
      final data = (res['data'] ?? res) as Map<String, dynamic>;
      if (mounted) setState(() => _isVerified = data['is_verified'] == true);
    } catch (_) {
      if (mounted) setState(() => _isVerified = false);
    }
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
                  _buildInitialDepositBanner(),
                  const SizedBox(height: 24),
                  _buildBalanceBreakdown(),
                  const SizedBox(height: 24),
                  _buildReferralStats(),
                  const SizedBox(height: 24),
                  _buildPortfolioPreview(),
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
                  'MyBisnis',
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
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    _balanceHidden
                        ? '••••••••'
                        : CurrencyFormatter.format(auth.balance?.balance ?? 0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _balanceHidden = !_balanceHidden),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _balanceHidden
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
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
                  final label = a['label'] as String;
                  if (label == 'Bagikan\nReferral' || label == 'Tim\nSaya') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen()));
                  } else if (label == 'Bisnis\nTerbuka') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessScreen()));
                  } else if (label == 'Pembayaran') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsScreen()));
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
    if (_isVerified == null || _isVerified == true) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const IdentityScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.badge_outlined, color: AppColors.warning, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verifikasi Identitas',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.warning, fontSize: 14),
                  ),
                  Text(
                    'Lengkapi identitas untuk mengakses semua fitur',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.warning),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialDepositBanner() {
    return Consumer<AuthProvider>(
      builder: (_, auth, __) {
        final isVerified = auth.balance?.isVerified ?? false;
        final hasInitialDeposit = auth.balance?.hasInitialDeposit ?? true;
        if (!isVerified || hasInitialDeposit) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1565C0).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Deposit Pertama',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                            Text(
                              'Daftarkan diri sebagai anggota koperasi',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const InitialDepositTermsScreen()),
                        ),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Lakukan deposit pertama untuk terdaftar sebagai anggota koperasi dan mendapatkan akses ke seluruh fitur investasi.',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TopupScreen()),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1565C0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Deposit Sekarang', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
                        _balanceHidden ? '••••' : (balance != null ? CurrencyFormatter.compact(balance.investmentProfit) : '-'),
                        AppColors.primary,
                        Icons.trending_up_rounded,
                      ),
                      const SizedBox(width: 12),
                      _balanceStat(
                        'Reward Referral',
                        _balanceHidden ? '••••' : (balance != null ? CurrencyFormatter.compact(balance.referralReward) : '-'),
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
            home.topBusinesses.isEmpty
                ? AppCard(
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Belum ada bisnis tersedia', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ),
                  )
                : SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemCount: home.topBusinesses.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => _buildBusinessCarouselCard(home.topBusinesses[i]),
                    ),
                  ),
          ],
        );
      },
    );
  }

  Widget _buildBusinessCarouselCard(BusinessModel business) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BusinessScreen()),
      ),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: business.imageUrl != null && business.imageUrl!.isNotEmpty
                  ? Image.network(
                      business.imageUrl!,
                      height: 110,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _businessImagePlaceholder(),
                    )
                  : _businessImagePlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    business.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    business.category,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: (business.isOpen ? AppColors.success : AppColors.textHint).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          business.isOpen ? 'Terbuka' : 'Penuh',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: business.isOpen ? AppColors.success : AppColors.textHint,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${business.currentInvestors}/${business.targetInvestors}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _businessImagePlaceholder() {
    return Container(
      height: 110,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.business_rounded, color: Colors.white54, size: 40),
      ),
    );
  }

  Widget _buildPortfolioPreview() {
    final s = _portfolioSummary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Portofolio Saya',
          actionLabel: 'Lihat Detail',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PortfolioScreen()),
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PortfolioScreen()),
          ),
          child: s == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Belum ada investasi aktif',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              : Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _portfolioStat(
                            'Total Investasi',
                            CurrencyFormatter.format(s.totalInvested),
                            AppColors.primary,
                            Icons.pie_chart_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _portfolioStat(
                            'Total Profit',
                            CurrencyFormatter.format(s.totalProfit),
                            AppColors.success,
                            Icons.trending_up_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _portfolioStat(
                            'Aktif',
                            '${s.activeInvestments} investasi',
                            AppColors.info,
                            Icons.business_center_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _portfolioStat(
                            'Saldo Tersisa',
                            CurrencyFormatter.compact(s.currentBalance),
                            AppColors.accent,
                            Icons.account_balance_wallet_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _portfolioStat(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary)),
                Text(value,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: color),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
