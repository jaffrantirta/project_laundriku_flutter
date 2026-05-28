class NotificationModel {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final String? readAt;
  final String? createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.data,
    this.readAt,
    this.createdAt,
  });

  bool get isRead => readAt != null;

  String get title {
    if (type.contains('InstallmentReminder')) {
      final business = data['business_name'] ?? 'Bisnis';
      return 'Pengingat Cicilan – $business';
    }
    if (type.contains('Profit')) return 'Profit Diterima';
    if (type.contains('Investment')) return 'Investasi Dikonfirmasi';
    if (type.contains('Verification')) return 'Status Verifikasi';
    return 'Notifikasi';
  }

  String get body {
    if (type.contains('InstallmentReminder')) {
      final due = data['due_date'] ?? '-';
      final month = data['month_number'];
      final amount = data['amount'];
      final amountStr = amount != null
          ? 'Rp ${_formatNumber(amount)}'
          : '';
      return 'Cicilan bulan ke-$month jatuh tempo $due${amountStr.isNotEmpty ? ' sebesar $amountStr' : ''}.';
    }
    if (data['message'] != null) return data['message'].toString();
    return 'Ketuk untuk melihat detail.';
  }

  String _formatNumber(dynamic n) {
    final num = n is int ? n : (double.tryParse(n.toString()) ?? 0).toInt();
    return num.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        data: (json['data'] as Map<String, dynamic>?) ?? {},
        readAt: json['read_at']?.toString(),
        createdAt: json['created_at']?.toString(),
      );
}
