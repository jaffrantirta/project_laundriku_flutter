class TransactionModel {
  final int id;
  final String type;
  final int amount;
  final String status;
  final String? confirmedAt;
  final String? createdAt;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    this.confirmedAt,
    this.createdAt,
  });

  int get statusValue {
    switch (status) {
      case 'success':
        return 2;
      case 'failed':
        return 3;
      default:
        return 0;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'success':
        return 'Sukses';
      case 'failed':
        return 'Gagal';
      default:
        return 'Menunggu';
    }
  }

  String get typeLabel {
    switch (type) {
      case 'initial_deposit':
        return 'Deposit Awal';
      case 'investment':
        return 'Investasi';
      case 'installment':
        return 'Cicilan';
      case 'profit':
        return 'Profit';
      case 'referral_reward':
        return 'Reward Referral';
      case 'withdrawal':
        return 'Penarikan';
      case 'refund':
        return 'Refund';
      default:
        return type;
    }
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
        id: _parseInt(json['id']),
        type: json['type'] ?? '',
        amount: _parseInt(json['amount']),
        status: json['status'] ?? 'pending',
        confirmedAt: json['confirmed_at'],
        createdAt: json['created_at'],
      );

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return (double.tryParse(v.toString()) ?? 0).toInt();
  }
}

class BankDetailsModel {
  final String bankName;
  final String accountNumber;
  final String accountName;
  final int amount;

  const BankDetailsModel({
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.amount,
  });

  factory BankDetailsModel.fromJson(Map<String, dynamic> json) => BankDetailsModel(
        bankName: json['bank_name'] ?? '',
        accountNumber: json['account_number'] ?? '',
        accountName: json['account_name'] ?? '',
        amount: TransactionModel._parseInt(json['amount']),
      );
}

class InitialDepositModel {
  final TransactionModel transaction;
  final BankDetailsModel? bankDetails;
  final String? snapToken;
  final String? snapRedirectUrl;

  const InitialDepositModel({
    required this.transaction,
    this.bankDetails,
    this.snapToken,
    this.snapRedirectUrl,
  });

  bool get isSnap => snapRedirectUrl != null;

  factory InitialDepositModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] ?? json) as Map<String, dynamic>;
    return InitialDepositModel(
      transaction: TransactionModel.fromJson(data['transaction'] as Map<String, dynamic>),
      bankDetails: data['bank_details'] != null
          ? BankDetailsModel.fromJson(data['bank_details'] as Map<String, dynamic>)
          : null,
      snapToken: data['snap_token']?.toString(),
      snapRedirectUrl: data['snap_redirect_url']?.toString(),
    );
  }
}
