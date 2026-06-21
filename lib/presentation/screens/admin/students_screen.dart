import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/student_provider.dart';
import '../../../data/models/student_model.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  final _searchCtrl = TextEditingController();
  String _statusFilter = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gestion des élèves'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(studentsListProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche + filtre
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un élève...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    onChanged: (val) {
                      ref.read(studentsListProvider.notifier).load(
                            search: val,
                            status: _statusFilter,
                          );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.filter_list,
                    color: _statusFilter.isNotEmpty
                        ? AppColors.accent
                        : AppColors.primary,
                  ),
                  onSelected: (val) {
                    setState(() => _statusFilter = val);
                    ref.read(studentsListProvider.notifier).load(
                          search: _searchCtrl.text,
                          status: val,
                        );
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: '', child: Text('Tous')),
                    const PopupMenuItem(
                        value: 'ACTIVE', child: Text('Actifs')),
                    const PopupMenuItem(
                        value: 'SUSPENDED', child: Text('Suspendus')),
                    const PopupMenuItem(
                        value: 'GRADUATED', child: Text('Diplômés')),
                  ],
                ),
              ],
            ),
          ),

          // Liste
          Expanded(
            child: studentsAsync.when(
              data: (students) {
                if (students.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school_outlined,
                            size: 56, color: Colors.grey.shade200),
                        const SizedBox(height: 12),
                        const Text('Aucun élève trouvé',
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: students.length,
                  itemBuilder: (_, i) => _StudentCard(
                    student: students[i],
                    onTap: () =>
                        _showStudentDetail(context, students[i]),
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error,
                        color: AppColors.error, size: 40),
                    const SizedBox(height: 12),
                    const Text('Erreur de chargement'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref
                          .read(studentsListProvider.notifier)
                          .refresh(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStudentDetail(BuildContext context, StudentModel student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StudentDetailSheet(
        student: student,
        onUpdated: () =>
            ref.read(studentsListProvider.notifier).refresh(),
      ),
    );
  }
}

// ── Carte élève ────────────────────────────────────────────────────────────

class _StudentCard extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onTap;

  const _StudentCard({required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(student.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor:
                    AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  (student.fullName ?? 'E').substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName ?? 'Sans nom',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    if (student.phone != null)
                      Text(
                        student.phone!,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: student.progressPercent,
                              minHeight: 5,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation(
                                  AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${student.hoursCompleted}/${student.hoursRequired}h',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusLabel(student.status),
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'ACTIVE':
        return AppColors.success;
      case 'GRADUATED':
        return AppColors.primary;
      default:
        return AppColors.error;
    }
  }

  String _statusLabel(String s) {
    switch (s.toUpperCase()) {
      case 'ACTIVE':
        return 'Actif';
      case 'GRADUATED':
        return 'Diplômé';
      case 'SUSPENDED':
        return 'Suspendu';
      default:
        return s;
    }
  }
}

// ── Fiche détail élève ─────────────────────────────────────────────────────

class _StudentDetailSheet extends ConsumerStatefulWidget {
  final StudentModel student;
  final VoidCallback onUpdated;

  const _StudentDetailSheet({
    required this.student,
    required this.onUpdated,
  });

  @override
  ConsumerState<_StudentDetailSheet> createState() =>
      _StudentDetailSheetState();
}

class _StudentDetailSheetState extends ConsumerState<_StudentDetailSheet> {
  late String _status;
  late double _hoursCompleted;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _status = widget.student.status;
    _hoursCompleted = widget.student.hoursCompleted.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header élève
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor:
                    AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  (student.fullName ?? 'E').substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName ?? 'Sans nom',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                    if (student.phone != null)
                      Text(student.phone!,
                          style: const TextStyle(
                              color: AppColors.textSecondary)),
                    if (student.registrationNumber != null)
                      Text(
                        'N° ${student.registrationNumber}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Progression des heures
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Heures de conduite',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '${_hoursCompleted.round()}/${student.hoursRequired}h',
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _hoursCompleted,
            min: 0,
            max: student.hoursRequired.toDouble(),
            divisions: student.hoursRequired,
            label: '${_hoursCompleted.round()}h',
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _hoursCompleted = v),
          ),
          const SizedBox(height: 16),

          // Statut
          const Text('Statut',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            selected: {_status},
            onSelectionChanged: (s) =>
                setState(() => _status = s.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor:
                  AppColors.primary.withValues(alpha: 0.1),
              selectedForegroundColor: AppColors.primary,
            ),
            segments: const [
              ButtonSegment(value: 'ACTIVE', label: Text('Actif')),
              ButtonSegment(value: 'SUSPENDED', label: Text('Suspendu')),
              ButtonSegment(value: 'GRADUATED', label: Text('Diplômé')),
            ],
          ),
          const SizedBox(height: 24),

          // Boutons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Enregistrer',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(studentRepositoryProvider);
      // Mettre à jour les heures
      await repo.updateStudentHours(
          widget.student.id, _hoursCompleted.toInt());
      // Mettre à jour le statut
      await repo.updateStudentStatus(widget.student.id, _status);

      if (mounted) {
        Navigator.pop(context);
        widget.onUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Élève mis à jour avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
