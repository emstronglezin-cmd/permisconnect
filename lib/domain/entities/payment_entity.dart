class PaymentEntity {
  final String id;
  final String studentId;
  final String studentName;
  final double amount;
  final String paymentMethod;
  final String status;
  final String? transactionId;
  final String? reference;
  final String? notes;
  final DateTime paymentDate;
  final DateTime? validatedAt;
  final String? validatedBy;

  PaymentEntity({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    this.transactionId,
    this.reference,
    this.notes,
    required this.paymentDate,
    this.validatedAt,
    this.validatedBy,
  });

  bool get isPending => status == 'PENDING';
  bool get isValidated => status == 'VALIDATED';
  bool get isFailed => status == 'FAILED';

  String get paymentMethodLabel {
    switch (paymentMethod) {
      case 'CASH':
        return 'Espèces';
      case 'ORANGE_MONEY':
        return 'Orange Money';
      case 'MOOV_MONEY':
        return 'Moov Money';
      case 'CARD':
        return 'Carte bancaire';
      default:
        return paymentMethod;
    }
  }
}

class FormulaEntity {
  final String id;
  final String name;
  final String description;
  final double price;
  final int hoursIncluded;
  final List<String> features;
  final bool isActive;
  final String? color;

  FormulaEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.hoursIncluded,
    required this.features,
    required this.isActive,
    this.color,
  });
}
