class ReferralModel {
  final int id;
  final String name;
  final String email;
  final String referralCode;
  final bool isActiveReferral;
  final String? createdAt;

  const ReferralModel({
    required this.id,
    required this.name,
    required this.email,
    required this.referralCode,
    required this.isActiveReferral,
    this.createdAt,
  });

  factory ReferralModel.fromJson(Map<String, dynamic> json) => ReferralModel(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        referralCode: json['referral_code'] ?? '',
        isActiveReferral: json['is_active_referral'] == true || json['is_active_referral'] == 1,
        createdAt: json['created_at'],
      );
}

class ReferralSummaryModel {
  final int totalReferrals;
  final int activeReferrals;
  final int inactiveReferrals;
  final String referralCode;
  final bool isActiveReferral;

  const ReferralSummaryModel({
    required this.totalReferrals,
    required this.activeReferrals,
    required this.inactiveReferrals,
    required this.referralCode,
    required this.isActiveReferral,
  });

  factory ReferralSummaryModel.fromJson(Map<String, dynamic> json) => ReferralSummaryModel(
        totalReferrals: json['total_referrals'] ?? 0,
        activeReferrals: json['active_referrals'] ?? 0,
        inactiveReferrals: json['inactive_referrals'] ?? 0,
        referralCode: json['referral_code'] ?? '',
        isActiveReferral: json['is_active_referral'] == true || json['is_active_referral'] == 1,
      );
}

class GroupModel {
  final int id;
  final String name;
  final int membersCount;
  final String? createdAt;
  final List<GroupMember>? members;

  const GroupModel({
    required this.id,
    required this.name,
    required this.membersCount,
    this.createdAt,
    this.members,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) => GroupModel(
        id: json['id'],
        name: json['name'],
        membersCount: json['members_count'] ?? 0,
        createdAt: json['created_at'],
        members: (json['members'] as List<dynamic>?)
            ?.map((e) => GroupMember.fromJson(e))
            .toList(),
      );
}

class GroupMember {
  final int id;
  final String userName;
  final String userEmail;
  final String userReferralCode;
  final int userId;
  final String? joinedAt;

  const GroupMember({
    required this.id,
    required this.userName,
    required this.userEmail,
    required this.userReferralCode,
    required this.userId,
    this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
        id: json['id'],
        userName: json['user']?['name'] ?? '',
        userEmail: json['user']?['email'] ?? '',
        userReferralCode: json['user']?['referral_code'] ?? '',
        userId: json['user']?['id'] ?? 0,
        joinedAt: json['joined_at'],
      );
}
