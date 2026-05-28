class VerificationStatusModel {
  final bool isVerified;
  final String? verificationStatus;
  final bool hasInitialDeposit;
  final bool idUploaded;
  final bool idApproved;
  final bool depositPaid;

  const VerificationStatusModel({
    required this.isVerified,
    this.verificationStatus,
    required this.hasInitialDeposit,
    required this.idUploaded,
    required this.idApproved,
    required this.depositPaid,
  });

  bool get hasSubmitted => idUploaded;
  bool get isPending => !isVerified && verificationStatus == 'pending';
  bool get isRejected => verificationStatus == 'rejected';
  bool get isFullyOnboarded => isVerified && hasInitialDeposit;

  factory VerificationStatusModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] ?? json) as Map<String, dynamic>;
    final steps = (data['steps'] as Map<String, dynamic>?) ?? {};
    return VerificationStatusModel(
      isVerified: data['is_verified'] == true,
      verificationStatus: data['verification_status'],
      hasInitialDeposit: data['has_initial_deposit'] == true,
      idUploaded: steps['id_uploaded'] == true,
      idApproved: steps['id_approved'] == true,
      depositPaid: steps['deposit_paid'] == true,
    );
  }
}

class BusinessDetailModel {
  final int id;
  final String name;
  final String category;
  final String status;
  final int currentInvestors;
  final int targetInvestors;
  final Map<String, dynamic>? extra;

  const BusinessDetailModel({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.currentInvestors,
    required this.targetInvestors,
    this.extra,
  });

  bool get isOpen => status == 'open';
  double get investorProgress =>
      targetInvestors > 0 ? currentInvestors / targetInvestors : 0;

  factory BusinessDetailModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] ?? json) as Map<String, dynamic>;
    return BusinessDetailModel(
      id: _parseInt(data['id']),
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      status: data['status'] ?? '',
      currentInvestors: _parseInt(data['current_investors']),
      targetInvestors: _parseInt(data['target_investors']),
      extra: data,
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return (double.tryParse(v.toString()) ?? 0).toInt();
  }
}
