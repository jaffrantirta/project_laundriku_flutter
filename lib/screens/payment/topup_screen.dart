import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
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
  TopupConfig? _config;
  bool _configLoading = true;
  final _amountCtrl = TextEditingController();
  bool _isSubmitting = false;
  PaymentModel? _createdPayment;

  final _quickAmounts = [50000, 100000, 200000, 500000, 1000000];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final res = await ApiService.getTopupConfig();
      setState(() {
        _config = TopupConfig.fromJson(res['data']);
        _configLoading = false;
      });
    } catch (_) {
      setState(() => _configLoading = false);
    }
  }

  Future<void> _submit() async {
    final raw = _amountCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
    final amount = int.tryParse(raw);
    if (amount == null || amount < (_config?.minAmount ?? 25000)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum topup ${CurrencyFormatter.format(_config?.minAmount ?? 25000)}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final res = await ApiService.createTopup(amount);
      setState(() => _createdPayment = PaymentModel.fromJson(res['data']));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    }
    setState(() => _isSubmitting = false);
  }

  void _contactWhatsApp() async {
    final wa = _config?.picWhatsapp;
    if (wa == null) return;
    final uri = Uri.parse('https://wa.me/$wa?text=Konfirmasi topup LaundriKu order ${_createdPayment?.orderId}');
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Topup Saldo')),
      body: _configLoading
          ? const Center(child: CircularProgressIndicator())
          : _createdPayment != null
              ? _buildSuccess()
              : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 20),
          const Text('Jumlah Topup', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: '0',
              prefixText: 'Rp ',
              prefixStyle: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickAmounts.map((a) => GestureDetector(
              onTap: () => _amountCtrl.text = a.toString(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Text(
                  CurrencyFormatter.compact(a),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 24),
          LoadingButton(
            isLoading: _isSubmitting,
            onPressed: _submit,
            label: 'Buat Topup',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    if (_config == null) return const SizedBox.shrink();
    return AppCard(
      color: AppColors.primary.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text('Informasi Topup', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
          const Divider(height: 16),
          InfoRow(label: 'Minimum Topup', value: CurrencyFormatter.format(_config!.minAmount)),
          InfoRow(label: 'Biaya Admin', value: _config!.adminFee == 0 ? 'Gratis' : CurrencyFormatter.format(_config!.adminFee)),
          InfoRow(label: 'Bank', value: _config!.paymentInfo['bank'] ?? '-'),
          InfoRow(label: 'No. Rekening', value: _config!.paymentInfo['account_number'] ?? '-'),
          InfoRow(label: 'Nama', value: _config!.paymentInfo['account_name'] ?? '-'),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    final p = _createdPayment!;
    final info = p.paymentInfo;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 44),
          ),
          const SizedBox(height: 16),
          const Text('Topup Berhasil Dibuat!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Transfer ke rekening berikut dan konfirmasi via WhatsApp', style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              children: [
                InfoRow(label: 'Order ID', value: p.orderId),
                InfoRow(label: 'Jumlah', value: CurrencyFormatter.format(p.grossAmount), bold: true),
                if (info != null) ...[
                  InfoRow(label: 'Bank', value: info['bank'] ?? '-'),
                  InfoRow(
                    label: 'No. Rekening',
                    value: info['account_number'] ?? '-',
                    valueColor: AppColors.primary,
                    bold: true,
                  ),
                  InfoRow(label: 'Nama', value: info['account_name'] ?? '-'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (info != null)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: info['account_number'] ?? ''));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No. rekening disalin'), behavior: SnackBarBehavior.floating),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.08),
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
          const SizedBox(height: 12),
          if (_config?.picWhatsapp != null)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _contactWhatsApp,
                icon: const Icon(Icons.chat_rounded),
                label: const Text('Konfirmasi via WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
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
