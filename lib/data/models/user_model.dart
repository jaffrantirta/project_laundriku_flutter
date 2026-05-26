class UserModel {
  final int id;
  final String name;
  final String email;
  final String? emailVerifiedAt;
  final String referralCode;
  final bool isActiveReferral;
  final int? referredById;
  final String? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    required this.referralCode,
    required this.isActiveReferral,
    this.referredById,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        emailVerifiedAt: json['email_verified_at'],
        referralCode: json['referral_code'] ?? '',
        isActiveReferral: json['is_active_referral'] == true || json['is_active_referral'] == 1,
        referredById: json['referred_by_id'],
        createdAt: json['created_at'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'email_verified_at': emailVerifiedAt,
        'referral_code': referralCode,
        'is_active_referral': isActiveReferral,
        'referred_by_id': referredById,
        'created_at': createdAt,
      };
}

class WalletModel {
  final int balance;
  final String balanceFormatted;

  const WalletModel({required this.balance, required this.balanceFormatted});

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
        balance: json['balance'] ?? 0,
        balanceFormatted: json['balance_formatted'] ?? 'Rp 0',
      );
}
