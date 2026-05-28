class WithdrawalModel {
  final int id;
  final int amount;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final String status;
  final String? createdAt;

  const WithdrawalModel({
    required this.id,
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.status,
    this.createdAt,
  });

  int get statusValue {
    switch (status) {
      case 'approved':
        return 1;
      case 'rejected':
        return 2;
      default:
        return 0;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Menunggu';
    }
  }

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) => WithdrawalModel(
        id: _parseInt(json['id']),
        amount: _parseInt(json['amount']),
        bankName: json['bank_name'] ?? '',
        accountNumber: json['account_number'] ?? '',
        accountName: json['account_name'] ?? '',
        status: json['status'] ?? 'pending',
        createdAt: json['created_at'],
      );

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return (double.tryParse(v.toString()) ?? 0).toInt();
  }
}
