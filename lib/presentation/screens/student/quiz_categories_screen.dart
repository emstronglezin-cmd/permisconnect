import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class QuizCategoriesScreen extends StatefulWidget {
  const QuizCategoriesScreen({super.key});

  @override
  State<QuizCategoriesScreen> createState() => _QuizCategoriesScreenState();
}

class _QuizCategoriesScreenState extends State<QuizCategoriesScreen> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await rootBundle.loadString('assets/data/quiz_data.json');
      final json = jsonDecode(data);
      setState(() {
        _categories = List<Map<String, dynamic>>.from(json['categories']);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _categories = _defaultCategories;
        _isLoading = false;
      });
    }
  }

  final List<Map<String, dynamic>> _defaultCategories = [
    {'id': 'cat_001', 'name': 'Panneaux de Signalisation', 'description': 'Lecture des panneaux routiers', 'color': '#E74C3C', 'question_count': 20, 'order_index': 1},
    {'id': 'cat_002', 'name': 'Priorités et Intersections', 'description': 'Règles de priorité', 'color': '#F39C12', 'question_count': 15, 'order_index': 2},
    {'id': 'cat_003', 'name': 'Vitesse et Distances', 'description': 'Limitations de vitesse', 'color': '#3498DB', 'question_count': 15, 'order_index': 3},
    {'id': 'cat_004', 'name': 'Dépassement et Stationnement', 'description': 'Règles de dépassement', 'color': '#9B59B6', 'question_count': 12, 'order_index': 4},
    {'id': 'cat_005', 'name': 'Sécurité Routière', 'description': 'Alcool, fatigue, équipements', 'color': '#27AE60', 'question_count': 18, 'order_index': 5},
    {'id': 'cat_006', 'name': 'Feux de Signalisation', 'description': 'Signification des feux', 'color': '#1E65C5', 'question_count': 10, 'order_index': 6},
  ];

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF1E65C5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
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
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Code de la Route',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.play_circle_filled_rounded,
                                      color: Color(0xFFFF7F27), size: 16),
                                  const SizedBox(width: 6),
                                  const Text('Examen Blanc',
                                      style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Statistiques globales
                        Row(
                          children: [
                            _buildQuickStat('6', 'Thèmes'),
                            const SizedBox(width: 20),
                            _buildQuickStat('90', 'Questions'),
                            const SizedBox(width: 20),
                            _buildQuickStat('75%', 'Score moyen'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bouton examen blanc
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: GestureDetector(
                onTap: () => context.push('/student/quiz/session/exam'),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF7F27), Color(0xFFFF9A52)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF7F27).withValues(alpha: 0.3),
                        blurRadius: 16, offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.assignment_turned_in_rounded,
                            color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Examen Blanc Complet',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                            Text('40 questions • 40 minutes',
                                style: TextStyle(fontSize: 13, color: Colors.white70)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
            sliver: _isLoading
                ? const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()))
                : SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.9,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final cat = _categories[index];
                        return _buildCategoryCard(cat);
                      },
                      childCount: _categories.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7))),
      ],
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> cat) {
    final color = _parseColor(cat['color'] ?? '#1E65C5');
    final icons = [
      Icons.traffic_rounded,
      Icons.alt_route_rounded,
      Icons.speed_rounded,
      Icons.local_parking_rounded,
      Icons.health_and_safety_rounded,
      Icons.traffic_rounded,
    ];
    final index = (cat['order_index'] as int? ?? 1) - 1;
    final icon = icons[index.clamp(0, icons.length - 1)];
    final questionCount = cat['question_count'] as int? ?? 10;

    // Score simulé
    final scores = [80, 65, 55, 70, 90, 75];
    final score = scores[index.clamp(0, scores.length - 1)];

    return GestureDetector(
      onTap: () => context.push('/student/quiz/session/${cat['id']}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 16, offset: const Offset(0, 4),
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
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$score%',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color)),
                ),
              ],
            ),
            const Spacer(),
            Text(cat['name'] ?? '',
                maxLines: 2,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 4),
            Text('$questionCount questions',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
