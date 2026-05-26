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
  IdentityModel? _identity;
  bool _loading = true;
  bool _showForm = false;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nikCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _subDistrictCtrl = TextEditingController();
  final _occupationCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();
  File? _ktpFile;
  File? _selfieFile;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _nikCtrl.dispose();
    _addressCtrl.dispose();
    _provinceCtrl.dispose();
    _districtCtrl.dispose();
    _subDistrictCtrl.dispose();
    _occupationCtrl.dispose();
    _positionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getIdentityStatus();
      setState(() {
        _identity = IdentityModel.fromJson(res['data']);
        _loading = false;
      });
      if (_identity?.status == -1) {
        setState(() => _showForm = true);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickImage(bool isKtp) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        if (isKtp) {
          _ktpFile = File(picked.path);
        } else {
          _selfieFile = File(picked.path);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ktpFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto KTP wajib diisi'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_selfieFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto selfie wajib diisi'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ApiService.submitIdentity(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        nik: _nikCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        province: _provinceCtrl.text.trim(),
        district: _districtCtrl.text.trim(),
        subDistrict: _subDistrictCtrl.text.trim(),
        occupation: _occupationCtrl.text.trim(),
        position: _positionCtrl.text.trim(),
        ktpPhoto: _ktpFile!,
        selfiePhoto: _selfieFile!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Identitas berhasil disubmit! Menunggu verifikasi.'),
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
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
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
    final id = _identity;
    if (id == null || !id.hasIdentity) {
      return _buildNoIdentity();
    }
    Color statusColor;
    IconData statusIcon;
    switch (id.status) {
      case 1:
        statusColor = AppColors.success;
        statusIcon = Icons.verified_rounded;
        break;
      case -1:
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = AppColors.warning;
        statusIcon = Icons.hourglass_top_rounded;
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
            id.statusLabel ?? '',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: statusColor),
          ),
          const SizedBox(height: 8),
          Text(
            id.statusDescription ?? '',
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
          if (id.note != null && id.note!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Alasan Penolakan:', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.error)),
                  const SizedBox(height: 6),
                  Text(id.note!, style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
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
                child: const Text('Submit Ulang Identitas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
          if (id.status == 1 && id.identity != null) ...[
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Data Identitas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 12),
                  InfoRow(label: 'Nama', value: id.identity!['name'] ?? '-'),
                  InfoRow(label: 'NIK', value: id.identity!['nik'] ?? '-'),
                  InfoRow(label: 'Telepon', value: id.identity!['phone'] ?? '-'),
                  InfoRow(label: 'Pekerjaan', value: id.identity!['occupation'] ?? '-'),
                  InfoRow(label: 'Jabatan', value: id.identity!['position'] ?? '-'),
                ],
              ),
            ),
          ],
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
            'Lengkapi data KTP Anda untuk dapat melakukan penarikan saldo dan menikmati semua fitur LaundriKu',
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
              child: const Text('Mulai Verifikasi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
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
            const Text('Data Pribadi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            _field(_nameCtrl, 'Nama Sesuai KTP', Icons.person_outline, required: true),
            const SizedBox(height: 12),
            _field(_phoneCtrl, 'No. WhatsApp/Telepon', Icons.phone_outlined, type: TextInputType.phone, required: true),
            const SizedBox(height: 12),
            _field(_nikCtrl, 'NIK (16 digit)', Icons.badge_outlined, type: TextInputType.number, required: true, maxLen: 16),
            const SizedBox(height: 12),
            _field(_addressCtrl, 'Alamat Lengkap', Icons.location_on_outlined, required: true, maxLines: 3),
            const SizedBox(height: 20),
            const Text('Wilayah', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            _field(_provinceCtrl, 'Kode Provinsi', Icons.map_outlined, required: true),
            const SizedBox(height: 12),
            _field(_districtCtrl, 'Kode Kabupaten/Kota', Icons.location_city_outlined, required: true),
            const SizedBox(height: 12),
            _field(_subDistrictCtrl, 'Kode Kecamatan', Icons.near_me_outlined, required: true),
            const SizedBox(height: 20),
            const Text('Pekerjaan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            _field(_occupationCtrl, 'Pekerjaan', Icons.work_outline, required: true),
            const SizedBox(height: 12),
            _field(_positionCtrl, 'Jabatan', Icons.badge_outlined, required: true),
            const SizedBox(height: 20),
            const Text('Foto Dokumen', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            _buildPhotoField('Foto KTP', _ktpFile, () => _pickImage(true)),
            const SizedBox(height: 12),
            _buildPhotoField('Foto Selfie dengan KTP', _selfieFile, () => _pickImage(false)),
            const SizedBox(height: 24),
            LoadingButton(isLoading: _isSubmitting, onPressed: _submit, label: 'Kirim untuk Verifikasi'),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? type,
    bool required = false,
    int? maxLen,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      maxLength: maxLen,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        counterText: '',
      ),
      validator: required ? (v) => v == null || v.trim().isEmpty ? '$label wajib diisi' : null : null,
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
                        decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppColors.textSecondary),
                  const SizedBox(height: 8),
                  Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const Text('Ketuk untuk memilih foto', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                ],
              ),
      ),
    );
  }
}
