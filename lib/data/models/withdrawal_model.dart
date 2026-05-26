class WithdrawalModel {
  final int id;
  final int amount;
  final int adminFee;
  final int grossAmount;
  final WithdrawalStatusInfo status;
  final String? createdAt;

  const WithdrawalModel({
    required this.id,
    required this.amount,
    required this.adminFee,
    required this.grossAmount,
    required this.status,
    this.createdAt,
  });

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) => WithdrawalModel(
        id: json['id'],
        amount: json['amount'],
        adminFee: json['admin_fee'] ?? 0,
        grossAmount: json['gross_amount'],
        status: WithdrawalStatusInfo.fromJson(json['status']),
        createdAt: json['created_at'],
      );
}

class WithdrawalStatusInfo {
  final int value;
  final String label;

  const WithdrawalStatusInfo({required this.value, required this.label});

  factory WithdrawalStatusInfo.fromJson(Map<String, dynamic> json) =>
      WithdrawalStatusInfo(value: json['value'], label: json['label']);
}

class WithdrawalConfig {
  final int minAmount;
  final int adminFee;
  final int maintainingBalance;
  final int walletBalance;
  final int maxWithdrawal;
  final bool isIdentityVerified;

  const WithdrawalConfig({
    required this.minAmount,
    required this.adminFee,
    required this.maintainingBalance,
    required this.walletBalance,
    required this.maxWithdrawal,
    required this.isIdentityVerified,
  });

  factory WithdrawalConfig.fromJson(Map<String, dynamic> json) => WithdrawalConfig(
        minAmount: json['min_amount'] ?? 50000,
        adminFee: json['admin_fee'] ?? 0,
        maintainingBalance: json['maintaining_balance'] ?? 0,
        walletBalance: json['wallet_balance'] ?? 0,
        maxWithdrawal: json['max_withdrawal'] ?? 0,
        isIdentityVerified: json['is_identity_verified'] == true || json['is_identity_verified'] == 1,
      );
}
