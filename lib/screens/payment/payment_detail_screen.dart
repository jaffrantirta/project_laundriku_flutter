import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/payment_model.dart';
import '../../data/services/api_service.dart';
import '../../widgets/app_widgets.dart';

class PaymentDetailScreen extends StatefulWidget {
  final int transactionId;
  const PaymentDetailScreen({super.key, required this.transactionId});

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  TransactionModel? _transaction;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getPaymentStatus(widget.transactionId);
      final data = res['data'] ?? res;
      setState(() {
        _transaction = TransactionModel.fromJson(data['transaction'] ?? data);
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
      appBar: AppBar(title: const Text('Detail Pembayaran')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _transaction == null
              ? const EmptyState(title: 'Pembayaran tidak ditemukan', icon: Icons.receipt_long_outlined)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildStatusCard(),
                        const SizedBox(height: 16),
                        _buildDetailsCard(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatusCard() {
    final t = _transaction!;
    final isSuccess = t.statusValue == 2;
    final isPending = t.statusValue == 0;
    final color = isSuccess ? AppColors.success : isPending ? AppColors.warning : AppColors.error;
    final icon = isSuccess ? Icons.check_circle_rounded : isPending ? Icons.pending_rounded : Icons.cancel_rounded;

    return GradientCard(
      colors: [color, color.withOpacity(0.7)],
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          Text(t.statusLabel, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(t.amount),
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    final t = _transaction!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Detail Transaksi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          InfoRow(label: 'ID Transaksi', value: '#${t.id}'),
          InfoRow(label: 'Jenis', value: t.typeLabel),
          InfoRow(label: 'Jumlah', value: CurrencyFormatter.format(t.amount), bold: true, valueColor: AppColors.primary),
          InfoRow(label: 'Status', value: t.statusLabel),
          if (t.confirmedAt != null) InfoRow(label: 'Dikonfirmasi', value: DateFormatter.formatDateTime(t.confirmedAt)),
          InfoRow(label: 'Dibuat', value: DateFormatter.formatDateTime(t.createdAt)),
        ],
      ),
    );
  }
}
