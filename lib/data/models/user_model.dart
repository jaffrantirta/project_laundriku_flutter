class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: _parseInt(json['id']),
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'],
        createdAt: json['created_at'],
      );

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return (double.tryParse(v.toString()) ?? 0).toInt();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'created_at': createdAt,
      };
}

class BalanceModel {
  final int balance;
  final int investmentProfit;
  final int referralReward;
  final bool isVerified;
  final bool hasInitialDeposit;

  const BalanceModel({
    required this.balance,
    required this.investmentProfit,
    required this.referralReward,
    required this.isVerified,
    required this.hasInitialDeposit,
  });

  factory BalanceModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] ?? json) as Map<String, dynamic>;
    final breakdown = (data['breakdown'] as Map<String, dynamic>?) ?? {};
    return BalanceModel(
      balance: _parseInt(data['balance']),
      investmentProfit: _parseInt(breakdown['investment_profit']),
      referralReward: _parseInt(breakdown['referral_reward']),
      isVerified: data['is_verified'] == true,
      hasInitialDeposit: data['has_initial_deposit'] == true,
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return (double.tryParse(v.toString()) ?? 0).toInt();
  }
}
