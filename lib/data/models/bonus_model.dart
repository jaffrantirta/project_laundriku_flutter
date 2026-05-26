class BonusModel {
  final int id;
  final int userId;
  final int fromUserId;
  final int level;
  final int percentage;
  final int amount;
  final String? createdAt;
  final String? fromUserName;

  const BonusModel({
    required this.id,
    required this.userId,
    required this.fromUserId,
    required this.level,
    required this.percentage,
    required this.amount,
    this.createdAt,
    this.fromUserName,
  });

  factory BonusModel.fromJson(Map<String, dynamic> json) => BonusModel(
        id: json['id'],
        userId: json['user_id'],
        fromUserId: json['from_user_id'],
        level: json['level'],
        percentage: json['percentage'],
        amount: json['amount'],
        createdAt: json['created_at'],
        fromUserName: json['from_user']?['name'],
      );
}

class BonusSummaryModel {
  final int totalBonus;
  final int totalTransactions;
  final List<BonusByLevel> bonusByLevel;

  const BonusSummaryModel({
    required this.totalBonus,
    required this.totalTransactions,
    required this.bonusByLevel,
  });

  factory BonusSummaryModel.fromJson(Map<String, dynamic> json) => BonusSummaryModel(
        totalBonus: json['total_bonus'] ?? 0,
        totalTransactions: json['total_transactions'] ?? 0,
        bonusByLevel: (json['bonus_by_level'] as List<dynamic>?)
                ?.map((e) => BonusByLevel.fromJson(e))
                .toList() ??
            [],
      );
}

class BonusByLevel {
  final int level;
  final int totalAmount;
  final int count;

  const BonusByLevel({required this.level, required this.totalAmount, required this.count});

  factory BonusByLevel.fromJson(Map<String, dynamic> json) => BonusByLevel(
        level: json['level'],
        totalAmount: json['total_amount'] ?? 0,
        count: json['count'] ?? 0,
      );
}

class PaginationModel {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const PaginationModel({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) => PaginationModel(
        currentPage: json['current_page'] ?? 1,
        lastPage: json['last_page'] ?? 1,
        perPage: json['per_page'] ?? 15,
        total: json['total'] ?? 0,
      );

  bool get hasNextPage => currentPage < lastPage;
}
