import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/leaderboard_model.dart';
import '../../data/services/api_service.dart';
import '../../widgets/app_widgets.dart';

class IdentityScreen extends StatefulWidget {
  const IdentityScreen({super.key});

  @override
  State<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends State<IdentityScreen> {
  VerificationStatusModel? _status;
  bool _loading = true;
  bool _showForm = false;

  final _formKey = GlobalKey<FormState>();
  String _selectedIdType = 'ktp';
  final _idNumberCtrl = TextEditingController();
  File? _idPhotoFile;
  File? _selfieFile;
  bool _isSubmitting = false;

  final _idTypes = [
    {'value': 'ktp', 'label': 'KTP'},
    {'value': 'sim', 'label': 'SIM'},
    {'value': 'passport', 'label': 'Paspor'},
  ];

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _idNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getVerificationStatus();
      final model = VerificationStatusModel.fromJson(res);
      setState(() {
        _status = model;
        _loading = false;
      });
      if (!model.hasSubmitted) {
        setState(() => _showForm = true);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickImage(bool isId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        if (isId) {
          _idPhotoFile = File(picked.path);
        } else {
          _selfieFile = File(picked.path);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idPhotoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto identitas wajib diisi'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ApiService.uploadVerification(
        idType: _selectedIdType,
        idNumber: _idNumberCtrl.text.trim(),
        idPhoto: _idPhotoFile!,
        selfiePhoto: _selfieFile,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dokumen identitas berhasil dikirim! Menunggu verifikasi.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _showForm = false);
        _loadStatus();
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
      appBar: AppBar(title: const Text('Verifikasi Identitas')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _showForm
              ? _buildForm()
              : _buildStatus(),
    );
  }

  Widget _buildStatus() {
    final s = _status;
    if (s == null || !s.hasSubmitted) {
      return _buildNoIdentity();
    }

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    String statusDescription;

    if (s.isVerified) {
      statusColor = AppColors.success;
      statusIcon = Icons.verified_rounded;
      statusLabel = 'Identitas Terverifikasi';
      statusDescription = 'Identitas Anda telah berhasil diverifikasi.';
    } else if (s.isRejected) {
      statusColor = AppColors.error;
      statusIcon = Icons.cancel_rounded;
      statusLabel = 'Identitas Ditolak';
      statusDescription = 'Dokumen identitas Anda ditolak. Silakan submit ulang.';
    } else {
      statusColor = AppColors.warning;
      statusIcon = Icons.hourglass_top_rounded;
      statusLabel = 'Sedang Diverifikasi';
      statusDescription = 'Dokumen identitas Anda sedang dalam proses review.';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            statusLabel,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: statusColor),
          ),
          const SizedBox(height: 8),
          Text(
            statusDescription,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
          if (s.isRejected) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => setState(() => _showForm = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Submit Ulang Identitas',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
          if (s.isVerified) ...[
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status Onboarding',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  _stepRow('Upload Identitas', s.idUploaded),
                  _stepRow('Identitas Disetujui', s.idApproved),
                  _stepRow('Deposit Awal Dibayar', s.depositPaid),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stepRow(String label, bool done) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: (done ? AppColors.success : AppColors.textHint).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              done ? Icons.check_rounded : Icons.radio_button_unchecked_rounded,
              size: 16,
              color: done ? AppColors.success : AppColors.textHint,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: done ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: done ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoIdentity() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.badge_outlined, color: AppColors.primary, size: 44),
          ),
          const SizedBox(height: 20),
          const Text('Verifikasi Identitas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          const Text(
            'Lengkapi data identitas Anda untuk dapat melakukan penarikan saldo dan menikmati semua fitur BisnisKu',
            style: TextStyle(color: AppColors.textSecondary, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildFeaturePoint(Icons.account_balance_wallet_rounded, 'Aktifkan fitur penarikan saldo'),
          const SizedBox(height: 12),
          _buildFeaturePoint(Icons.security_rounded, 'Keamanan akun lebih terjamin'),
          const SizedBox(height: 12),
          _buildFeaturePoint(Icons.verified_rounded, 'Status terverifikasi di profil'),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => setState(() => _showForm = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Mulai Verifikasi',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePoint(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.success, size: 18),
        ),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Jenis Identitas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedIdType,
                  isExpanded: true,
                  items: _idTypes.map((t) => DropdownMenuItem(
                    value: t['value'],
                    child: Text(t['label']!),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedIdType = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Nomor Identitas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _idNumberCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nomor KTP / SIM / Paspor',
                prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primary),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Nomor identitas wajib diisi' : null,
            ),
            const SizedBox(height: 20),
            const Text('Foto Dokumen', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            _buildPhotoField('Foto KTP / SIM / Paspor', _idPhotoFile, () => _pickImage(true)),
            const SizedBox(height: 12),
            _buildPhotoField('Foto Selfie dengan Identitas (Opsional)', _selfieFile, () => _pickImage(false)),
            const SizedBox(height: 24),
            LoadingButton(isLoading: _isSubmitting, onPressed: _submit, label: 'Kirim untuk Verifikasi'),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoField(String label, File? file, VoidCallback onPick) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: file != null ? AppColors.primary : AppColors.divider,
            width: file != null ? 2 : 1,
          ),
        ),
        child: file != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(file, fit: BoxFit.cover),
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
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_outlined, size: 32, color: AppColors.textSecondary),
                  const SizedBox(height: 8),
                  Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const Text('Ketuk untuk membuka kamera', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                ],
              ),
      ),
    );
  }
}
