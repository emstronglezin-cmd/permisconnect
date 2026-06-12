import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/quiz_provider.dart';

class QuizCategoriesScreen extends ConsumerWidget {
  const QuizCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(quizCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Code de la Route'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return _buildFallbackCategories(context);
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(quizCategoriesProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              itemBuilder: (ctx, i) {
                final cat = categories[i];
                return _CategoryCard(
                  name: cat.name,
                  description: cat.description ?? '',
                  questionCount: cat.questionCount,
                  color: _hexToColor(cat.color),
                  icon: _categoryIcon(cat.name),
                  onTap: () => context.go(
                    '/student/quiz/session/${cat.id}?name=${Uri.encodeComponent(cat.name)}',
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildFallbackCategories(context),
      ),
    );
  }

  // Catégories de repli si Supabase est vide
  Widget _buildFallbackCategories(BuildContext context) {
    final fallback = [
      {'name': 'Panneaux de signalisation', 'count': 15, 'icon': Icons.signpost},
      {'name': 'Priorités', 'count': 10, 'icon': Icons.priority_high},
      {'name': 'Règles de conduite', 'count': 20, 'icon': Icons.rule},
      {'name': 'Distances de sécurité', 'count': 8, 'icon': Icons.social_distance},
      {'name': 'Alcool & Drogues', 'count': 10, 'icon': Icons.local_bar},
      {'name': 'Premiers secours', 'count': 12, 'icon': Icons.local_hospital},
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: fallback.length,
      itemBuilder: (ctx, i) {
        final cat = fallback[i];
        return _CategoryCard(
          name: cat['name'] as String,
          description: 'Questions sur ${cat['name']}',
          questionCount: cat['count'] as int,
          color: AppColors.primary,
          icon: cat['icon'] as IconData,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Connectez votre base Supabase pour accéder aux quiz')),
          ),
        );
      },
    );
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  IconData _categoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('panneau')) return Icons.signpost;
    if (lower.contains('priorité')) return Icons.priority_high;
    if (lower.contains('alcool') || lower.contains('drogue')) return Icons.local_bar;
    if (lower.contains('secours')) return Icons.local_hospital;
    if (lower.contains('distance')) return Icons.social_distance;
    if (lower.contains('vitesse')) return Icons.speed;
    return Icons.quiz;
  }
}

class _CategoryCard extends StatelessWidget {
  final String name;
  final String description;
  final int questionCount;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.name,
    required this.description,
    required this.questionCount,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(description,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.quiz_outlined,
                            size: 14, color: color),
                        const SizedBox(width: 4),
                        Text('$questionCount questions',
                            style: TextStyle(color: color, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
