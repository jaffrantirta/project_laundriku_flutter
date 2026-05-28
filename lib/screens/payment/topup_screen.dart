import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_constants.dart';
import 'snap_webview_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/payment_model.dart';
import '../../data/services/api_service.dart';
import '../../widgets/app_widgets.dart';

class TopupScreen extends StatefulWidget {
  const TopupScreen({super.key});

  @override
  State<TopupScreen> createState() => _TopupScreenState();
}

class _TopupScreenState extends State<TopupScreen> {
  String _paymentMethod = 'manual_transfer';
  bool _isSubmitting = false;
  bool _isLoadingConfig = true;
  InitialDepositModel? _createdDeposit;
  bool _isUploadingProof = false;
  File? _proofFile;
  int _depositAmount = AppConstants.initialDepositAmount;
  bool _alreadyPaid = false;
  bool _isVerified = true; // assume true until loaded to avoid flicker

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([
      _loadVerificationStatus(),
      _loadExistingDeposit(),
    ]);
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

  Future<void> _loadExistingDeposit() async {
    try {
      final res = await ApiService.getPaymentHistory(type: 'initial_deposit', perPage: 1);
      final data = res['data'] as Map<String, dynamic>?;
      final items = data?['data'] as List<dynamic>?;
      if (items != null && items.isNotEmpty) {
        final tx = TransactionModel.fromJson(items.first as Map<String, dynamic>);
        if (tx.status == 'success') {
          if (mounted) setState(() => _alreadyPaid = true);
          return;
        }
        if (tx.status == 'pending') {
          // Existing pending deposit — reconstruct so we can show payment details
          // Re-fetch full detail via payment status
          final detail = await ApiService.getPaymentStatus(tx.id);
          final detailData = (detail['data'] ?? detail) as Map<String, dynamic>;
          final detailTx = TransactionModel.fromJson(detailData['transaction'] ?? detailData);
          if (mounted) {
            setState(() {
              _depositAmount = detailTx.amount > 0 ? detailTx.amount : tx.amount;
              _createdDeposit = InitialDepositModel(
                transaction: detailTx,
                bankDetails: detailData['bank_details'] != null
                    ? BankDetailsModel.fromJson(detailData['bank_details'] as Map<String, dynamic>)
                    : null,
              );
              _isLoadingConfig = false;
            });
          }
          return;
        }
        // Transaction exists but not pending — just take the amount for the form
        if (tx.amount > 0 && mounted) {
          setState(() => _depositAmount = tx.amount);
        }
      }
    } catch (_) {
      // Ignore — show form with constant amount
    }
    if (mounted) setState(() => _isLoadingConfig = false);
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final res = await ApiService.payInitialDeposit(_paymentMethod);
      final model = InitialDepositModel.fromJson(res);
      setState(() {
        _createdDeposit = model;
        if (model.transaction.amount > 0) _depositAmount = model.transaction.amount;
      });
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

  Future<void> _pickProof() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _proofFile = File(picked.path));
  }

  Future<void> _uploadProof() async {
    if (_proofFile == null || _createdDeposit == null) return;
    setState(() => _isUploadingProof = true);
    try {
      await ApiService.uploadPaymentProof(
        transactionId: _createdDeposit!.transaction.id,
        proofImage: _proofFile!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bukti pembayaran berhasil dikirim! Menunggu konfirmasi admin.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
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
    setState(() => _isUploadingProof = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Deposit Awal')),
      body: _isLoadingConfig
          ? _buildSkeleton()
          : !_isVerified
              ? _buildNotVerified()
              : _alreadyPaid
                  ? _buildAlreadyPaid()
                  : _createdDeposit != null
                      ? _buildSuccess()
                      : _buildForm(),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ShimmerLoading(height: 110, borderRadius: BorderRadius.circular(20)),
        const SizedBox(height: 24),
        ShimmerLoading(height: 20, width: 160, borderRadius: BorderRadius.circular(8)),
        const SizedBox(height: 12),
        ShimmerLoading(height: 72, borderRadius: BorderRadius.circular(12)),
        const SizedBox(height: 10),
        ShimmerLoading(height: 72, borderRadius: BorderRadius.circular(12)),
        const SizedBox(height: 28),
        ShimmerLoading(height: 52, borderRadius: BorderRadius.circular(12)),
      ],
    );
  }

  Widget _buildNotVerified() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.badge_outlined, color: AppColors.warning, size: 52),
            ),
            const SizedBox(height: 24),
            const Text(
              'Identitas Belum Diverifikasi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Anda perlu menyelesaikan verifikasi identitas terlebih dahulu sebelum melakukan deposit awal.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Kembali'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientCard(
            colors: const [AppColors.primary, AppColors.primaryLight],
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Deposit Awal', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      CurrencyFormatter.format(_depositAmount),
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const Text('Satu kali pembayaran untuk aktivasi', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          _buildMethodTile(
            'manual_transfer',
            'Transfer Bank Manual',
            'Konfirmasi via upload bukti transfer',
            Icons.account_balance_rounded,
          ),
          const SizedBox(height: 10),
          _buildMethodTile(
            'gopay',
            'GoPay / QRIS',
            'Bayar via Midtrans Snap, konfirmasi otomatis',
            Icons.qr_code_rounded,
          ),
          const SizedBox(height: 28),
          LoadingButton(
            isLoading: _isSubmitting,
            onPressed: _submit,
            label: 'Lanjutkan Pembayaran',
          ),
        ],
      ),
    );
  }

  Widget _buildMethodTile(String value, String label, String subtitle, IconData icon) {
    final selected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (selected ? AppColors.primary : AppColors.textHint).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: selected ? AppColors.primary : AppColors.textHint, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? AppColors.primary : AppColors.textPrimary)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.primary : AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlreadyPaid() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_rounded, color: AppColors.success, size: 52),
            ),
            const SizedBox(height: 24),
            const Text(
              'Deposit Awal Sudah Lunas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Anda sudah melakukan deposit awal sebelumnya. Tidak perlu membayar lagi.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Kembali'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    final deposit = _createdDeposit!;
    final isSnap = deposit.isSnap;
    final bank = deposit.bankDetails;
    final amount = deposit.transaction.amount > 0 ? deposit.transaction.amount : _depositAmount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 44),
          ),
          const SizedBox(height: 16),
          const Text('Pembayaran Dibuat!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            isSnap
                ? 'Selesaikan pembayaran melalui halaman Midtrans Snap'
                : 'Transfer ke rekening berikut dan upload bukti pembayaran',
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              children: [
                InfoRow(label: 'ID Transaksi', value: '#${deposit.transaction.id}'),
                InfoRow(
                  label: 'Jumlah',
                  value: CurrencyFormatter.format(amount),
                  bold: true,
                  valueColor: AppColors.primary,
                ),
                if (bank != null) ...[
                  InfoRow(label: 'Bank', value: bank.bankName),
                  InfoRow(
                    label: 'No. Rekening',
                    value: bank.accountNumber,
                    valueColor: AppColors.primary,
                    bold: true,
                  ),
                  InfoRow(label: 'Nama', value: bank.accountName),
                ],
              ],
            ),
          ),
          if (isSnap) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pilih metode pembayaran (GoPay, QRIS, dll.) di halaman Snap Midtrans.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SnapWebViewScreen(
                      snapUrl: deposit.snapRedirectUrl!,
                      title: 'Deposit Awal',
                    ),
                  ),
                ),
                icon: const Icon(Icons.payment_rounded),
                label: const Text('Bayar Sekarang'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            if (bank != null)
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: bank.accountNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No. rekening disalin'), behavior: SnackBarBehavior.floating),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.copy_rounded, color: AppColors.info, size: 18),
                      SizedBox(width: 8),
                      Text('Salin Nomor Rekening', style: TextStyle(color: AppColors.info, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Text('Upload Bukti Transfer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickProof,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _proofFile != null ? AppColors.primary : AppColors.divider,
                    width: _proofFile != null ? 2 : 1,
                  ),
                ),
                child: _proofFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_proofFile!, fit: BoxFit.cover),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                                child: const Icon(Icons.check, color: Colors.white, size: 14),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppColors.textSecondary),
                          SizedBox(height: 8),
                          Text('Pilih foto bukti transfer', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          Text('Ketuk untuk memilih', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            LoadingButton(
              isLoading: _isUploadingProof,
              onPressed: _proofFile != null ? _uploadProof : null,
              label: 'Kirim Bukti Pembayaran',
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Kembali'),
            ),
          ),
        ],
      ),
    );
  }
}
