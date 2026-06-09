import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _localeInit = false;

  final List<Map<String, dynamic>> _schedule = [
    {'id': '1', 'time': '08:00', 'duration': '1h30', 'student': 'Kouamé Issa', 'instructor': 'M. Ouédraogo', 'vehicle': 'Toyota Corolla', 'type': 'CONDUITE', 'color': const Color(0xFF1E65C5)},
    {'id': '2', 'time': '09:30', 'duration': '2h00', 'student': 'Fatou Coulibaly', 'instructor': 'Mme Kaboré', 'vehicle': null, 'type': 'CODE', 'color': const Color(0xFFFF7F27)},
    {'id': '3', 'time': '11:30', 'duration': '1h30', 'student': 'Aïssatou Traoré', 'instructor': 'M. Ouédraogo', 'vehicle': 'Peugeot 308', 'type': 'CONDUITE', 'color': const Color(0xFF1E65C5)},
    {'id': '4', 'time': '14:00', 'duration': '1h30', 'student': 'Bintou Kaboré', 'instructor': 'M. Traoré', 'vehicle': 'Toyota Yaris', 'type': 'CONDUITE', 'color': const Color(0xFF1E65C5)},
    {'id': '5', 'time': '15:30', 'duration': '1h00', 'student': 'Seydou Diallo', 'instructor': 'M. Traoré', 'vehicle': null, 'type': 'EXAMEN', 'color': const Color(0xFF9B59B6)},
  ];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR').then((_) {
      if (mounted) setState(() => _localeInit = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E65C5),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Planning',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            onPressed: () => _showAddLessonDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Sélecteur de jours horizontal
            _buildWeekSelector(),
            const SizedBox(height: 20),

            // Résumé du jour
            _buildDaySummary(),
            const SizedBox(height: 20),

            // Planning du jour
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Cours du jour',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E))),
            ),
            const SizedBox(height: 12),

            ..._schedule.map((item) => _buildScheduleItem(item)),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekSelector() {
    final today = DateTime.now();
    final List<DateTime> days = List.generate(7, (i) => today.add(Duration(days: i - 2)));

    return SizedBox(
      height: 76,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, i) {
          final day = days[i];
          final isSelected = day.day == _selectedDate.day &&
              day.month == _selectedDate.month;
          final isToday = day.day == today.day && day.month == today.month;
          final dayName = _localeInit
              ? DateFormat('EEE', 'fr_FR').format(day)
              : DateFormat('EEE').format(day);

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              width: 52,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1E65C5) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isToday && !isSelected
                    ? Border.all(color: const Color(0xFF1E65C5), width: 2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? const Color(0xFF1E65C5).withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8, offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(dayName.toUpperCase(),
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white70
                              : const Color(0xFF9CA3AF))),
                  const SizedBox(height: 4),
                  Text('${day.day}',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? const Color(0xFF1E65C5)
                                  : const Color(0xFF1A1A2E))),
                  if (isToday)
                    Container(
                      width: 5, height: 5,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : const Color(0xFFFF7F27),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDaySummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E65C5), Color(0xFF3D7DD4)]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E65C5).withValues(alpha: 0.3),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildDayStat('${_schedule.length}', 'Cours total'),
          _buildDayDivider(),
          _buildDayStat('${_schedule.where((s) => s['type'] == 'CONDUITE').length}', 'Conduite'),
          _buildDayDivider(),
          _buildDayStat('3', 'Moniteurs'),
          _buildDayDivider(),
          _buildDayStat('3', 'Véhicules'),
        ],
      ),
    );
  }

  Widget _buildDayStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.75))),
        ],
      ),
    );
  }

  Widget _buildDayDivider() {
    return Container(
      width: 1, height: 30,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

  Widget _buildScheduleItem(Map<String, dynamic> item) {
    final color = item['color'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heure
          SizedBox(
            width: 50,
            child: Column(
              children: [
                Text(item['time'] as String,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 4),
                Container(
                  width: 2,
                  height: 80,
                  color: const Color(0xFFE5E7EB),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Carte
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(color: color, width: 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.08),
                    blurRadius: 8, offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(item['type'] as String,
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: color)),
                      ),
                      Text(item['duration'] as String,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(item['student'] as String,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.badge_rounded, size: 12, color: Color(0xFF6B7280)),
                      const SizedBox(width: 4),
                      Text(item['instructor'] as String,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      if (item['vehicle'] != null) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.directions_car_rounded, size: 12, color: Color(0xFF6B7280)),
                        const SizedBox(width: 4),
                        Text(item['vehicle'] as String,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddLessonDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24, right: 24, top: 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Planifier un cours',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            const Text('Remplissez les informations du cours à planifier.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E65C5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text('Planifier',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
