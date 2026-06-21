import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/student_provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../data/models/instructor_model.dart';

class InstructorsScreen extends ConsumerWidget {
  const InstructorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instructorsAsync = ref.watch(instructorsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Moniteurs'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(instructorsListProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _showInstructorDialog(context, ref),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: instructorsAsync.when(
        data: (instructors) {
          if (instructors.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.drive_eta, size: 64, color: Colors.grey.shade200),
                  const SizedBox(height: 12),
                  const Text('Aucun moniteur enregistré',
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showInstructorDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un moniteur'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
            itemCount: instructors.length,
            itemBuilder: (_, i) => _InstructorCard(
              instructor: instructors[i],
              onEdit: () =>
                  _showInstructorDialog(context, ref, existing: instructors[i]),
              onToggle: () =>
                  _toggleAvailability(context, ref, instructors[i]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Erreur de chargement'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(instructorsListProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInstructorDialog(BuildContext context, WidgetRef ref,
      {InstructorModel? existing}) {
    showDialog(
      context: context,
      builder: (_) => _InstructorFormDialog(
        existing: existing,
        onSaved: () => ref.invalidate(instructorsListProvider),
      ),
    );
  }

  Future<void> _toggleAvailability(
      BuildContext context, WidgetRef ref, InstructorModel instructor) async {
    try {
      final client = ref.read(supabaseClientProvider);
      await client
          .from('instructors')
          .update({'is_available': !instructor.isAvailable}).eq(
              'id', instructor.id);
      ref.invalidate(instructorsListProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }
}

// ── Carte moniteur ─────────────────────────────────────────────────────────

class _InstructorCard extends StatelessWidget {
  final InstructorModel instructor;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  const _InstructorCard({
    required this.instructor,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.accent.withValues(alpha: 0.1),
              child: Text(
                (instructor.fullName ?? 'M').substring(0, 1).toUpperCase(),
                style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instructor.fullName ?? 'Moniteur',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  if (instructor.phone != null)
                    Text(
                      instructor.phone!,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  if (instructor.specialization != null)
                    Text(
                      instructor.specialization!,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        instructor.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.assignment,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${instructor.totalLessons} cours',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: instructor.isAvailable
                          ? AppColors.success.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      instructor.isAvailable ? 'Disponible' : 'Occupé',
                      style: TextStyle(
                          color: instructor.isAvailable
                              ? AppColors.success
                              : Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dialog formulaire moniteur ─────────────────────────────────────────────

class _InstructorFormDialog extends ConsumerStatefulWidget {
  final InstructorModel? existing;
  final VoidCallback onSaved;

  const _InstructorFormDialog({this.existing, required this.onSaved});

  @override
  ConsumerState<_InstructorFormDialog> createState() =>
      _InstructorFormDialogState();
}

class _InstructorFormDialogState
    extends ConsumerState<_InstructorFormDialog> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _specCtrl = TextEditingController();
  bool _isAvailable = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final i = widget.existing!;
      _nameCtrl.text = i.fullName ?? '';
      _phoneCtrl.text = i.phone ?? '';
      _licenseCtrl.text = i.licenseNumber ?? '';
      _specCtrl.text = i.specialization ?? '';
      _isAvailable = i.isAvailable;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _licenseCtrl.dispose();
    _specCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing != null ? 'Modifier le moniteur' : 'Nouveau moniteur',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Field(
                controller: _nameCtrl,
                label: 'Nom complet',
                icon: Icons.person),
            const SizedBox(height: 12),
            _Field(
                controller: _phoneCtrl,
                label: 'Téléphone',
                icon: Icons.phone,
                keyboard: TextInputType.phone),
            const SizedBox(height: 12),
            _Field(
                controller: _licenseCtrl,
                label: 'N° permis/agrément',
                icon: Icons.badge),
            const SizedBox(height: 12),
            _Field(
                controller: _specCtrl,
                label: 'Spécialisation',
                icon: Icons.school),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _isAvailable,
              onChanged: (v) => setState(() => _isAvailable = v),
              title: const Text('Disponible'),
              activeThumbColor: AppColors.success,
              contentPadding: EdgeInsets.zero,
            ),
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
              : Text(
                  widget.existing != null ? 'Modifier' : 'Ajouter',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le nom est obligatoire')));
      return;
    }

    setState(() => _loading = true);
    try {
      final client = ref.read(supabaseClientProvider);

      if (widget.existing != null) {
        // UPDATE instructeur
        await client.from('instructors').update({
          'license_number': _licenseCtrl.text.trim(),
          'specialization': _specCtrl.text.trim(),
          'is_available': _isAvailable,
        }).eq('id', widget.existing!.id);

        // UPDATE profile associé
        await client.from('profiles').update({
          'full_name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
        }).eq('id', widget.existing!.profileId);
      } else {
        // Pour créer un nouveau moniteur, il faut créer un profil d'abord
        // Note: ceci nécessite un service_role ou une fonction Edge
        // Pour l'instant on affiche un message informatif
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Pour ajouter un moniteur, créez d\'abord son compte depuis Supabase Dashboard, puis il pourra s\'inscrire avec son email.'),
              duration: Duration(seconds: 5),
            ),
          );
          return;
        }
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Moniteur mis à jour avec succès'),
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

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboard;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboard = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
