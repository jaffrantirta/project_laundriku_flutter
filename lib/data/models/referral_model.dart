class ReferralCodeModel {
  final String referralCode;
  final int totalReferrals;
  final int totalRewarded;

  const ReferralCodeModel({
    required this.referralCode,
    required this.totalReferrals,
    required this.totalRewarded,
  });

  factory ReferralCodeModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] ?? json) as Map<String, dynamic>;
    return ReferralCodeModel(
      referralCode: data['referral_code'] ?? '',
      totalReferrals: _parseInt(data['total_referrals']),
      totalRewarded: _parseInt(data['total_rewarded']),
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return (double.tryParse(v.toString()) ?? 0).toInt();
  }
}

class ReferralTreeMemberModel {
  final String name;
  final String? joinedAt;
  final bool hasInitialDeposit;

  const ReferralTreeMemberModel({
    required this.name,
    this.joinedAt,
    required this.hasInitialDeposit,
  });

  factory ReferralTreeMemberModel.fromJson(Map<String, dynamic> json) => ReferralTreeMemberModel(
        name: json['name'] ?? '',
        joinedAt: json['joined_at'],
        hasInitialDeposit: json['has_initial_deposit'] == true,
      );
}

class ReferralTreeModel {
  final String referralCode;
  final int directReferrals;
  final List<ReferralTreeMemberModel> level1;
  final List<ReferralTreeMemberModel> level2;
  final List<ReferralTreeMemberModel> level3;
  final int deeperLevelsCount;

  const ReferralTreeModel({
    required this.referralCode,
    required this.directReferrals,
    required this.level1,
    required this.level2,
    required this.level3,
    required this.deeperLevelsCount,
  });

  factory ReferralTreeModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] ?? json) as Map<String, dynamic>;
    final tree = (data['tree'] as Map<String, dynamic>?) ?? {};
    return ReferralTreeModel(
      referralCode: data['referral_code'] ?? '',
      directReferrals: data['direct_referrals'] ?? 0,
      level1: (tree['level_1'] as List<dynamic>? ?? [])
          .map((e) => ReferralTreeMemberModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      level2: (tree['level_2'] as List<dynamic>? ?? [])
          .map((e) => ReferralTreeMemberModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      level3: (tree['level_3'] as List<dynamic>? ?? [])
          .map((e) => ReferralTreeMemberModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      deeperLevelsCount: (tree['deeper_levels'] as Map<String, dynamic>?)?['total_count'] ?? 0,
    );
  }
}

class ReferralRewardModel {
  final int id;
  final int amount;
  final String status;
  final String fromUser;
  final int level;
  final String? createdAt;

  const ReferralRewardModel({
    required this.id,
    required this.amount,
    required this.status,
    required this.fromUser,
    required this.level,
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

  factory ReferralRewardModel.fromJson(Map<String, dynamic> json) => ReferralRewardModel(
        id: _parseInt(json['id']),
        amount: _parseInt(json['amount']),
        status: json['status'] ?? 'pending',
        fromUser: json['from_user'] ?? '-',
        level: _parseInt(json['level']) == 0 ? 1 : _parseInt(json['level']),
        createdAt: json['created_at'],
      );

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return (double.tryParse(v.toString()) ?? 0).toInt();
  }
}

class BusinessModel {
  final int id;
  final String name;
  final String category;
  final String status;
  final int currentInvestors;
  final int targetInvestors;

  const BusinessModel({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.currentInvestors,
    required this.targetInvestors,
  });

  bool get isOpen => status == 'open';

  double get investorProgress =>
      targetInvestors > 0 ? currentInvestors / targetInvestors : 0;

  factory BusinessModel.fromJson(Map<String, dynamic> json) => BusinessModel(
        id: _parseInt(json['id']),
        name: json['name'] ?? '',
        category: json['category'] ?? '',
        status: json['status'] ?? 'open',
        currentInvestors: _parseInt(json['current_investors']),
        targetInvestors: _parseInt(json['target_investors']),
      );

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return (double.tryParse(v.toString()) ?? 0).toInt();
  }
}
