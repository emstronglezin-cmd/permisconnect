import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/student_model.dart';
import '../../data/models/instructor_model.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/repositories/supabase_student_repository.dart';
import '../../data/repositories/supabase_instructor_repository.dart';
import '../../data/repositories/supabase_vehicle_repository.dart';
import 'auth_provider.dart';

// ─── Repositories ─────────────────────────────────────────────────────────────

final studentRepositoryProvider = Provider((ref) {
  return SupabaseStudentRepository(ref.watch(supabaseClientProvider));
});

final instructorRepositoryProvider = Provider((ref) {
  return SupabaseInstructorRepository(ref.watch(supabaseClientProvider));
});

final vehicleRepositoryProvider = Provider((ref) {
  return SupabaseVehicleRepository(ref.watch(supabaseClientProvider));
});

// ─── Mon profil élève ─────────────────────────────────────────────────────────

final myStudentProvider = FutureProvider<StudentModel?>((ref) async {
  // Réagit au changement d'auth
  ref.watch(authStateProvider);
  return ref.read(studentRepositoryProvider).getMyStudent();
});

// ─── Liste des élèves (admin) ─────────────────────────────────────────────────

final studentsListProvider =
    StateNotifierProvider<StudentsNotifier, AsyncValue<List<StudentModel>>>(
  (ref) => StudentsNotifier(ref.watch(studentRepositoryProvider)),
);

class StudentsNotifier
    extends StateNotifier<AsyncValue<List<StudentModel>>> {
  final SupabaseStudentRepository _repo;

  StudentsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  String? _search;
  String? _status;

  Future<void> load({String? search, String? status}) async {
    _search = search;
    _status = status;
    state = const AsyncValue.loading();
    try {
      final students = await _repo.getAllStudents(
        search: search,
        status: status,
      );
      state = AsyncValue.data(students);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => load(search: _search, status: _status);
}

// ─── Liste des moniteurs ──────────────────────────────────────────────────────

final instructorsListProvider =
    FutureProvider<List<InstructorModel>>((ref) async {
  return ref.watch(instructorRepositoryProvider).getAllInstructors();
});

// ─── Liste des véhicules ──────────────────────────────────────────────────────

final vehiclesListProvider =
    FutureProvider<List<VehicleModel>>((ref) async {
  return ref.watch(vehicleRepositoryProvider).getAllVehicles();
});

// ─── Statistiques admin ───────────────────────────────────────────────────────

final adminStatsProvider =
    FutureProvider<Map<String, int>>((ref) async {
  // Compter les éléments de chaque liste
  final students =
      await ref.watch(studentRepositoryProvider).getAllStudents();
  final instructors =
      await ref.watch(instructorRepositoryProvider).getAllInstructors();
  final vehicles = await ref.watch(vehicleRepositoryProvider).getAllVehicles();

  final activeStudents =
      students.where((s) => s.status == 'active').length;

  return {
    'total_students': students.length,
    'active_students': activeStudents,
    'total_instructors': instructors.length,
    'total_vehicles': vehicles.length,
  };
});
