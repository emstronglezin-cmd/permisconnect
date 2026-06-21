import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/lesson_provider.dart';
import '../../../presentation/providers/student_provider.dart';
import '../../../data/models/lesson_model.dart';

class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({super.key});

  @override
  ConsumerState<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends ConsumerState<PlanningScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final allLessonsAsync = ref.watch(allLessonsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Planning des cours'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(allLessonsProvider.notifier).load(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateLessonDialog(context),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un cours',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: allLessonsAsync.when(
        data: (lessons) {
          final eventMap = <DateTime, List<LessonModel>>{};
          for (final lesson in lessons) {
            final day = DateTime(
              lesson.scheduledAt.year,
              lesson.scheduledAt.month,
              lesson.scheduledAt.day,
            );
            eventMap[day] = [...(eventMap[day] ?? []), lesson];
          }

          final selected = DateTime(
              _selectedDay.year, _selectedDay.month, _selectedDay.day);
          final selectedLessons = eventMap[selected] ?? [];

          return Column(
            children: [
              Container(
                color: Colors.white,
                child: TableCalendar(
                  firstDay: DateTime.now().subtract(const Duration(days: 90)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                  eventLoader: (d) {
                    final key = DateTime(d.year, d.month, d.day);
                    return eventMap[key] ?? [];
                  },
                  onDaySelected: (sel, foc) => setState(() {
                    _selectedDay = sel;
                    _focusedDay = foc;
                  }),
                  calendarStyle: CalendarStyle(
                    selectedDecoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  locale: 'fr_FR',
                ),
              ),

              // Barre date + compteur
              Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Text(
                      '${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${selectedLessons.length} cours',
                        style: const TextStyle(
                            color: AppColors.primary, fontSize: 12),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _showCreateLessonDialog(context,
                          initialDate: _selectedDay),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Ajouter',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),

              // Liste des cours
              Expanded(
                child: selectedLessons.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_available,
                                size: 52, color: Colors.grey.shade200),
                            const SizedBox(height: 12),
                            const Text('Aucun cours ce jour',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 15)),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () => _showCreateLessonDialog(context,
                                  initialDate: _selectedDay),
                              icon: const Icon(Icons.add),
                              label: const Text('Planifier un cours'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                        itemCount: selectedLessons.length,
                        itemBuilder: (ctx, i) => _PlanningItem(
                          lesson: selectedLessons[i],
                          onEdit: () => _showEditLessonDialog(
                              context, selectedLessons[i]),
                          onCancel: () => _confirmCancel(
                              context, selectedLessons[i]),
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Erreur de chargement'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.read(allLessonsProvider.notifier).load(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dialog créer un cours ──────────────────────────────────────────────────

  Future<void> _showCreateLessonDialog(BuildContext context,
      {DateTime? initialDate}) async {
    await showDialog(
      context: context,
      builder: (ctx) => _LessonFormDialog(
        initialDate: initialDate ?? _selectedDay,
        onSaved: () {
          ref.read(allLessonsProvider.notifier).load();
        },
      ),
    );
  }

  Future<void> _showEditLessonDialog(
      BuildContext context, LessonModel lesson) async {
    await showDialog(
      context: context,
      builder: (ctx) => _LessonFormDialog(
        initialDate: lesson.scheduledAt,
        existingLesson: lesson,
        onSaved: () {
          ref.read(allLessonsProvider.notifier).load();
        },
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, LessonModel lesson) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler ce cours ?'),
        content: Text(
            'Confirmer l\'annulation du cours de ${lesson.studentName ?? "cet élève"} ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Non')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            child: const Text('Annuler le cours'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(allLessonsProvider.notifier).cancel(lesson.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cours annulé'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// ── Widget item planning ───────────────────────────────────────────────────

class _PlanningItem extends StatelessWidget {
  final LessonModel lesson;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  const _PlanningItem({
    required this.lesson,
    required this.onEdit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (lesson.status.toUpperCase()) {
      case 'COMPLETED':
        statusColor = AppColors.success;
        break;
      case 'CANCELLED':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Heure
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    lesson.scheduledAt.hour.toString().padLeft(2, '0'),
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        height: 1.1),
                  ),
                  Text(
                    lesson.scheduledAt.minute.toString().padLeft(2, '0'),
                    style: TextStyle(
                        color: statusColor, fontSize: 13, height: 1.1),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.studentName ?? 'Élève',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        lesson.instructorName ?? 'Moniteur',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.timer_outlined,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${lesson.durationMinutes} min',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  if (lesson.vehicleName != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.directions_car,
                            size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          lesson.vehicleName!,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Statut + actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(lesson.status),
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 6),
                if (lesson.status.toUpperCase() != 'CANCELLED' &&
                    lesson.status.toUpperCase() != 'COMPLETED')
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: onEdit,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.edit,
                              size: 14, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: onCancel,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.close,
                              size: 14, color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String s) {
    switch (s.toUpperCase()) {
      case 'SCHEDULED':
        return 'Planifié';
      case 'COMPLETED':
        return 'Terminé';
      case 'CANCELLED':
        return 'Annulé';
      default:
        return s;
    }
  }
}

// ── Dialog formulaire cours ────────────────────────────────────────────────

class _LessonFormDialog extends ConsumerStatefulWidget {
  final DateTime initialDate;
  final LessonModel? existingLesson;
  final VoidCallback onSaved;

  const _LessonFormDialog({
    required this.initialDate,
    this.existingLesson,
    required this.onSaved,
  });

  @override
  ConsumerState<_LessonFormDialog> createState() => _LessonFormDialogState();
}

class _LessonFormDialogState extends ConsumerState<_LessonFormDialog> {
  late DateTime _selectedDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 0);
  String? _selectedStudentId;
  String? _selectedInstructorId;
  String? _selectedVehicleId;
  String _lessonType = 'practical';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    if (widget.existingLesson != null) {
      final l = widget.existingLesson!;
      _startTime = TimeOfDay(
          hour: l.scheduledAt.hour, minute: l.scheduledAt.minute);
      _endTime = TimeOfDay(
          hour: (l.scheduledAt.hour + l.durationMinutes ~/ 60) % 24,
          minute: l.scheduledAt.minute + l.durationMinutes % 60);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsListProvider);
    final instructorsAsync = ref.watch(instructorsListProvider);
    final vehiclesAsync = ref.watch(vehiclesListProvider);

    final isEdit = widget.existingLesson != null;

    return AlertDialog(
      title: Text(
        isEdit ? 'Modifier le cours' : 'Nouveau cours',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date
            const _SectionLabel(label: 'Date'),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  locale: const Locale('fr', 'FR'),
                );
                if (d != null) setState(() => _selectedDate = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Horaires
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel(label: 'Début'),
                      _TimePickerButton(
                        time: _startTime,
                        onTap: () async {
                          final t = await showTimePicker(
                              context: context, initialTime: _startTime);
                          if (t != null) setState(() => _startTime = t);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel(label: 'Fin'),
                      _TimePickerButton(
                        time: _endTime,
                        onTap: () async {
                          final t = await showTimePicker(
                              context: context, initialTime: _endTime);
                          if (t != null) setState(() => _endTime = t);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Élève
            const _SectionLabel(label: 'Élève'),
            studentsAsync.when(
              data: (students) => DropdownButtonFormField<String>(
                initialValue: _selectedStudentId,
                hint: const Text('Choisir un élève'),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300)),
                ),
                items: students
                    .map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.fullName ?? 'Élève',
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedStudentId = v),
              ),
              loading: () =>
                  const LinearProgressIndicator(),
              error: (_, __) =>
                  const Text('Impossible de charger les élèves'),
            ),
            const SizedBox(height: 14),

            // Moniteur
            const _SectionLabel(label: 'Moniteur'),
            instructorsAsync.when(
              data: (instructors) => DropdownButtonFormField<String>(
                initialValue: _selectedInstructorId,
                hint: const Text('Choisir un moniteur'),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300)),
                ),
                items: instructors
                    .map((i) => DropdownMenuItem(
                          value: i.id,
                          child: Text(i.fullName ?? 'Moniteur',
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedInstructorId = v),
              ),
              loading: () =>
                  const LinearProgressIndicator(),
              error: (_, __) =>
                  const Text('Impossible de charger les moniteurs'),
            ),
            const SizedBox(height: 14),

            // Véhicule
            const _SectionLabel(label: 'Véhicule'),
            vehiclesAsync.when(
              data: (vehicles) => DropdownButtonFormField<String>(
                initialValue: _selectedVehicleId,
                hint: const Text('Choisir un véhicule'),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300)),
                ),
                items: vehicles
                    .where((v) => v.isAvailable)
                    .map((v) => DropdownMenuItem(
                          value: v.id,
                          child: Text(v.fullName,
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedVehicleId = v),
              ),
              loading: () =>
                  const LinearProgressIndicator(),
              error: (_, __) =>
                  const Text('Impossible de charger les véhicules'),
            ),
            const SizedBox(height: 14),

            // Type de cours
            const _SectionLabel(label: 'Type de cours'),
            DropdownButtonFormField<String>(
              initialValue: _lessonType,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300)),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'practical',
                    child: Text('Cours de conduite')),
                DropdownMenuItem(
                    value: 'theory',
                    child: Text('Cours de code')),
                DropdownMenuItem(
                    value: 'evaluation',
                    child: Text('Évaluation')),
              ],
              onChanged: (v) =>
                  setState(() => _lessonType = v ?? 'practical'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(isEdit ? 'Modifier' : 'Créer',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez choisir un élève')));
      return;
    }

    setState(() => _loading = true);

    try {
      final dateStr =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final startTimeStr =
          '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00';
      final endTimeStr =
          '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}:00';

      final data = {
        'student_id': _selectedStudentId,
        if (_selectedInstructorId != null)
          'instructor_id': _selectedInstructorId,
        if (_selectedVehicleId != null) 'vehicle_id': _selectedVehicleId,
        'scheduled_date': dateStr,
        'start_time': startTimeStr,
        'end_time': endTimeStr,
        'lesson_type': _lessonType,
        'status': 'SCHEDULED',
      };

      await ref.read(lessonRepositoryProvider).createLesson(data);

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingLesson != null
                ? 'Cours modifié avec succès'
                : 'Cours créé avec succès'),
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

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimePickerButton({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
