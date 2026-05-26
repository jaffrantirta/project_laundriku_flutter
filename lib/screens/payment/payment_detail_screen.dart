import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/payment_model.dart';
import '../../data/services/api_service.dart';
import '../../widgets/app_widgets.dart';

class PaymentDetailScreen extends StatefulWidget {
  final String orderId;
  const PaymentDetailScreen({super.key, required this.orderId});

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  PaymentModel? _payment;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getPaymentDetail(widget.orderId);
      setState(() {
        _payment = PaymentModel.fromJson(res['data']);
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
          : _payment == null
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
                        if (_payment!.paymentInfo != null) ...[
                          const SizedBox(height: 16),
                          _buildPaymentInfoCard(),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatusCard() {
    final p = _payment!;
    final isSuccess = p.status.value == 2;
    final isPending = p.status.value == 0 || p.status.value == 1;
    final color = isSuccess ? AppColors.success : isPending ? AppColors.warning : AppColors.error;
    final icon = isSuccess ? Icons.check_circle_rounded : isPending ? Icons.pending_rounded : Icons.cancel_rounded;

    return GradientCard(
      colors: [color, color.withOpacity(0.7)],
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          Text(p.status.label, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(p.grossAmount),
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    final p = _payment!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Detail Transaksi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          InfoRow(label: 'Order ID', value: p.orderId),
          InfoRow(label: 'Jenis', value: p.type.label),
          InfoRow(label: 'Jumlah', value: CurrencyFormatter.format(p.amount)),
          InfoRow(label: 'Biaya Admin', value: CurrencyFormatter.format(p.adminFee)),
          InfoRow(label: 'Total', value: CurrencyFormatter.format(p.grossAmount), bold: true, valueColor: AppColors.primary),
          if (p.paymentType != null) InfoRow(label: 'Metode', value: p.paymentType!.label),
          if (p.paidAt != null) InfoRow(label: 'Dibayar', value: DateFormatter.formatDateTime(p.paidAt)),
          if (p.expireTime != null) InfoRow(label: 'Kadaluarsa', value: DateFormatter.formatDateTime(p.expireTime)),
          InfoRow(label: 'Dibuat', value: DateFormatter.formatDateTime(p.createdAt)),
          if (p.transactionId != null) InfoRow(label: 'Transaction ID', value: p.transactionId!),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoCard() {
    final info = _payment!.paymentInfo!;
    return AppCard(
      color: AppColors.primary.withOpacity(0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text('Info Pembayaran', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
          const Divider(height: 16),
          if (info['bank'] != null) InfoRow(label: 'Bank', value: info['bank']),
          if (info['account_number'] != null)
            InfoRow(label: 'No. Rekening', value: info['account_number'], bold: true, valueColor: AppColors.primary),
          if (info['account_name'] != null) InfoRow(label: 'Atas Nama', value: info['account_name']),
        ],
      ),
    );
  }
}
