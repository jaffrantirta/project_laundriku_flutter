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

  // Identity fields
  String _selectedIdType = 'ktp';
  final _idNumberCtrl = TextEditingController();

  // Personal data fields
  final _fullNameCtrl = TextEditingController();
  final _placeOfBirthCtrl = TextEditingController();
  DateTime? _dateOfBirth;
  final _phoneCtrl = TextEditingController();
  final _occupationCtrl = TextEditingController();
  String? _maritalStatus;

  // Address fields
  String? _selectedProvince;
  final _kabupatenCtrl = TextEditingController();
  final _kecamatanCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // Photos
  File? _idPhotoFile;
  File? _selfieFile;
  bool _isSubmitting = false;

  final _idTypes = [
    {'value': 'ktp', 'label': 'KTP'},
    {'value': 'sim', 'label': 'SIM'},
    {'value': 'passport', 'label': 'Paspor'},
  ];

  final _maritalStatuses = [
    {'value': 'single', 'label': 'Belum Menikah'},
    {'value': 'married', 'label': 'Menikah'},
    {'value': 'divorced', 'label': 'Cerai Hidup'},
    {'value': 'widowed', 'label': 'Cerai Mati'},
  ];

  final _provinces = [
    {'value': 'aceh', 'label': 'Aceh'},
    {'value': 'sumatera_utara', 'label': 'Sumatera Utara'},
    {'value': 'sumatera_barat', 'label': 'Sumatera Barat'},
    {'value': 'riau', 'label': 'Riau'},
    {'value': 'kepulauan_riau', 'label': 'Kepulauan Riau'},
    {'value': 'jambi', 'label': 'Jambi'},
    {'value': 'sumatera_selatan', 'label': 'Sumatera Selatan'},
    {'value': 'bangka_belitung', 'label': 'Kepulauan Bangka Belitung'},
    {'value': 'bengkulu', 'label': 'Bengkulu'},
    {'value': 'lampung', 'label': 'Lampung'},
    {'value': 'banten', 'label': 'Banten'},
    {'value': 'dki_jakarta', 'label': 'DKI Jakarta'},
    {'value': 'jawa_barat', 'label': 'Jawa Barat'},
    {'value': 'jawa_tengah', 'label': 'Jawa Tengah'},
    {'value': 'diy', 'label': 'DI Yogyakarta'},
    {'value': 'jawa_timur', 'label': 'Jawa Timur'},
    {'value': 'bali', 'label': 'Bali'},
    {'value': 'nusa_tenggara_barat', 'label': 'Nusa Tenggara Barat'},
    {'value': 'nusa_tenggara_timur', 'label': 'Nusa Tenggara Timur'},
    {'value': 'kalimantan_barat', 'label': 'Kalimantan Barat'},
    {'value': 'kalimantan_tengah', 'label': 'Kalimantan Tengah'},
    {'value': 'kalimantan_selatan', 'label': 'Kalimantan Selatan'},
    {'value': 'kalimantan_timur', 'label': 'Kalimantan Timur'},
    {'value': 'kalimantan_utara', 'label': 'Kalimantan Utara'},
    {'value': 'sulawesi_utara', 'label': 'Sulawesi Utara'},
    {'value': 'gorontalo', 'label': 'Gorontalo'},
    {'value': 'sulawesi_tengah', 'label': 'Sulawesi Tengah'},
    {'value': 'sulawesi_barat', 'label': 'Sulawesi Barat'},
    {'value': 'sulawesi_selatan', 'label': 'Sulawesi Selatan'},
    {'value': 'sulawesi_tenggara', 'label': 'Sulawesi Tenggara'},
    {'value': 'maluku', 'label': 'Maluku'},
    {'value': 'maluku_utara', 'label': 'Maluku Utara'},
    {'value': 'papua_barat', 'label': 'Papua Barat'},
    {'value': 'papua', 'label': 'Papua'},
    {'value': 'papua_selatan', 'label': 'Papua Selatan'},
    {'value': 'papua_tengah', 'label': 'Papua Tengah'},
    {'value': 'papua_pegunungan', 'label': 'Papua Pegunungan'},
    {'value': 'papua_barat_daya', 'label': 'Papua Barat Daya'},
  ];

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _idNumberCtrl.dispose();
    _fullNameCtrl.dispose();
    _placeOfBirthCtrl.dispose();
    _phoneCtrl.dispose();
    _occupationCtrl.dispose();
    _kabupatenCtrl.dispose();
    _kecamatanCtrl.dispose();
    _addressCtrl.dispose();
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
    final picked = await picker.pickImage(source: source, maxWidth: 1200, imageQuality: 80);
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 17, now.month, now.day),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

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
        fullName: _fullNameCtrl.text.trim(),
        placeOfBirth: _placeOfBirthCtrl.text.trim(),
        dateOfBirth: _dateOfBirth != null
            ? '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}'
            : null,
        phoneNumber: _phoneCtrl.text.trim(),
        occupation: _occupationCtrl.text.trim(),
        maritalStatus: _maritalStatus,
        province: _selectedProvince,
        kabupaten: _kabupatenCtrl.text.trim(),
        kecamatan: _kecamatanCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
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
          ? _buildSkeleton()
          : _showForm
              ? _buildForm()
              : _buildStatus(),
    );
  }

  Widget _buildStatus() {
    final s = _status;
    if (s == null || !s.hasSubmitted) return _buildNoIdentity();

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
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 48),
          ),
          const SizedBox(height: 16),
          Text(statusLabel, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: statusColor)),
          const SizedBox(height: 8),
          Text(statusDescription,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center),
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
                child: const Text('Submit Ulang Identitas',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
          if (s.isVerified) ...[
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Status Onboarding', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
              color: (done ? AppColors.success : AppColors.textHint).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              done ? Icons.check_rounded : Icons.radio_button_unchecked_rounded,
              size: 16,
              color: done ? AppColors.success : AppColors.textHint,
            ),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                fontSize: 14,
                color: done ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: done ? FontWeight.w600 : FontWeight.w400,
              )),
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
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.badge_outlined, color: AppColors.primary, size: 44),
          ),
          const SizedBox(height: 20),
          const Text('Verifikasi Identitas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          const Text(
            'Lengkapi data identitas Anda untuk dapat melakukan penarikan saldo dan menikmati semua fitur MyBisnis',
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
              child: const Text('Mulai Verifikasi',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
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
            color: AppColors.success.withValues(alpha: 0.1),
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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section 1: Dokumen Identitas ──────────────────────────────
            _sectionHeader('Dokumen Identitas', Icons.badge_outlined),
            const SizedBox(height: 12),
            _label('Jenis Identitas'),
            const SizedBox(height: 8),
            _dropdown<String>(
              value: _selectedIdType,
              items: _idTypes.map((t) => DropdownMenuItem(value: t['value'], child: Text(t['label']!))).toList(),
              onChanged: (val) { if (val != null) setState(() => _selectedIdType = val); },
            ),
            const SizedBox(height: 14),
            _label('Nomor Identitas'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _idNumberCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Nomor KTP / SIM / Paspor',
                prefixIcon: Icon(Icons.numbers_rounded, color: AppColors.primary),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Nomor identitas wajib diisi' : null,
            ),

            // ── Section 2: Data Diri ──────────────────────────────────────
            const SizedBox(height: 24),
            _sectionHeader('Data Diri', Icons.person_outlined),
            const SizedBox(height: 12),
            _label('Nama Lengkap (sesuai identitas)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _fullNameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Nama lengkap',
                prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 14),
            _label('Tempat Lahir'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _placeOfBirthCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Kota / Kabupaten',
                prefixIcon: Icon(Icons.location_city_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 14),
            _label('Tanggal Lahir'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _dateOfBirth != null ? _formatDate(_dateOfBirth!) : 'Pilih tanggal lahir',
                      style: TextStyle(
                        fontSize: 14,
                        color: _dateOfBirth != null ? AppColors.textPrimary : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _label('Nomor Telepon'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '08xxxxxxxxxx',
                prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 14),
            _label('Pekerjaan'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _occupationCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Wiraswasta, Karyawan, dll.',
                prefixIcon: Icon(Icons.work_outline_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 14),
            _label('Status Pernikahan'),
            const SizedBox(height: 8),
            _dropdown<String?>(
              value: _maritalStatus,
              hint: 'Pilih status pernikahan',
              items: _maritalStatuses
                  .map((m) => DropdownMenuItem(value: m['value'], child: Text(m['label']!)))
                  .toList(),
              onChanged: (val) => setState(() => _maritalStatus = val),
            ),

            // ── Section 3: Alamat ─────────────────────────────────────────
            const SizedBox(height: 24),
            _sectionHeader('Alamat', Icons.home_outlined),
            const SizedBox(height: 12),
            _label('Provinsi'),
            const SizedBox(height: 8),
            _dropdown<String?>(
              value: _selectedProvince,
              hint: 'Pilih provinsi',
              items: _provinces
                  .map((p) => DropdownMenuItem(value: p['value'], child: Text(p['label']!)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedProvince = val),
            ),
            const SizedBox(height: 14),
            _label('Kabupaten / Kota'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _kabupatenCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Kab. / Kota',
                prefixIcon: Icon(Icons.map_outlined, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 14),
            _label('Kecamatan'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _kecamatanCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Kecamatan',
                prefixIcon: Icon(Icons.place_outlined, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 14),
            _label('Alamat Lengkap'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Jl. Nama Jalan No. XX, RT/RW, Kelurahan',
                alignLabelWithHint: true,
              ),
            ),

            // ── Section 4: Foto Dokumen ───────────────────────────────────
            const SizedBox(height: 24),
            _sectionHeader('Foto Dokumen', Icons.camera_alt_outlined),
            const SizedBox(height: 12),
            _buildPhotoField('Foto KTP / SIM / Paspor *', _idPhotoFile, () => _pickImage(true)),
            const SizedBox(height: 12),
            _buildPhotoField('Foto Selfie dengan Identitas (Opsional)', _selfieFile, () => _pickImage(false)),

            const SizedBox(height: 28),
            LoadingButton(isLoading: _isSubmitting, onPressed: _submit, label: 'Kirim untuk Verifikasi'),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary));

  Widget _dropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: hint != null ? Text(hint, style: const TextStyle(color: AppColors.textHint)) : null,
          items: items,
          onChanged: onChanged,
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
        alignment: Alignment.center,
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppColors.textSecondary),
                  const SizedBox(height: 8),
                  Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
                  const Text('Ketuk untuk memilih sumber foto',
                      style: TextStyle(fontSize: 11, color: AppColors.textHint), textAlign: TextAlign.center),
                ],
              ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ShimmerLoading(height: 120, borderRadius: BorderRadius.circular(20)),
        const SizedBox(height: 16),
        ShimmerLoading(height: 180, borderRadius: BorderRadius.circular(16)),
        const SizedBox(height: 16),
        ShimmerLoading(height: 56, borderRadius: BorderRadius.circular(12)),
        const SizedBox(height: 12),
        ShimmerLoading(height: 56, borderRadius: BorderRadius.circular(12)),
        const SizedBox(height: 12),
        ShimmerLoading(height: 56, borderRadius: BorderRadius.circular(12)),
        const SizedBox(height: 24),
        ShimmerLoading(height: 52, borderRadius: BorderRadius.circular(12)),
      ],
    );
  }
}
