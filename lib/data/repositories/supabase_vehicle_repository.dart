import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../data/models/vehicle_model.dart';

class SupabaseVehicleRepository {
  final SupabaseClient _client;

  SupabaseVehicleRepository(this._client);

  Future<List<VehicleModel>> getAllVehicles() async {
    final data = await _client
        .from(SupabaseConfig.tableVehicles)
        .select()
        .order('brand');

    return (data as List)
        .map((json) => VehicleModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<VehicleModel?> getVehicleById(String id) async {
    final data = await _client
        .from(SupabaseConfig.tableVehicles)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return VehicleModel.fromJson(data);
  }

  Future<VehicleModel> createVehicle(Map<String, dynamic> vehicleData) async {
    final result = await _client
        .from(SupabaseConfig.tableVehicles)
        .insert(vehicleData)
        .select()
        .single();
    return VehicleModel.fromJson(result);
  }

  Future<void> updateVehicleStatus(String vehicleId, String status) async {
    await _client
        .from(SupabaseConfig.tableVehicles)
        .update({'status': status})
        .eq('id', vehicleId);
  }
}
