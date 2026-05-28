import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/payment_model.dart';
import '../../data/models/referral_model.dart';
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
      prov.loadRewards(refresh: true),
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
            Tab(text: 'Reward'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPaymentsTab(),
          _buildWithdrawalsTab(),
          _buildRewardsTab(),
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

  Widget _paymentItem(TransactionModel t) {
    final color = _transactionColor(t.type);
    return AppCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PaymentDetailScreen(transactionId: t.id)),
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
            child: Icon(_transactionIcon(t.type), color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.typeLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text('#${t.id}', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                Text(DateFormatter.formatDateTime(t.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(t.amount),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 4),
              StatusBadge(label: t.statusLabel, statusValue: t.statusValue),
            ],
          ),
        ],
      ),
    );
  }

  Color _transactionColor(String type) {
    switch (type) {
      case 'initial_deposit':
        return AppColors.info;
      case 'investment':
      case 'installment':
        return AppColors.primary;
      case 'profit':
        return AppColors.success;
      case 'referral_reward':
        return AppColors.accent;
      case 'withdrawal':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _transactionIcon(String type) {
    switch (type) {
      case 'initial_deposit':
        return Icons.account_circle_rounded;
      case 'investment':
        return Icons.business_center_rounded;
      case 'installment':
        return Icons.payments_rounded;
      case 'profit':
        return Icons.trending_up_rounded;
      case 'referral_reward':
        return Icons.card_giftcard_rounded;
      case 'withdrawal':
        return Icons.arrow_upward_rounded;
      default:
        return Icons.receipt_rounded;
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
                Text('${w.bankName} • ${w.accountNumber}', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
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
              StatusBadge(label: w.statusLabel, statusValue: w.statusValue, isPayment: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsTab() {
    return Consumer<TransactionProvider>(
      builder: (_, prov, __) => RefreshIndicator(
        onRefresh: () => prov.loadRewards(refresh: true),
        color: AppColors.primary,
        child: prov.rewardsLoading && prov.rewards.isEmpty
            ? _shimmerList()
            : prov.rewards.isEmpty
                ? const EmptyState(
                    title: 'Belum ada reward',
                    subtitle: 'Reward referral akan masuk saat referral Anda menyelesaikan deposit',
                    icon: Icons.card_giftcard_outlined,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: prov.rewards.length + (prov.rewardPagination?.hasNextPage == true ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= prov.rewards.length) {
                        prov.loadRewards();
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _rewardItem(prov.rewards[i]),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _rewardItem(ReferralRewardModel r) {
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
                'L${r.level}',
                style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reward Level ${r.level}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text('Dari: ${r.fromUser}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(DateFormatter.timeAgo(r.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${CurrencyFormatter.format(r.amount)}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.success),
              ),
              const SizedBox(height: 4),
              StatusBadge(label: r.statusLabel, statusValue: r.statusValue),
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
