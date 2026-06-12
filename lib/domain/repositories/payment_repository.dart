import '../../data/models/payment_model.dart';

abstract class PaymentRepository {
  /// Paiements de l'élève connecté
  Future<List<PaymentModel>> getMyPayments();

  /// Tous les paiements (admin)
  Future<List<PaymentModel>> getAllPayments({String? status});

  /// Initier un paiement via Edge Function (LeekPay)
  Future<Map<String, dynamic>> initiatePayment({
    required double amount,
    required String method,
    required String formula,
    required String phoneNumber,
  });

  /// Vérifier le statut d'un paiement
  Future<Map<String, dynamic>> verifyPayment(String leekpayRef);
}
