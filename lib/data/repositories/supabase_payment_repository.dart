import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../data/models/payment_model.dart';
import '../../domain/repositories/payment_repository.dart';

class SupabasePaymentRepository implements PaymentRepository {
  final SupabaseClient _client;

  SupabasePaymentRepository(this._client);

  @override
  Future<List<PaymentModel>> getMyPayments() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final profileData = await _client
        .from(SupabaseConfig.tableProfiles)
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();
    if (profileData == null) return [];

    final studentData = await _client
        .from(SupabaseConfig.tableStudents)
        .select('id')
        .eq('profile_id', profileData['id'] as String)
        .maybeSingle();
    if (studentData == null) return [];

    final data = await _client
        .from(SupabaseConfig.tablePayments)
        .select('*, students(profiles(full_name, phone))')
        .eq('student_id', studentData['id'] as String)
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => PaymentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<PaymentModel>> getAllPayments({String? status}) async {
    List<dynamic> data;
    if (status != null && status.isNotEmpty) {
      data = await _client
          .from(SupabaseConfig.tablePayments)
          .select('*, students(profiles(full_name, phone))')
          .eq('status', status)
          .order('created_at', ascending: false);
    } else {
      data = await _client
          .from(SupabaseConfig.tablePayments)
          .select('*, students(profiles(full_name, phone))')
          .order('created_at', ascending: false);
    }
    return data
        .map((json) => PaymentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> initiatePayment({
    required double amount,
    required String method,
    required String formula,
    required String phoneNumber,
  }) async {
    // Appel à l'Edge Function Supabase (clé privée LeekPay côté serveur)
    final response = await _client.functions.invoke(
      SupabaseConfig.fnCreatePayment,
      body: {
        'amount': amount,
        'method': method,
        'formula': formula,
        'phone_number': phoneNumber,
        'currency': 'XOF',
      },
    );

    if (response.status != 200) {
      throw Exception('Erreur paiement: ${response.data}');
    }

    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> verifyPayment(String leekpayRef) async {
    final response = await _client.functions.invoke(
      SupabaseConfig.fnVerifyPayment,
      body: {'leekpay_ref': leekpayRef},
    );

    if (response.status != 200) {
      throw Exception('Erreur vérification: ${response.data}');
    }

    return response.data as Map<String, dynamic>;
  }
}
