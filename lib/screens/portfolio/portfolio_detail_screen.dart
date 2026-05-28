import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/portfolio_model.dart';
import '../../data/services/api_service.dart';
import '../../widgets/app_widgets.dart';

class PortfolioDetailScreen extends StatefulWidget {
  final int investmentId;
  final String businessName;

  const PortfolioDetailScreen({
    super.key,
    required this.investmentId,
    required this.businessName,
  });

  @override
  State<PortfolioDetailScreen> createState() => _PortfolioDetailScreenState();
}

class _PortfolioDetailScreenState extends State<PortfolioDetailScreen>
    with SingleTickerProviderStateMixin {
  PortfolioDetailModel? _detail;
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getPortfolioDetail(widget.investmentId);
      setState(() {
        _detail = PortfolioDetailModel.fromJson(res);
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
      appBar: AppBar(
        title: Text(widget.businessName, overflow: TextOverflow.ellipsis),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(text: 'Detail'),
            Tab(text: 'Cicilan'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: _loading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ShimmerLoading(height: 100, borderRadius: BorderRadius.circular(16)),
              ),
            )
          : _detail == null
              ? const Center(child: Text('Gagal memuat data'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDetailTab(),
                    _buildInstallmentTab(),
                    _buildHistoryTab(),
                  ],
                ),
    );
  }

  Widget _buildDetailTab() {
    final inv = _detail!.investment;
    final biz = inv.business;
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          GradientCard(
            colors: const [AppColors.primary, AppColors.primaryLight],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        biz.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    _statusChip(inv.status, inv.statusLabel),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  biz.category,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(biz.location, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _whiteStatCol('Total Investasi', CurrencyFormatter.format(inv.totalAmount)),
                    _whiteStatCol('Profit Diterima', CurrencyFormatter.format(inv.profitReceived)),
                    _whiteStatCol('Admin Fee', CurrencyFormatter.format(inv.adminFee)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Info Investasi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 14),
                _infoRow('Jenis Pembayaran', inv.isInstallment ? 'Cicilan' : 'Lunas'),
                _infoRow('Tanggal Bergabung', inv.joinedAt ?? '-'),
                _infoRow('Tanggal Aktif', biz.activationDate ?? '-'),
                _infoRow('Investor', '${biz.currentInvestors} / ${biz.targetInvestors}'),
              ],
            ),
          ),
          if (inv.installmentProgress != null) ...[
            const SizedBox(height: 16),
            _buildInstallmentProgress(inv.installmentProgress!),
          ],
        ],
      ),
    );
  }

  Widget _buildInstallmentProgress(InstallmentProgressModel p) {
    final progressValue = p.tenureMonths > 0 ? p.monthsPaid / p.tenureMonths : 0.0;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Progress Cicilan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${p.monthsPaid} dari ${p.tenureMonths} bulan',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              Text(
                '${(progressValue * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue.toDouble(),
              backgroundColor: AppColors.divider,
              color: p.completed ? AppColors.success : AppColors.primary,
              minHeight: 8,
            ),
          ),
          if (!p.completed && p.nextDueDate != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.info),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Jatuh Tempo Berikutnya',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Text(
                          DateFormatter.formatDate(p.nextDueDate),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(p.nextAmount),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (p.completed) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                  SizedBox(width: 8),
                  Text('Semua cicilan telah lunas',
                      style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstallmentTab() {
    final schedule = _detail!.installmentSchedule;
    if (schedule == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: EmptyState(
            title: 'Tidak ada cicilan',
            subtitle: 'Investasi ini menggunakan pembayaran lunas',
            icon: Icons.receipt_long_outlined,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: schedule.length,
      itemBuilder: (_, i) {
        final item = schedule[i];
        final isPaid = item.status == 'paid';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: (isPaid ? AppColors.success : AppColors.textHint).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${item.monthNumber}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isPaid ? AppColors.success : AppColors.textHint,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bulan ${item.monthNumber}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Text(
                        DateFormatter.formatDate(item.dueDate),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(item.amount),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isPaid ? AppColors.success : AppColors.textHint).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isPaid ? 'Lunas' : 'Belum',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isPaid ? AppColors.success : AppColors.textHint,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        if (_detail!.profitHistory.isNotEmpty) ...[
          const Text('Riwayat Profit', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          ..._detail!.profitHistory.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.trending_up_rounded,
                            color: AppColors.success, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.notes ?? 'Distribusi Profit',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (p.confirmedAt != null)
                              Text(
                                _formatDate(p.confirmedAt!),
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(p.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 20),
        ],
        if (_detail!.paymentHistory.isNotEmpty) ...[
          const Text('Riwayat Pembayaran', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          ..._detail!.paymentHistory.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: (p.status == 'success' ? AppColors.primary : AppColors.textHint)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.payment_rounded,
                          color: p.status == 'success' ? AppColors.primary : AppColors.textHint,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.typeLabel,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            if (p.confirmedAt != null)
                              Text(
                                _formatDate(p.confirmedAt!),
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.format(p.amount),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (p.status == 'success' ? AppColors.success : AppColors.textHint)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              p.statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: p.status == 'success' ? AppColors.success : AppColors.textHint,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
        ],
        if (_detail!.profitHistory.isEmpty && _detail!.paymentHistory.isEmpty)
          const EmptyState(
            title: 'Belum ada riwayat',
            subtitle: 'Riwayat pembayaran dan profit akan tampil di sini',
            icon: Icons.history_rounded,
          ),
      ],
    );
  }

  Widget _statusChip(String status, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _whiteStatCol(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
