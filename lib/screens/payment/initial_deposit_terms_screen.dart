import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class InitialDepositTermsScreen extends StatelessWidget {
  const InitialDepositTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Syarat & Ketentuan Deposit Awal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GradientCard(
              colors: const [AppColors.primary, AppColors.primaryLight],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.account_balance_rounded, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Deposit Awal Koperasi',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Syarat untuk menjadi anggota resmi',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Tentang Deposit Awal'),
            const SizedBox(height: 12),
            AppCard(
              child: const Text(
                'Deposit awal merupakan syarat wajib untuk terdaftar sebagai anggota resmi koperasi MyBisnis. '
                'Dengan menyelesaikan deposit awal, Anda akan mendapatkan akses penuh ke seluruh fitur platform.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
              ),
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Keuntungan Menjadi Anggota'),
            const SizedBox(height: 12),
            ..._benefits.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BenefitItem(icon: b['icon'] as IconData, title: b['title'] as String, desc: b['desc'] as String),
                )),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Ketentuan Umum'),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _terms.asMap().entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${e.key + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            e.value,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.info.withOpacity(0.2)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.info, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Informasi lebih lanjut mengenai besaran deposit awal akan segera tersedia. Silakan cek kembali secara berkala.',
                      style: TextStyle(fontSize: 12, color: AppColors.info, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _benefits = [
  {
    'icon': Icons.verified_rounded,
    'title': 'Status Anggota Resmi',
    'desc': 'Terdaftar sebagai anggota resmi koperasi dan mendapat nomor anggota.',
  },
  {
    'icon': Icons.business_center_rounded,
    'title': 'Akses Investasi Bisnis',
    'desc': 'Dapat berinvestasi di bisnis laundry yang tersedia di platform.',
  },
  {
    'icon': Icons.share_rounded,
    'title': 'Program Referral Aktif',
    'desc': 'Kode referral aktif dan dapat menghasilkan reward untuk setiap anggota baru.',
  },
  {
    'icon': Icons.trending_up_rounded,
    'title': 'Bagi Hasil Investasi',
    'desc': 'Mendapatkan bagi hasil dari investasi bisnis yang dikelola koperasi.',
  },
];

const _terms = [
  'Deposit awal wajib dilakukan satu kali sebagai syarat pendaftaran anggota koperasi.',
  'Deposit awal bersifat permanen dan menjadi modal awal partisipasi dalam koperasi.',
  'Besaran deposit awal ditentukan oleh pengurus koperasi dan dapat berubah sewaktu-waktu.',
  'Anggota yang telah melakukan deposit awal berhak menggunakan seluruh fitur platform MyBisnis.',
  'Informasi detail mengenai besaran dan mekanisme deposit akan diberitahukan melalui notifikasi resmi.',
];

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _BenefitItem({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 3),
                Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
