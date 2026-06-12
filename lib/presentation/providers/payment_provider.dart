import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/payment_model.dart';
import '../../data/repositories/supabase_payment_repository.dart';
import '../../domain/repositories/payment_repository.dart';
import 'auth_provider.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return SupabasePaymentRepository(ref.watch(supabaseClientProvider));
});

// Paiements de l'élève connecté
final myPaymentsProvider = FutureProvider<List<PaymentModel>>((ref) async {
  ref.watch(authStateProvider);
  return ref.read(paymentRepositoryProvider).getMyPayments();
});

// Tous les paiements (admin)
final allPaymentsProvider =
    StateNotifierProvider<PaymentsNotifier, AsyncValue<List<PaymentModel>>>(
  (ref) => PaymentsNotifier(ref.watch(paymentRepositoryProvider)),
);

class PaymentsNotifier extends StateNotifier<AsyncValue<List<PaymentModel>>> {
  final PaymentRepository _repo;

  PaymentsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load({String? status}) async {
    state = const AsyncValue.loading();
    try {
      final payments = await _repo.getAllPayments(status: status);
      state = AsyncValue.data(payments);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// État du formulaire de paiement
class PaymentFormState {
  final bool isLoading;
  final String? errorMessage;
  final Map<String, dynamic>? result;

  const PaymentFormState({
    this.isLoading = false,
    this.errorMessage,
    this.result,
  });

  PaymentFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    Map<String, dynamic>? result,
  }) {
    return PaymentFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      result: result ?? this.result,
    );
  }
}

final paymentFormProvider =
    StateNotifierProvider<PaymentFormNotifier, PaymentFormState>(
  (ref) => PaymentFormNotifier(ref.watch(paymentRepositoryProvider)),
);

class PaymentFormNotifier extends StateNotifier<PaymentFormState> {
  final PaymentRepository _repo;

  PaymentFormNotifier(this._repo) : super(const PaymentFormState());

  Future<void> initiatePayment({
    required double amount,
    required String method,
    required String formula,
    required String phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _repo.initiatePayment(
        amount: amount,
        method: method,
        formula: formula,
        phoneNumber: phoneNumber,
      );
      state = state.copyWith(isLoading: false, result: result);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void reset() => state = const PaymentFormState();
}
