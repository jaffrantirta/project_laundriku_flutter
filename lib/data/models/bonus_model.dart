class BalanceHistoryItemModel {
  final int id;
  final String type;
  final int amount;
  final String status;
  final String? description;
  final String? createdAt;

  const BalanceHistoryItemModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    this.description,
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
      case 'profit':
        return 'Profit Investasi';
      case 'referral_reward':
        return 'Reward Referral';
      case 'withdrawal':
        return 'Penarikan';
      case 'initial_deposit':
        return 'Deposit Awal';
      default:
        return type;
    }
  }

  factory BalanceHistoryItemModel.fromJson(Map<String, dynamic> json) => BalanceHistoryItemModel(
        id: json['id'],
        type: json['type'] ?? '',
        amount: json['amount'] ?? 0,
        status: json['status'] ?? 'success',
        description: json['description'],
        createdAt: json['created_at'],
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
