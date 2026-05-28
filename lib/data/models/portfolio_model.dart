class PortfolioSummaryModel {
  final int totalInvestments;
  final int activeInvestments;
  final int pendingInvestments;
  final int totalInvested;
  final int totalProfit;
  final int currentBalance;

  const PortfolioSummaryModel({
    required this.totalInvestments,
    required this.activeInvestments,
    required this.pendingInvestments,
    required this.totalInvested,
    required this.totalProfit,
    required this.currentBalance,
  });

  factory PortfolioSummaryModel.fromJson(Map<String, dynamic> json) =>
      PortfolioSummaryModel(
        totalInvestments: _parseInt(json['total_investments']),
        activeInvestments: _parseInt(json['active_investments']),
        pendingInvestments: _parseInt(json['pending_investments']),
        totalInvested: _parseInt(json['total_invested']),
        totalProfit: _parseInt(json['total_profit']),
        currentBalance: _parseInt(json['current_balance']),
      );

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return (double.tryParse(v.toString()) ?? 0).toInt();
  }
}

class InstallmentProgressModel {
  final int monthsPaid;
  final int tenureMonths;
  final int remaining;
  final String? nextDueDate;
  final int nextAmount;
  final bool completed;

  const InstallmentProgressModel({
    required this.monthsPaid,
    required this.tenureMonths,
    required this.remaining,
    this.nextDueDate,
    required this.nextAmount,
    required this.completed,
  });

  factory InstallmentProgressModel.fromJson(Map<String, dynamic> json) =>
      InstallmentProgressModel(
        monthsPaid: _parseInt(json['months_paid']),
        tenureMonths: _parseInt(json['tenure_months']),
        remaining: _parseInt(json['remaining']),
        nextDueDate: json['next_due_date'],
        nextAmount: _parseInt(json['next_amount']),
        completed: json['completed'] == true,
      );

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return (double.tryParse(v.toString()) ?? 0).toInt();
  }
}

class PortfolioBusinessModel {
  final int id;
  final String name;
  final String category;
  final String location;
  final String status;
  final String? imageUrl;
  final int currentInvestors;
  final int targetInvestors;
  final String? activationDate;

  const PortfolioBusinessModel({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.status,
    this.imageUrl,
    required this.currentInvestors,
    required this.targetInvestors,
    this.activationDate,
  });

  factory PortfolioBusinessModel.fromJson(Map<String, dynamic> json) =>
      PortfolioBusinessModel(
        id: _parseInt(json['id']),
        name: json['name'] ?? '',
        category: json['category'] ?? '',
        location: json['location'] ?? '',
        status: json['status'] ?? 'active',
        imageUrl: json['image_url'],
        currentInvestors: _parseInt(json['current_investors']),
        targetInvestors: _parseInt(json['target_investors']),
        activationDate: json['activation_date'],
      );

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return (double.tryParse(v.toString()) ?? 0).toInt();
  }
}

class PortfolioInvestmentModel {
  final int id;
  final String status;
  final String paymentType;
  final int totalAmount;
  final int adminFee;
  final int profitReceived;
  final InstallmentProgressModel? installmentProgress;
  final String? joinedAt;
  final PortfolioBusinessModel business;

  const PortfolioInvestmentModel({
    required this.id,
    required this.status,
    required this.paymentType,
    required this.totalAmount,
    required this.adminFee,
    required this.profitReceived,
    this.installmentProgress,
    this.joinedAt,
    required this.business,
  });

  bool get isInstallment => paymentType == 'installment';

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'pending':
        return 'Menunggu';
      case 'completed':
        return 'Selesai';
      default:
        return status;
    }
  }

  factory PortfolioInvestmentModel.fromJson(Map<String, dynamic> json) =>
      PortfolioInvestmentModel(
        id: _parseInt(json['id']),
        status: json['status'] ?? 'pending',
        paymentType: json['payment_type'] ?? 'full',
        totalAmount: _parseInt(json['total_amount']),
        adminFee: _parseInt(json['admin_fee']),
        profitReceived: _parseInt(json['profit_received']),
        installmentProgress: json['installment_progress'] != null
            ? InstallmentProgressModel.fromJson(
                json['installment_progress'] as Map<String, dynamic>)
            : null,
        joinedAt: json['joined_at'],
        business: PortfolioBusinessModel.fromJson(
            json['business'] as Map<String, dynamic>),
      );

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return (double.tryParse(v.toString()) ?? 0).toInt();
  }
}

class PortfolioModel {
  final PortfolioSummaryModel summary;
  final List<PortfolioInvestmentModel> investments;

  const PortfolioModel({required this.summary, required this.investments});

  factory PortfolioModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] ?? json) as Map<String, dynamic>;
    return PortfolioModel(
      summary: PortfolioSummaryModel.fromJson(
          data['summary'] as Map<String, dynamic>),
      investments: (data['investments'] as List<dynamic>? ?? [])
          .map((e) =>
              PortfolioInvestmentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class InstallmentScheduleItem {
  final int monthNumber;
  final int amount;
  final String status;
  final String? dueDate;
  final String? paidAt;

  const InstallmentScheduleItem({
    required this.monthNumber,
    required this.amount,
    required this.status,
    this.dueDate,
    this.paidAt,
  });

  factory InstallmentScheduleItem.fromJson(Map<String, dynamic> json) =>
      InstallmentScheduleItem(
        monthNumber: _parseInt(json['month_number']),
        amount: _parseInt(json['amount']),
        status: json['status'] ?? 'pending',
        dueDate: json['due_date'],
        paidAt: json['paid_at'],
      );

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return (double.tryParse(v.toString()) ?? 0).toInt();
  }
}

class ProfitHistoryItem {
  final int id;
  final int amount;
  final String? notes;
  final String? confirmedAt;

  const ProfitHistoryItem({
    required this.id,
    required this.amount,
    this.notes,
    this.confirmedAt,
  });

  factory ProfitHistoryItem.fromJson(Map<String, dynamic> json) =>
      ProfitHistoryItem(
        id: _parseInt(json['id']),
        amount: _parseInt(json['amount']),
        notes: json['notes'],
        confirmedAt: json['confirmed_at'],
      );

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return (double.tryParse(v.toString()) ?? 0).toInt();
  }
}

class PaymentHistoryItem {
  final int id;
  final String type;
  final int amount;
  final String status;
  final String? paymentMethod;
  final String? confirmedAt;

  const PaymentHistoryItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    this.paymentMethod,
    this.confirmedAt,
  });

  String get typeLabel {
    switch (type) {
      case 'installment':
        return 'Cicilan';
      case 'full':
        return 'Lunas';
      case 'profit':
        return 'Profit';
      default:
        return type;
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

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) =>
      PaymentHistoryItem(
        id: _parseInt(json['id']),
        type: json['type'] ?? '',
        amount: _parseInt(json['amount']),
        status: json['status'] ?? 'pending',
        paymentMethod: json['payment_method'],
        confirmedAt: json['confirmed_at'],
      );

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return (double.tryParse(v.toString()) ?? 0).toInt();
  }
}

class PortfolioDetailModel {
  final PortfolioInvestmentModel investment;
  final List<InstallmentScheduleItem>? installmentSchedule;
  final List<ProfitHistoryItem> profitHistory;
  final List<PaymentHistoryItem> paymentHistory;

  const PortfolioDetailModel({
    required this.investment,
    this.installmentSchedule,
    required this.profitHistory,
    required this.paymentHistory,
  });

  factory PortfolioDetailModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] ?? json) as Map<String, dynamic>;
    final rawSchedule = data['installment_schedule'];
    return PortfolioDetailModel(
      investment: PortfolioInvestmentModel.fromJson(
          data['investment'] as Map<String, dynamic>),
      installmentSchedule: rawSchedule == null
          ? null
          : (rawSchedule as List<dynamic>)
              .map((e) => InstallmentScheduleItem.fromJson(
                  e as Map<String, dynamic>))
              .toList(),
      profitHistory: (data['profit_history'] as List<dynamic>? ?? [])
          .map((e) =>
              ProfitHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      paymentHistory: (data['payment_history'] as List<dynamic>? ?? [])
          .map((e) =>
              PaymentHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
