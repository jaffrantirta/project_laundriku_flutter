class LeaderboardModel {
  final int id;
  final int rank;
  final LeaderboardUser user;
  final int amount;
  final String month;
  final String monthLabel;

  const LeaderboardModel({
    required this.id,
    required this.rank,
    required this.user,
    required this.amount,
    required this.month,
    required this.monthLabel,
  });

  factory LeaderboardModel.fromJson(Map<String, dynamic> json) => LeaderboardModel(
        id: json['id'],
        rank: json['rank'],
        user: LeaderboardUser.fromJson(json['user']),
        amount: json['amount'] ?? 0,
        month: json['month'] ?? '',
        monthLabel: json['month_label'] ?? '',
      );
}

class LeaderboardUser {
  final int id;
  final String name;
  final String referralCode;
  final bool isCurrentUser;

  const LeaderboardUser({
    required this.id,
    required this.name,
    required this.referralCode,
    required this.isCurrentUser,
  });

  factory LeaderboardUser.fromJson(Map<String, dynamic> json) => LeaderboardUser(
        id: json['id'],
        name: json['name'],
        referralCode: json['referral_code'] ?? '',
        isCurrentUser: json['is_current_user'] == true || json['is_current_user'] == 1,
      );
}

class CurrentUserRank {
  final int rank;
  final int amount;

  const CurrentUserRank({required this.rank, required this.amount});

  factory CurrentUserRank.fromJson(Map<String, dynamic> json) =>
      CurrentUserRank(rank: json['rank'], amount: json['amount'] ?? 0);
}

class IdentityModel {
  final bool hasIdentity;
  final int? status;
  final String? statusLabel;
  final String? statusDescription;
  final String? note;
  final Map<String, dynamic>? identity;

  const IdentityModel({
    required this.hasIdentity,
    this.status,
    this.statusLabel,
    this.statusDescription,
    this.note,
    this.identity,
  });

  factory IdentityModel.fromJson(Map<String, dynamic> json) => IdentityModel(
        hasIdentity: json['has_identity'] == true || json['has_identity'] == 1,
        status: json['status'],
        statusLabel: json['status_label'],
        statusDescription: json['status_description'],
        note: json['note'],
        identity: json['identity'],
      );
}
