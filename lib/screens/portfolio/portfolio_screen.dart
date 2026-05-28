import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/portfolio_model.dart';
import '../../data/services/api_service.dart';
import '../../widgets/app_widgets.dart';
import 'portfolio_detail_screen.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  PortfolioModel? _portfolio;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getPortfolio();
      setState(() {
        _portfolio = PortfolioModel.fromJson(res);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Portofolio')),
      body: _loading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ShimmerLoading(height: i == 0 ? 160 : 110, borderRadius: BorderRadius.circular(16)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: _portfolio == null
                  ? const CustomScrollView(
                      slivers: [
                        SliverFillRemaining(
                          child: EmptyState(
                            title: 'Gagal memuat data',
                            subtitle: 'Tarik ke bawah untuk mencoba lagi',
                            icon: Icons.error_outline_rounded,
                          ),
                        ),
                      ],
                    )
                  : CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              _buildSummaryCard(),
                              const SizedBox(height: 20),
                              _buildStatRow(),
                              const SizedBox(height: 24),
                              const SectionHeader(title: 'Investasi Saya'),
                              const SizedBox(height: 12),
                              if (_portfolio!.investments.isEmpty)
                                const EmptyState(
                                  title: 'Belum ada investasi',
                                  subtitle: 'Mulai berinvestasi di bisnis yang tersedia',
                                  icon: Icons.business_center_outlined,
                                )
                              else
                                ..._portfolio!.investments.map(
                                  (inv) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildInvestmentCard(inv),
                                  ),
                                ),
                            ]),
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final s = _portfolio!.summary;
    return GradientCard(
      colors: const [AppColors.primary, AppColors.primaryLight],
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Diinvestasikan',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(s.totalInvested),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryStatCol('Total Profit', CurrencyFormatter.compact(s.totalProfit)),
              _summaryStatCol('Saldo Tersisa', CurrencyFormatter.compact(s.currentBalance)),
              _summaryStatCol('Investasi Aktif', '${s.activeInvestments}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStatCol(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
      ],
    );
  }

  Widget _buildStatRow() {
    final s = _portfolio!.summary;
    return Row(
      children: [
        _statCard('${s.totalInvestments}', 'Total', AppColors.primary, Icons.pie_chart_rounded),
        const SizedBox(width: 12),
        _statCard('${s.activeInvestments}', 'Aktif', AppColors.success, Icons.trending_up_rounded),
        const SizedBox(width: 12),
        _statCard('${s.pendingInvestments}', 'Pending', AppColors.warning, Icons.hourglass_empty_rounded),
      ],
    );
  }

  Widget _statCard(String value, String label, Color color, IconData icon) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestmentCard(PortfolioInvestmentModel inv) {
    Color statusColor;
    switch (inv.status) {
      case 'active':
        statusColor = AppColors.success;
        break;
      case 'pending':
        statusColor = AppColors.warning;
        break;
      default:
        statusColor = AppColors.textHint;
    }

    return AppCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PortfolioDetailScreen(
            investmentId: inv.id,
            businessName: inv.business.name,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.business_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inv.business.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                        overflow: TextOverflow.ellipsis),
                    Text(inv.business.category,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  inv.statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _investStat(
                  'Total Investasi',
                  CurrencyFormatter.format(inv.totalAmount),
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _investStat(
                  'Profit Diterima',
                  CurrencyFormatter.format(inv.profitReceived),
                  AppColors.success,
                ),
              ),
            ],
          ),
          if (inv.isInstallment && inv.installmentProgress != null) ...[
            const SizedBox(height: 14),
            _buildProgressBar(inv.installmentProgress!),
          ],
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.payments_outlined,
                      size: 13, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    inv.isInstallment ? 'Cicilan' : 'Lunas',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 13, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    inv.joinedAt ?? '-',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _investStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _buildProgressBar(InstallmentProgressModel p) {
    final progress = p.tenureMonths > 0 ? p.monthsPaid / p.tenureMonths : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cicilan ${p.monthsPaid}/${p.tenureMonths} bulan',
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.toDouble(),
            backgroundColor: AppColors.divider,
            color: p.completed ? AppColors.success : AppColors.primary,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
