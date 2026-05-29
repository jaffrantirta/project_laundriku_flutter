import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../payment/snap_webview_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/leaderboard_model.dart';
import '../../data/models/payment_model.dart';
import '../../data/services/api_service.dart';
import '../../widgets/app_widgets.dart';

class GroupDetailScreen extends StatefulWidget {
  final int businessId;
  final String businessName;

  const GroupDetailScreen({super.key, required this.businessId, required this.businessName});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  BusinessDetailModel? _business;
  bool _loading = true;
  bool _isInvesting = false;
  String _paymentType = 'full';
  String _paymentMethod = 'manual_transfer';
  int _tenureMonths = 12;

  // Set after successful investment — switches to payment view
  InitialDepositModel? _investPayment;
  bool _isUploadingProof = false;
  File? _proofFile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getBusinessDetail(widget.businessId);
      setState(() {
        _business = BusinessDetailModel.fromJson(res);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _invest() async {
    setState(() => _isInvesting = true);
    try {
      final res = await ApiService.investInBusiness(
        businessId: widget.businessId,
        paymentType: _paymentType,
        tenureMonths: _paymentType == 'installment' ? _tenureMonths : null,
        paymentMethod: _paymentMethod,
      );

      // Parse the invest response — same structure as initial deposit
      final data = (res['data'] ?? res) as Map<String, dynamic>;
      final txData = (data['transaction'] ?? data) as Map<String, dynamic>;
      final tx = TransactionModel.fromJson(txData);
      final bankDetails = data['bank_details'] != null
          ? BankDetailsModel.fromJson(data['bank_details'] as Map<String, dynamic>)
          : null;
      final payment = InitialDepositModel(transaction: tx, bankDetails: bankDetails);

      if (mounted) {
        Navigator.pop(context); // close bottom sheet
        setState(() => _investPayment = payment);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close bottom sheet so SnackBar is visible
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    if (mounted) setState(() => _isInvesting = false);
  }

  Future<void> _pickProof() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _proofFile = File(picked.path));
  }

  Future<void> _uploadProof() async {
    if (_proofFile == null || _investPayment == null) return;
    setState(() => _isUploadingProof = true);
    try {
      await ApiService.uploadPaymentProof(
        transactionId: _investPayment!.transaction.id,
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

  void _showInvestSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Investasi Sekarang', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                _business?.name ?? '',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),
              const Text('Tipe Pembayaran', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _paymentTypeChip('full', 'Lunas', setSheetState),
                  const SizedBox(width: 10),
                  _paymentTypeChip('installment', 'Cicilan', setSheetState),
                ],
              ),
              if (_paymentType == 'installment') ...[
                const SizedBox(height: 16),
                const Text('Durasi Cicilan (bulan)', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [3, 6, 9, 12].map((m) => ChoiceChip(
                    label: Text('$m bln'),
                    selected: _tenureMonths == m,
                    onSelected: (_) => setSheetState(() => _tenureMonths = m),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  )).toList(),
                ),
              ],
              const SizedBox(height: 16),
              const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _methodChip('manual_transfer', 'Transfer Bank', setSheetState),
                  const SizedBox(width: 10),
                  _methodChip('gopay', 'GoPay / QRIS', setSheetState),
                ],
              ),
              const SizedBox(height: 24),
              LoadingButton(
                isLoading: _isInvesting,
                onPressed: _invest,
                label: 'Konfirmasi Investasi',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentTypeChip(String value, String label, StateSetter setSheetState) {
    final selected = _paymentType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setSheetState(() => _paymentType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _methodChip(String value, String label, StateSetter setSheetState) {
    final selected = _paymentMethod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setSheetState(() => _paymentMethod = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.businessName)),
      body: _loading
          ? _buildSkeleton()
          : _business == null
              ? const EmptyState(title: 'Gagal memuat bisnis', icon: Icons.error_outline_rounded)
              : _investPayment != null
                  ? _buildPaymentView()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: _buildMainCard(),
                            ),
                          ),
                          if (_business!.isOpen)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                                child: LoadingButton(
                                  isLoading: _isInvesting,
                                  onPressed: _showInvestSheet,
                                  label: 'Investasi Sekarang',
                                ),
                              ),
                            ),
                          const SliverToBoxAdapter(child: SizedBox(height: 100)),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildPaymentView() {
    final payment = _investPayment!;
    final isSnap = payment.isSnap;
    final bank = payment.bankDetails;
    final amount = payment.transaction.amount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 40),
          ),
          const SizedBox(height: 14),
          const Text('Investasi Dibuat!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            isSnap
                ? 'Selesaikan pembayaran melalui halaman Midtrans Snap'
                : 'Transfer ke rekening berikut lalu upload bukti',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          AppCard(
            child: Column(
              children: [
                InfoRow(label: 'ID Transaksi', value: '#${payment.transaction.id}'),
                InfoRow(
                  label: 'Jumlah',
                  value: CurrencyFormatter.format(amount),
                  bold: true,
                  valueColor: AppColors.primary,
                ),
                InfoRow(label: 'Bisnis', value: widget.businessName),
                if (bank != null) ...[
                  const Divider(height: 20),
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
            const SizedBox(height: 16),
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
                      snapUrl: payment.snapRedirectUrl!,
                      title: 'Pembayaran Investasi',
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
            if (bank != null) ...[
              const SizedBox(height: 12),
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
            ],
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _businessStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard() {
    final b = _business!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: b.imageUrl != null && b.imageUrl!.isNotEmpty
                ? Image.network(
                    b.imageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                  )
                : _buildImagePlaceholder(),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text(b.category,
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (b.isOpen ? AppColors.success : AppColors.textHint)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        b.isOpen ? 'Terbuka' : 'Penuh',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: b.isOpen ? AppColors.success : AppColors.textHint,
                        ),
                      ),
                    ),
                  ],
                ),

                // Location
                if (b.location != null && b.location!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 14, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(b.location!,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Investor progress stats
                Row(
                  children: [
                    _businessStat('Investor',
                        '${b.currentInvestors}/${b.targetInvestors}'),
                    const SizedBox(width: 10),
                    _businessStat(
                        'Status', b.isOpen ? 'Terbuka' : 'Penuh'),
                    if ((b.investmentAmount ?? 0) > 0) ...[
                      const SizedBox(width: 10),
                      _businessStat('Harga/Slot',
                          CurrencyFormatter.compact(b.investmentAmount!)),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: b.investorProgress,
                    backgroundColor: AppColors.divider,
                    color: AppColors.primary,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(b.investorProgress * 100).toStringAsFixed(0)}% slot terisi',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),

                // Profit sharing + return period chips
                if (b.profitSharingPercent != null || b.returnPeriod != null) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (b.profitSharingPercent != null)
                        _infoChip(Icons.trending_up_rounded,
                            'Bagi Hasil',
                            '${b.profitSharingPercent!.toStringAsFixed(1)}%',
                            AppColors.success),
                      if (b.returnPeriod != null && b.returnPeriod!.isNotEmpty)
                        _infoChip(Icons.calendar_month_rounded,
                            'Periode Return', b.returnPeriod!, AppColors.info),
                      if (b.establishedYear != null && b.establishedYear!.isNotEmpty)
                        _infoChip(Icons.storefront_rounded,
                            'Berdiri', b.establishedYear!, AppColors.accent),
                      if (b.contactInfo != null && b.contactInfo!.isNotEmpty)
                        _infoChip(Icons.phone_rounded,
                            'Kontak', b.contactInfo!, AppColors.primary),
                    ],
                  ),
                ],

                // Description
                if (b.description != null && b.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  const Text('Tentang Bisnis',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    b.description!,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.6),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary)),
              Text(value,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentDetails() {
    final b = _business!;
    final hasAmount = (b.investmentAmount ?? 0) > 0;
    final hasProfit = b.profitSharingPercent != null;
    final hasReturn = b.returnPeriod != null && b.returnPeriod!.isNotEmpty;
    final hasMin = (b.minInvestment ?? 0) > 0;
    if (!hasAmount && !hasProfit && !hasReturn && !hasMin) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Detail Investasi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (hasAmount)
                _detailChip(
                  Icons.payments_rounded,
                  'Harga per Slot',
                  CurrencyFormatter.format(b.investmentAmount!),
                  AppColors.primary,
                ),
              if (hasMin)
                _detailChip(
                  Icons.account_balance_wallet_rounded,
                  'Min. Investasi',
                  CurrencyFormatter.format(b.minInvestment!),
                  AppColors.info,
                ),
              if (hasProfit)
                _detailChip(
                  Icons.trending_up_rounded,
                  'Bagi Hasil',
                  '${b.profitSharingPercent!.toStringAsFixed(1)}%',
                  AppColors.success,
                ),
              if (hasReturn)
                _detailChip(
                  Icons.calendar_month_rounded,
                  'Periode Return',
                  b.returnPeriod!,
                  AppColors.accent,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailChip(IconData icon, String label, String value, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 76) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tentang Bisnis', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          Text(
            _business!.description!,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessInfo() {
    final b = _business!;
    final rows = <_InfoEntry>[];
    if (b.location != null && b.location!.isNotEmpty)
      rows.add(_InfoEntry(Icons.location_on_rounded, 'Lokasi', b.location!));
    if (b.establishedYear != null && b.establishedYear!.isNotEmpty)
      rows.add(_InfoEntry(Icons.calendar_today_rounded, 'Berdiri', b.establishedYear!));
    if (b.contactInfo != null && b.contactInfo!.isNotEmpty)
      rows.add(_InfoEntry(Icons.phone_rounded, 'Kontak', b.contactInfo!));
    rows.add(_InfoEntry(Icons.category_rounded, 'Kategori', b.category));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Informasi Bisnis', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 14),
          ...rows.asMap().entries.map((e) => Column(
                children: [
                  _infoRow(e.value.icon, e.value.label, e.value.value),
                  if (e.key < rows.length - 1) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                  ],
                ],
              )),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.business_rounded, color: Colors.white54, size: 56),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ShimmerLoading(height: 200, borderRadius: BorderRadius.circular(20)),
        const SizedBox(height: 16),
        ShimmerLoading(height: 120, borderRadius: BorderRadius.circular(16)),
        const SizedBox(height: 12),
        ShimmerLoading(height: 100, borderRadius: BorderRadius.circular(16)),
        const SizedBox(height: 12),
        ShimmerLoading(height: 80, borderRadius: BorderRadius.circular(16)),
        const SizedBox(height: 24),
        ShimmerLoading(height: 52, borderRadius: BorderRadius.circular(12)),
      ],
    );
  }
}

class _InfoEntry {
  final IconData icon;
  final String label;
  final String value;
  const _InfoEntry(this.icon, this.label, this.value);
}
