class PaymentModel {
  final int id;
  final String orderId;
  final PaymentTypeInfo type;
  final int amount;
  final int adminFee;
  final int grossAmount;
  final PaymentStatusInfo status;
  final PaymentMethodInfo? paymentType;
  final String? paidAt;
  final String? expireTime;
  final String? qrUrl;
  final String? qrString;
  final String? transactionId;
  final String? createdAt;
  final Map<String, dynamic>? paymentInfo;

  const PaymentModel({
    required this.id,
    required this.orderId,
    required this.type,
    required this.amount,
    required this.adminFee,
    required this.grossAmount,
    required this.status,
    this.paymentType,
    this.paidAt,
    this.expireTime,
    this.qrUrl,
    this.qrString,
    this.transactionId,
    this.createdAt,
    this.paymentInfo,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        id: json['id'],
        orderId: json['order_id'],
        type: PaymentTypeInfo.fromJson(json['type']),
        amount: json['amount'],
        adminFee: json['admin_fee'] ?? 0,
        grossAmount: json['gross_amount'],
        status: PaymentStatusInfo.fromJson(json['status']),
        paymentType: json['payment_type'] != null
            ? PaymentMethodInfo.fromJson(json['payment_type'])
            : null,
        paidAt: json['paid_at'],
        expireTime: json['expire_time'],
        qrUrl: json['qr_url'],
        qrString: json['qr_string'],
        transactionId: json['transaction_id'],
        createdAt: json['created_at'],
        paymentInfo: json['payment_info'],
      );
}

class PaymentTypeInfo {
  final int value;
  final String label;

  const PaymentTypeInfo({required this.value, required this.label});

  factory PaymentTypeInfo.fromJson(Map<String, dynamic> json) =>
      PaymentTypeInfo(value: json['value'], label: json['label']);
}

class PaymentStatusInfo {
  final int value;
  final String label;

  const PaymentStatusInfo({required this.value, required this.label});

  factory PaymentStatusInfo.fromJson(Map<String, dynamic> json) =>
      PaymentStatusInfo(value: json['value'], label: json['label']);
}

class PaymentMethodInfo {
  final String value;
  final String label;

  const PaymentMethodInfo({required this.value, required this.label});

  factory PaymentMethodInfo.fromJson(Map<String, dynamic> json) =>
      PaymentMethodInfo(value: json['value'], label: json['label']);
}

class TopupConfig {
  final int minAmount;
  final int adminFee;
  final String paymentGateway;
  final Map<String, dynamic>? paymentInfo;
  final String? picWhatsapp;

  const TopupConfig({
    required this.minAmount,
    required this.adminFee,
    required this.paymentGateway,
    this.paymentInfo,
    this.picWhatsapp,
  });

  bool get isManual => paymentGateway == 'manual';

  factory TopupConfig.fromJson(Map<String, dynamic> json) => TopupConfig(
        minAmount: json['min_amount'] ?? 25000,
        adminFee: json['admin_fee'] ?? 0,
        paymentGateway: json['payment_gateway'] ?? '',
        paymentInfo: json['payment_info'],
        picWhatsapp: json['pic_whatsapp'],
      );
}
