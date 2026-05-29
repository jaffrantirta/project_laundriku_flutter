import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/payment_model.dart';
import '../../data/services/api_service.dart';
import '../../widgets/app_widgets.dart';
import 'snap_webview_screen.dart';

class PaymentDetailScreen extends StatefulWidget {
  final int transactionId;
  const PaymentDetailScreen({super.key, required this.transactionId});

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  TransactionModel? _transaction;
  bool _loading = true;
  File? _proofFile;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getPaymentStatus(widget.transactionId);
      final data = (res['data'] ?? res) as Map<String, dynamic>;
      // Merge top-level fields (snap_redirect_url, bank_details) into the transaction map
      final txMap = Map<String, dynamic>.from(
        (data['transaction'] ?? data) as Map<String, dynamic>,
      );
      if (txMap['snap_redirect_url'] == null && data['snap_redirect_url'] != null) {
        txMap['snap_redirect_url'] = data['snap_redirect_url'];
      }
      if (txMap['bank_details'] == null && data['bank_details'] != null) {
        txMap['bank_details'] = data['bank_details'];
      }
      if (txMap['payment_method'] == null && data['payment_method'] != null) {
        txMap['payment_method'] = data['payment_method'];
      }
      setState(() {
        _transaction = TransactionModel.fromJson(txMap);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickProof() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Buka Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) setState(() => _proofFile = File(picked.path));
  }

  Future<void> _uploadProof() async {
    if (_proofFile == null) return;
    setState(() => _uploading = true);
    try {
      await ApiService.uploadPaymentProof(
        transactionId: widget.transactionId,
        proofImage: _proofFile!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bukti pembayaran berhasil dikirim!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    }
    if (mounted) setState(() => _uploading = false);
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label disalin'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detail Pembayaran')),
      body: _loading
          ? _buildSkeleton()
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
                        if (_transaction!.isPending) ...[
                          const SizedBox(height: 16),
                          _buildPaymentActionCard(),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatusCard() {
    final t = _transaction!;
    final isSuccess = t.statusValue == 2;
    final isFailed = t.statusValue == 3;
    final color = isSuccess ? AppColors.success : isFailed ? AppColors.error : AppColors.warning;
    final icon = isSuccess ? Icons.check_circle_rounded : isFailed ? Icons.cancel_rounded : Icons.hourglass_top_rounded;

    return GradientCard(
      colors: [color, color.withOpacity(0.7)],
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          Text(t.statusLabel, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(CurrencyFormatter.format(t.amount), style: const TextStyle(color: Colors.white70, fontSize: 16)),
          if (t.isPending && t.expiredAt != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white60, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Berlaku hingga ${DateFormatter.formatDateTime(t.expiredAt)}',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ],
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
          if (t.businessName != null && t.businessName!.isNotEmpty)
            InfoRow(label: 'Bisnis', value: t.businessName!),
          InfoRow(
            label: 'Jumlah',
            value: CurrencyFormatter.format(t.amount),
            bold: true,
            valueColor: AppColors.primary,
          ),
          if (t.paymentMethod != null)
            InfoRow(label: 'Metode Bayar', value: t.paymentMethodLabel),
          InfoRow(label: 'Status', value: t.statusLabel),
          if (t.notes != null && t.notes!.isNotEmpty)
            InfoRow(label: 'Catatan', value: t.notes!),
          if (t.confirmedAt != null)
            InfoRow(label: 'Dikonfirmasi', value: DateFormatter.formatDateTime(t.confirmedAt)),
          InfoRow(label: 'Dibuat', value: DateFormatter.formatDateTime(t.createdAt)),
        ],
      ),
    );
  }

  Widget _buildPaymentActionCard() {
    final t = _transaction!;

    final showSnap = t.isSnap ||
        t.paymentMethod == 'gopay' ||
        t.paymentMethod == 'qris';

    if (showSnap) {
      final url = t.snapRedirectUrl;
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selesaikan Pembayaran', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              url != null
                  ? 'Klik tombol di bawah untuk melanjutkan pembayaran.'
                  : 'Link pembayaran sedang disiapkan. Silakan coba beberapa saat lagi.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: url != null
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SnapWebViewScreen(snapUrl: url),
                          ),
                        )
                    : null,
                icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                label: const Text('Bayar Sekarang', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final bank = t.bankDetails;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_rounded, color: AppColors.warning, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Instruksi Pembayaran', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          if (bank != null) ...[
            _bankRow('Bank', bank.bankName),
            const SizedBox(height: 10),
            _bankRowCopy('No. Rekening', bank.accountNumber),
            const SizedBox(height: 10),
            _bankRow('Atas Nama', bank.accountName),
            const SizedBox(height: 10),
            _bankRowCopy('Jumlah Transfer', CurrencyFormatter.format(t.amount)),
            const Divider(height: 24),
          ],
          const Text(
            'Upload bukti transfer setelah melakukan pembayaran',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          if (_proofFile != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(_proofFile!, height: 160, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickProof,
                  icon: const Icon(Icons.image_rounded, size: 18),
                  label: Text(_proofFile == null ? 'Pilih Bukti' : 'Ganti Foto'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              if (_proofFile != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: LoadingButton(
                    isLoading: _uploading,
                    onPressed: _uploadProof,
                    label: 'Kirim Bukti',
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _bankRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _bankRowCopy(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ),
        GestureDetector(
          onTap: () => _copyToClipboard(value, label),
          child: const Icon(Icons.copy_rounded, size: 16, color: AppColors.textHint),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ShimmerLoading(height: 140, borderRadius: BorderRadius.circular(20)),
        const SizedBox(height: 16),
        ShimmerLoading(height: 220, borderRadius: BorderRadius.circular(16)),
        const SizedBox(height: 16),
        ShimmerLoading(height: 180, borderRadius: BorderRadius.circular(16)),
      ],
    );
  }
}
