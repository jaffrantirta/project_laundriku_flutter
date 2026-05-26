import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/bonus_model.dart';
import '../../data/models/payment_model.dart';
import '../../data/models/withdrawal_model.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/app_widgets.dart';
import 'payment_detail_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final prov = context.read<TransactionProvider>();
    await Future.wait([
      prov.loadPayments(refresh: true),
      prov.loadWithdrawals(refresh: true),
      prov.loadBonuses(refresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transaksi'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Pembayaran'),
            Tab(text: 'Penarikan'),
            Tab(text: 'Bonus'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPaymentsTab(),
          _buildWithdrawalsTab(),
          _buildBonusesTab(),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    return Consumer<TransactionProvider>(
      builder: (_, prov, __) => RefreshIndicator(
        onRefresh: () => prov.loadPayments(refresh: true),
        color: AppColors.primary,
        child: prov.paymentsLoading && prov.payments.isEmpty
            ? _shimmerList()
            : prov.payments.isEmpty
                ? const EmptyState(
                    title: 'Belum ada pembayaran',
                    subtitle: 'Riwayat pembayaran akan muncul di sini',
                    icon: Icons.receipt_long_outlined,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: prov.payments.length + (prov.paymentPagination?.hasNextPage == true ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= prov.payments.length) {
                        prov.loadPayments();
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _paymentItem(prov.payments[i]),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _paymentItem(PaymentModel p) {
    final color = _paymentTypeColor(p.type.value);
    return AppCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PaymentDetailScreen(orderId: p.orderId)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_paymentTypeIcon(p.type.value), color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.type.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(p.orderId, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                Text(DateFormatter.formatDateTime(p.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(p.grossAmount),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 4),
              StatusBadge(label: p.status.label, statusValue: p.status.value),
            ],
          ),
        ],
      ),
    );
  }

  Color _paymentTypeColor(int type) {
    switch (type) {
      case 0:
        return AppColors.info;
      case 1:
        return AppColors.primary;
      case 2:
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _paymentTypeIcon(int type) {
    switch (type) {
      case 0:
        return Icons.account_circle_rounded;
      case 1:
        return Icons.card_membership_rounded;
      case 2:
        return Icons.add_circle_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  Widget _buildWithdrawalsTab() {
    return Consumer<TransactionProvider>(
      builder: (_, prov, __) => RefreshIndicator(
        onRefresh: () => prov.loadWithdrawals(refresh: true),
        color: AppColors.primary,
        child: prov.withdrawalsLoading && prov.withdrawals.isEmpty
            ? _shimmerList()
            : prov.withdrawals.isEmpty
                ? const EmptyState(
                    title: 'Belum ada penarikan',
                    subtitle: 'Riwayat penarikan saldo akan muncul di sini',
                    icon: Icons.account_balance_wallet_outlined,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: prov.withdrawals.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _withdrawalItem(prov.withdrawals[i]),
                    ),
                  ),
      ),
    );
  }

  Widget _withdrawalItem(WithdrawalModel w) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_upward_rounded, color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Penarikan Saldo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(DateFormatter.formatDateTime(w.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text('Diterima: ${CurrencyFormatter.format(w.grossAmount)}', style: const TextStyle(fontSize: 11, color: AppColors.success)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-${CurrencyFormatter.format(w.amount)}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.error),
              ),
              const SizedBox(height: 4),
              StatusBadge(label: w.status.label, statusValue: w.status.value, isPayment: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBonusesTab() {
    return Consumer<TransactionProvider>(
      builder: (_, prov, __) => RefreshIndicator(
        onRefresh: () => prov.loadBonuses(refresh: true),
        color: AppColors.primary,
        child: prov.bonusesLoading && prov.bonuses.isEmpty
            ? _shimmerList()
            : prov.bonuses.isEmpty
                ? const EmptyState(
                    title: 'Belum ada bonus',
                    subtitle: 'Bonus akan masuk saat referral Anda aktif dan melakukan transaksi',
                    icon: Icons.card_giftcard_outlined,
                  )
                : Column(
                    children: [
                      if (prov.bonusTotal > 0)
                        Container(
                          margin: const EdgeInsets.all(16),
                          child: GradientCard(
                            colors: const [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
                            child: Row(
                              children: [
                                const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 28),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Total Bonus', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    Text(
                                      CurrencyFormatter.format(prov.bonusTotal),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: prov.bonuses.length + (prov.bonusPagination?.hasNextPage == true ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i >= prov.bonuses.length) {
                              prov.loadBonuses();
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _bonusItem(prov.bonuses[i]),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _bonusItem(BonusModel b) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'L${b.level}',
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
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
                  'Bonus Level ${b.level}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(
                  'Dari: ${b.fromUserName ?? 'N/A'}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  DateFormatter.timeAgo(b.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${CurrencyFormatter.format(b.amount)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.success,
                ),
              ),
              Text(
                '${b.percentage}%',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ShimmerLoading(height: 80, borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
