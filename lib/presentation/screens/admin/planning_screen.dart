import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/lesson_provider.dart';
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
            onPressed: () =>
                ref.read(allLessonsProvider.notifier).load(),
          ),
        ],
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
                  firstDay:
                      DateTime.now().subtract(const Duration(days: 90)),
                  lastDay:
                      DateTime.now().add(const Duration(days: 180)),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                  eventLoader: (d) {
                    final key = DateTime(d.year, d.month, d.day);
                    return eventMap[key] ?? [];
                  },
                  onDaySelected: (sel, foc) =>
                      setState(() {
                        _selectedDay = sel;
                        _focusedDay = foc;
                      }),
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  locale: 'fr_FR',
                ),
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
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
                        style: TextStyle(
                            color: AppColors.primary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: selectedLessons.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_available,
                                size: 40, color: Colors.grey.shade300),
                            const SizedBox(height: 10),
                            Text('Aucun cours ce jour',
                                style: TextStyle(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: selectedLessons.length,
                        itemBuilder: (ctx, i) =>
                            _PlanningItem(lesson: selectedLessons[i]),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Erreur de chargement')),
      ),
    );
  }
}

class _PlanningItem extends StatelessWidget {
  final LessonModel lesson;
  const _PlanningItem({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            '${lesson.scheduledAt.hour.toString().padLeft(2, '0')}:${lesson.scheduledAt.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 11),
          ),
        ),
        title: Text(
          lesson.studentName ?? 'Élève',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${lesson.instructorName ?? 'Moniteur'} • ${lesson.durationMinutes} min',
        ),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            lesson.vehicleName ?? '',
            style: TextStyle(color: AppColors.primary, fontSize: 11),
          ),
        ),
      ),
    );
  }
}
