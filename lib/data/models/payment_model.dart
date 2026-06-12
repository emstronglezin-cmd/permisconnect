class PaymentModel {
  final String id;
  final String studentId;
  final double amount;
  final String currency;
  final String method;
  final String status;
  final String? transactionId;
  final String? leekpayRef;
  final String? description;
  final String? formula;
  final DateTime createdAt;
  final DateTime? paidAt;

  // Données jointes
  final String? studentName;
  final String? studentPhone;

  const PaymentModel({
    required this.id,
    required this.studentId,
    required this.amount,
    this.currency = 'XOF',
    required this.method,
    this.status = 'pending',
    this.transactionId,
    this.leekpayRef,
    this.description,
    this.formula,
    required this.createdAt,
    this.paidAt,
    this.studentName,
    this.studentPhone,
  });

  bool get isPaid => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';

  String get formattedAmount =>
      '${amount.toStringAsFixed(0)} $currency';

  String get statusLabel {
    switch (status) {
      case 'completed':
        return 'Payé';
      case 'pending':
        return 'En attente';
      case 'failed':
        return 'Échoué';
      case 'refunded':
        return 'Remboursé';
      default:
        return status;
    }
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    final studentData = json['students'] as Map<String, dynamic>?;
    final studentProfile =
        studentData?['profiles'] as Map<String, dynamic>?;

    return PaymentModel(
      id: json['id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'XOF',
      method: json['method'] as String? ?? 'mobile_money',
      status: json['status'] as String? ?? 'pending',
      transactionId: json['transaction_id'] as String?,
      leekpayRef: json['leekpay_ref'] as String?,
      description: json['description'] as String?,
      formula: json['formula'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      studentName: studentProfile?['full_name'] as String?,
      studentPhone: studentProfile?['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'amount': amount,
      'currency': currency,
      'method': method,
      'status': status,
      'transaction_id': transactionId,
      'leekpay_ref': leekpayRef,
      'description': description,
      'formula': formula,
      'created_at': createdAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
    };
  }
}
