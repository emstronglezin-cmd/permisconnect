import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  bool _localeInitialized = false;

  final List<Map<String, dynamic>> _lessons = [
    {
      'id': '1',
      'type': 'CONDUITE',
      'title': 'Conduite en Ville',
      'date': DateTime.now().add(const Duration(days: 2)),
      'time': '14:00',
      'duration': '1h30',
      'instructor': 'M. Ouédraogo',
      'vehicle': 'Toyota Corolla - AB 1234',
      'location': 'Départ école - Avenue Kwame Nkrumah',
      'status': 'CONFIRMED',
      'color': const Color(0xFF1E65C5),
    },
    {
      'id': '2',
      'type': 'CODE',
      'title': 'Cours Code de la Route',
      'date': DateTime.now().add(const Duration(days: 4)),
      'time': '09:30',
      'duration': '2h00',
      'instructor': 'Mme Kaboré',
      'vehicle': null,
      'location': 'Salle de cours - PermisConnect',
      'status': 'CONFIRMED',
      'color': const Color(0xFFFF7F27),
    },
    {
      'id': '3',
      'type': 'EXAMEN',
      'title': 'Examen Blanc Interne',
      'date': DateTime.now().add(const Duration(days: 7)),
      'time': '08:00',
      'duration': '1h00',
      'instructor': 'M. Traoré',
      'vehicle': null,
      'location': 'Salle d\'examen',
      'status': 'PENDING',
      'color': const Color(0xFF9B59B6),
    },
    {
      'id': '4',
      'type': 'CONDUITE',
      'title': 'Conduite Route Nationale',
      'date': DateTime.now().add(const Duration(days: 10)),
      'time': '15:30',
      'duration': '2h00',
      'instructor': 'M. Ouédraogo',
      'vehicle': 'Peugeot 308 - CD 5678',
      'location': 'Départ école',
      'status': 'CONFIRMED',
      'color': const Color(0xFF1E65C5),
    },
    {
      'id': '5',
      'type': 'CONDUITE',
      'title': 'Manœuvres (Créneau)',
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'time': '10:00',
      'duration': '1h30',
      'instructor': 'M. Ouédraogo',
      'vehicle': 'Toyota Corolla - AB 1234',
      'location': 'Parking école',
      'status': 'COMPLETED',
      'color': const Color(0xFF27AE60),
    },
  ];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR').then((_) {
      if (mounted) setState(() => _localeInitialized = true);
    });
  }

  List<Map<String, dynamic>> get _upcomingLessons {
    final now = DateTime.now();
    return _lessons
        .where((l) => (l['date'] as DateTime).isAfter(now))
        .toList()
      ..sort((a, b) =>
          (a['date'] as DateTime).compareTo(b['date'] as DateTime));
  }

  List<Map<String, dynamic>> get _pastLessons {
    final now = DateTime.now();
    return _lessons
        .where((l) => (l['date'] as DateTime).isBefore(now))
        .toList()
      ..sort((a, b) =>
          (b['date'] as DateTime).compareTo(a['date'] as DateTime));
  }

  String _formatDate(DateTime date) {
    if (!_localeInitialized) {
      return DateFormat('EEE dd MMM').format(date);
    }
    return DateFormat('EEE dd MMM', 'fr_FR').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 80,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1E65C5),
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text('Mon Agenda',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                onPressed: () => _showAddLessonDialog(context),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mini calendrier
                  _buildMiniCalendar(),
                  const SizedBox(height: 24),

                  // Légende
                  _buildLegend(),
                  const SizedBox(height: 24),

                  // Prochains cours
                  const Text('Prochains cours',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 14),

                  ..._upcomingLessons.map((lesson) => _buildLessonCard(lesson)),

                  if (_pastLessons.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Cours précédents',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280))),
                    const SizedBox(height: 14),
                    ..._pastLessons.map((lesson) => _buildLessonCard(lesson, isPast: true)),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCalendar() {
    final now = DateTime.now();
    final firstDayOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday % 7;

    final monthName = _localeInitialized
        ? DateFormat('MMMM yyyy', 'fr_FR').format(_focusedMonth)
        : DateFormat('MMMM yyyy').format(_focusedMonth);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded,
                    color: Color(0xFF6B7280)),
                onPressed: () => setState(() {
                  _focusedMonth = DateTime(
                      _focusedMonth.year, _focusedMonth.month - 1, 1);
                }),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                monthName[0].toUpperCase() + monthName.substring(1),
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E)),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFF6B7280)),
                onPressed: () => setState(() {
                  _focusedMonth = DateTime(
                      _focusedMonth.year, _focusedMonth.month + 1, 1);
                }),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Jours de la semaine
          Row(
            children: ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF9CA3AF))),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Jours
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 4,
              crossAxisSpacing: 0,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startWeekday) return const SizedBox();

              final day = index - startWeekday + 1;
              final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
              final isToday = date.day == now.day &&
                  date.month == now.month &&
                  date.year == now.year;
              final isSelected = date.day == _selectedDate.day &&
                  date.month == _selectedDate.month &&
                  date.year == _selectedDate.year;

              // Vérifier s'il y a des cours ce jour
              final hasLesson = _lessons.any((l) {
                final ld = l['date'] as DateTime;
                return ld.day == day &&
                    ld.month == _focusedMonth.month &&
                    ld.year == _focusedMonth.year;
              });

              return GestureDetector(
                onTap: () => setState(() => _selectedDate = date),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1E65C5)
                        : isToday
                            ? const Color(0xFF1E65C5).withValues(alpha: 0.1)
                            : null,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text('$day',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: isToday || isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isSelected
                                  ? Colors.white
                                  : isToday
                                      ? const Color(0xFF1E65C5)
                                      : const Color(0xFF4B5563))),
                      if (hasLesson && !isSelected)
                        Positioned(
                          bottom: 3,
                          child: Container(
                            width: 4, height: 4,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF7F27),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(const Color(0xFF1E65C5), 'Conduite'),
        const SizedBox(width: 16),
        _buildLegendItem(const Color(0xFFFF7F27), 'Code'),
        const SizedBox(width: 16),
        _buildLegendItem(const Color(0xFF9B59B6), 'Examen'),
        const SizedBox(width: 16),
        _buildLegendItem(const Color(0xFF27AE60), 'Terminé'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
      ],
    );
  }

  Widget _buildLessonCard(Map<String, dynamic> lesson, {bool isPast = false}) {
    final date = lesson['date'] as DateTime;
    final status = lesson['status'] as String;
    final color = isPast ? const Color(0xFF9CA3AF) : (lesson['color'] as Color);

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'CONFIRMED':
        statusColor = const Color(0xFF27AE60);
        statusLabel = 'Confirmé';
        break;
      case 'PENDING':
        statusColor = const Color(0xFFF39C12);
        statusLabel = 'En attente';
        break;
      case 'COMPLETED':
        statusColor = const Color(0xFF6B7280);
        statusLabel = 'Terminé';
        break;
      case 'CANCELLED':
        statusColor = const Color(0xFFE74C3C);
        statusLabel = 'Annulé';
        break;
      default:
        statusColor = const Color(0xFF6B7280);
        statusLabel = status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isPast ? 0.04 : 0.1),
            blurRadius: 12, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Indicateur coloré
          Container(
            width: 6,
            height: 100,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(lesson['type'] as String,
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: color)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(statusLabel,
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(lesson['title'] as String,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isPast ? const Color(0xFF9CA3AF) : const Color(0xFF1A1A2E))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: color),
                      const SizedBox(width: 4),
                      Text('${_formatDate(date)} • ${lesson['time']} (${lesson['duration']})',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 14, color: color),
                      const SizedBox(width: 4),
                      Text(lesson['instructor'] as String,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    ],
                  ),
                  if (lesson['vehicle'] != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.directions_car_rounded, size: 14, color: color),
                        const SizedBox(width: 4),
                        Text(lesson['vehicle'] as String,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ],
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
        padding: const EdgeInsets.all(24),
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
            const Text('Demander un cours',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            const Text('Contactez votre auto-école pour planifier un cours.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280))),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E65C5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text('Contacter l\'auto-école',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
