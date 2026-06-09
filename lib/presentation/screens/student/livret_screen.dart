import 'package:flutter/material.dart';

class LivretScreen extends StatefulWidget {
  const LivretScreen({super.key});

  @override
  State<LivretScreen> createState() => _LivretScreenState();
}

class _LivretScreenState extends State<LivretScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // ignore: unused_field
  int _selectedCategory = 0;

  final List<Map<String, dynamic>> _skillCategories = [
    {
      'id': 'vehicle',
      'name': 'Maîtrise du Véhicule',
      'icon': Icons.directions_car_rounded,
      'color': const Color(0xFF1E65C5),
      'progress': 0.70,
      'validated': 7,
      'total': 10,
    },
    {
      'id': 'circulation',
      'name': 'Règles de Circulation',
      'icon': Icons.traffic_rounded,
      'color': const Color(0xFFFF7F27),
      'progress': 0.85,
      'validated': 17,
      'total': 20,
    },
    {
      'id': 'safety',
      'name': 'Sécurité Routière',
      'icon': Icons.health_and_safety_rounded,
      'color': const Color(0xFF27AE60),
      'progress': 0.60,
      'validated': 9,
      'total': 15,
    },
    {
      'id': 'urban',
      'name': 'Conduite Urbaine',
      'icon': Icons.location_city_rounded,
      'color': const Color(0xFF9B59B6),
      'progress': 0.45,
      'validated': 5,
      'total': 11,
    },
  ];

  final Map<String, List<Map<String, dynamic>>> _skills = {
    'vehicle': [
      {'name': 'Démarrage moteur', 'status': 'VALIDATED', 'level': 3, 'date': '15 Jan 2024'},
      {'name': 'Arrêt d\'urgence', 'status': 'VALIDATED', 'level': 3, 'date': '20 Jan 2024'},
      {'name': 'Stationnement créneau', 'status': 'VALIDATED', 'level': 2, 'date': '25 Jan 2024'},
      {'name': 'Demi-tour', 'status': 'IN_PROGRESS', 'level': 2, 'date': null},
      {'name': 'Conduite nuit', 'status': 'IN_PROGRESS', 'level': 1, 'date': null},
      {'name': 'Voie rapide', 'status': 'NOT_STARTED', 'level': 0, 'date': null},
      {'name': 'Stationnement en bataille', 'status': 'VALIDATED', 'level': 3, 'date': '28 Jan'},
      {'name': 'Garage', 'status': 'VALIDATED', 'level': 3, 'date': '02 Fév'},
      {'name': 'Vitesse adaptée', 'status': 'VALIDATED', 'level': 3, 'date': '05 Fév'},
      {'name': 'Rétrogradation', 'status': 'VALIDATED', 'level': 2, 'date': '08 Fév'},
    ],
    'circulation': [
      {'name': 'Priorité à droite', 'status': 'VALIDATED', 'level': 3, 'date': '12 Jan'},
      {'name': 'Cédez le passage', 'status': 'VALIDATED', 'level': 3, 'date': '14 Jan'},
      {'name': 'Feux tricolores', 'status': 'VALIDATED', 'level': 3, 'date': '16 Jan'},
      {'name': 'Dépassement sécurisé', 'status': 'VALIDATED', 'level': 2, 'date': '18 Jan'},
      {'name': 'Insertion autoroute', 'status': 'IN_PROGRESS', 'level': 2, 'date': null},
      {'name': 'Voies de bus', 'status': 'VALIDATED', 'level': 3, 'date': '20 Jan'},
    ],
    'safety': [
      {'name': 'Angles morts', 'status': 'VALIDATED', 'level': 3, 'date': '10 Jan'},
      {'name': 'Distances de sécurité', 'status': 'VALIDATED', 'level': 3, 'date': '12 Jan'},
      {'name': 'Conduite sous pluie', 'status': 'IN_PROGRESS', 'level': 2, 'date': null},
      {'name': 'Chargement véhicule', 'status': 'NOT_STARTED', 'level': 0, 'date': null},
    ],
    'urban': [
      {'name': 'Rond-point', 'status': 'VALIDATED', 'level': 3, 'date': '05 Jan'},
      {'name': 'Piétons traversant', 'status': 'VALIDATED', 'level': 3, 'date': '07 Jan'},
      {'name': 'Voies cyclables', 'status': 'IN_PROGRESS', 'level': 1, 'date': null},
      {'name': 'Passage à niveau', 'status': 'NOT_STARTED', 'level': 0, 'date': null},
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _skillCategories.length, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedCategory = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Progression globale
  double get _globalProgress {
    final total = _skillCategories.fold<int>(0, (sum, c) => sum + (c['total'] as int));
    final validated = _skillCategories.fold<int>(0, (sum, c) => sum + (c['validated'] as int));
    return total > 0 ? validated / total : 0;
  }

  @override
  Widget build(BuildContext context) {
    final totalValidated = _skillCategories.fold<int>(0, (sum, c) => sum + (c['validated'] as int));
    final totalSkills = _skillCategories.fold<int>(0, (sum, c) => sum + (c['total'] as int));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1E65C5),
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1450A0), Color(0xFF3D7DD4)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Carnet de Progression',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        const SizedBox(height: 16),
                        // Progression globale
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              // Cercle de progression global
                              SizedBox(
                                width: 60, height: 60,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: _globalProgress,
                                      strokeWidth: 6,
                                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF7F27)),
                                    ),
                                    Text('${(_globalProgress * 100).toInt()}%',
                                        style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Progression globale',
                                        style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white)),
                                    Text('$totalValidated/$totalSkills compétences validées',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white.withValues(alpha: 0.8))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: const Color(0xFFFF7F27),
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(
                  fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600),
              tabs: _skillCategories
                  .map((cat) => Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cat['icon'] as IconData, size: 16),
                            const SizedBox(width: 6),
                            Text(_shortName(cat['name'] as String)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: _skillCategories.asMap().entries.map((entry) {
            final catId = entry.value['id'] as String;
            final skills = _skills[catId] ?? [];
            final cat = entry.value;
            return _buildSkillList(skills, cat);
          }).toList(),
        ),
      ),
    );
  }

  String _shortName(String name) {
    if (name.length > 14) return '${name.substring(0, 12)}...';
    return name;
  }

  Widget _buildSkillList(List<Map<String, dynamic>> skills, Map<String, dynamic> cat) {
    final color = cat['color'] as Color;
    final validated = skills.where((s) => s['status'] == 'VALIDATED').length;
    final inProgress = skills.where((s) => s['status'] == 'IN_PROGRESS').length;
    final notStarted = skills.where((s) => s['status'] == 'NOT_STARTED').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Résumé catégorie
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                _buildMiniStat('$validated', 'Validées', const Color(0xFF27AE60)),
                _buildDivider(),
                _buildMiniStat('$inProgress', 'En cours', const Color(0xFFF39C12)),
                _buildDivider(),
                _buildMiniStat('$notStarted', 'À faire', const Color(0xFF9CA3AF)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Liste des compétences
          ...skills.asMap().entries.map((entry) {
            return _buildSkillItem(entry.value, color);
          }),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1, height: 30,
      color: const Color(0xFFE5E7EB),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildSkillItem(Map<String, dynamic> skill, Color categoryColor) {
    final status = skill['status'] as String;
    final level = skill['level'] as int;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (status) {
      case 'VALIDATED':
        statusColor = const Color(0xFF27AE60);
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'Validé';
        break;
      case 'IN_PROGRESS':
        statusColor = const Color(0xFFF39C12);
        statusIcon = Icons.radio_button_checked_rounded;
        statusLabel = 'En cours';
        break;
      default:
        statusColor = const Color(0xFFD1D5DB);
        statusIcon = Icons.radio_button_unchecked_rounded;
        statusLabel = 'À faire';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(skill['name'] as String,
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: status == 'NOT_STARTED'
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF1A1A2E))),
                if (skill['date'] != null) ...[
                  const SizedBox(height: 2),
                  Text('Validé le ${skill['date']}',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9CA3AF))),
                ],
              ],
            ),
          ),
          // Étoiles niveau
          Row(
            children: List.generate(3, (i) => Icon(
              i < level ? Icons.star_rounded : Icons.star_outline_rounded,
              color: i < level ? const Color(0xFFF39C12) : const Color(0xFFD1D5DB),
              size: 16,
            )),
          ),
        ],
      ),
    );
  }
}
