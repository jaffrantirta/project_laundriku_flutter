import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/withdrawal_model.dart';
import '../../data/services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/app_widgets.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  bool _showForm = false;
  final _amountCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _accountNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final auth = context.read<AuthProvider>();
    final tx = context.read<TransactionProvider>();
    await Future.wait([
      auth.loadBalance(),
      tx.loadWithdrawals(refresh: true),
    ]);
  }

  Future<void> _submit() async {
    final raw = _amountCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
    final amount = int.tryParse(raw);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan jumlah penarikan yang valid'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_bankNameCtrl.text.trim().isEmpty ||
        _accountNumberCtrl.text.trim().isEmpty ||
        _accountNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi semua data rekening bank'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ApiService.requestWithdrawal(
        amount: amount,
        bankName: _bankNameCtrl.text.trim(),
        accountNumber: _accountNumberCtrl.text.trim(),
        accountName: _accountNameCtrl.text.trim(),
      );
      if (mounted) {
        setState(() {
          _showForm = false;
          _amountCtrl.clear();
          _bankNameCtrl.clear();
          _accountNumberCtrl.clear();
          _accountNameCtrl.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permintaan penarikan berhasil dibuat!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadAll();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Penarikan Saldo')),
      body: Consumer<AuthProvider>(
        builder: (_, auth, __) {
          final isVerified = auth.balance?.isVerified == true;
          return RefreshIndicator(
            onRefresh: _loadAll,
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildBalanceCard(auth),
                      const SizedBox(height: 16),
                      if (isVerified) ...[
                        if (_showForm) _buildForm() else _buildWithdrawButton(),
                        const SizedBox(height: 16),
                      ] else
                        _buildIdentityWarning(),
                      const SizedBox(height: 8),
                      const SectionHeader(title: 'Riwayat Penarikan'),
                      const SizedBox(height: 12),
                    ]),
                  ),
                ),
                _buildHistory(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(AuthProvider auth) {
    final balance = auth.balance?.balance ?? 0;
    return GradientCard(
      colors: const [AppColors.primary, AppColors.primaryLight],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Saldo Tersedia', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(balance),
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoChip('Profit Investasi', CurrencyFormatter.compact(auth.balance?.investmentProfit ?? 0)),
              const SizedBox(width: 12),
              _infoChip('Reward Referral', CurrencyFormatter.compact(auth.balance?.referralReward ?? 0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => setState(() => _showForm = true),
        icon: const Icon(Icons.arrow_upward_rounded),
        label: const Text('Tarik Saldo'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Jumlah Penarikan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          const Text(
            'Masukkan jumlah yang ingin ditarik',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              hintText: '0',
              prefixText: 'Rp ',
              prefixStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Data Rekening Bank', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          _bankField(_bankNameCtrl, 'Nama Bank (contoh: BCA, Mandiri)', Icons.account_balance_rounded),
          const SizedBox(height: 10),
          _bankField(_accountNumberCtrl, 'Nomor Rekening', Icons.credit_card_rounded,
              type: TextInputType.number),
          const SizedBox(height: 10),
          _bankField(_accountNameCtrl, 'Nama Pemilik Rekening', Icons.person_outline_rounded),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _showForm = false;
                    _amountCtrl.clear();
                    _bankNameCtrl.clear();
                    _accountNumberCtrl.clear();
                    _accountNameCtrl.clear();
                  }),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LoadingButton(
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                  label: 'Tarik',
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bankField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? type,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
      ),
    );
  }

  Widget _buildIdentityWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Verifikasi identitas diperlukan untuk melakukan penarikan',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    return Consumer<TransactionProvider>(
      builder: (_, prov, __) {
        if (prov.withdrawalsLoading && prov.withdrawals.isEmpty) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ShimmerLoading(height: 80, borderRadius: BorderRadius.circular(12)),
              ),
              childCount: 4,
            ),
          );
        }
        if (prov.withdrawals.isEmpty) {
          return const SliverToBoxAdapter(
            child: EmptyState(
              title: 'Belum ada riwayat penarikan',
              subtitle: 'Penarikan saldo yang berhasil akan ditampilkan di sini',
              icon: Icons.account_balance_wallet_outlined,
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                if (i >= prov.withdrawals.length) return null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _withdrawalItem(prov.withdrawals[i]),
                );
              },
              childCount: prov.withdrawals.length,
            ),
          ),
        );
      },
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
              color: AppColors.accent.withOpacity(0.1),
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
                const SizedBox(height: 4),
                Text(
                  DateFormatter.formatDateTime(w.createdAt),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${w.bankName} • ${w.accountNumber}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                ),
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
}
