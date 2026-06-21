import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/student_provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../data/models/vehicle_model.dart';

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Véhicules'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(vehiclesListProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVehicleDialog(context, ref),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: vehiclesAsync.when(
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car,
                      size: 64, color: Colors.grey.shade200),
                  const SizedBox(height: 12),
                  const Text('Aucun véhicule enregistré',
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showVehicleDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un véhicule'),
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
            itemCount: vehicles.length,
            itemBuilder: (_, i) => _VehicleCard(
              vehicle: vehicles[i],
              onEdit: () => _showVehicleDialog(context, ref,
                  existing: vehicles[i]),
              onStatusChange: (s) =>
                  _updateStatus(context, ref, vehicles[i].id, s),
            ),
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
                onPressed: () => ref.invalidate(vehiclesListProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVehicleDialog(BuildContext context, WidgetRef ref,
      {VehicleModel? existing}) {
    showDialog(
      context: context,
      builder: (_) => _VehicleFormDialog(
        existing: existing,
        onSaved: () => ref.invalidate(vehiclesListProvider),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref,
      String vehicleId, String newStatus) async {
    try {
      final client = ref.read(supabaseClientProvider);
      await client
          .from('vehicles')
          .update({'status': newStatus}).eq('id', vehicleId);
      ref.invalidate(vehiclesListProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }
}

// ── Carte véhicule ─────────────────────────────────────────────────────────

class _VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final VoidCallback onEdit;
  final void Function(String) onStatusChange;

  const _VehicleCard({
    required this.vehicle,
    required this.onEdit,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (vehicle.status) {
      case 'available':
        statusColor = AppColors.success;
        break;
      case 'maintenance':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = AppColors.error;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.directions_car,
                  color: Colors.blue, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  Text(
                    vehicle.licensePlate,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.settings,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        vehicle.type == 'manual' ? 'Manuelle' : 'Automatique',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${vehicle.year}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  if (vehicle.nextMaintenanceDate != null)
                    Text(
                      'Maint.: ${vehicle.nextMaintenanceDate!.day}/${vehicle.nextMaintenanceDate!.month}/${vehicle.nextMaintenanceDate!.year}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.orange.shade700),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PopupMenuButton<String>(
                  onSelected: onStatusChange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _statusLabel(vehicle.status),
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down,
                            color: statusColor, size: 16),
                      ],
                    ),
                  ),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'available',
                        child: Text('Disponible')),
                    const PopupMenuItem(
                        value: 'maintenance',
                        child: Text('En maintenance')),
                    const PopupMenuItem(
                        value: 'occupied', child: Text('En cours')),
                  ],
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

  String _statusLabel(String s) {
    switch (s) {
      case 'available':
        return 'Disponible';
      case 'maintenance':
        return 'Maintenance';
      default:
        return 'En cours';
    }
  }
}

// ── Dialog formulaire véhicule ─────────────────────────────────────────────

class _VehicleFormDialog extends ConsumerStatefulWidget {
  final VehicleModel? existing;
  final VoidCallback onSaved;

  const _VehicleFormDialog({this.existing, required this.onSaved});

  @override
  ConsumerState<_VehicleFormDialog> createState() =>
      _VehicleFormDialogState();
}

class _VehicleFormDialogState extends ConsumerState<_VehicleFormDialog> {
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  String _type = 'manual';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final v = widget.existing!;
      _brandCtrl.text = v.brand;
      _modelCtrl.text = v.model;
      _plateCtrl.text = v.licensePlate;
      _yearCtrl.text = v.year.toString();
      _type = v.type;
    } else {
      _yearCtrl.text = DateTime.now().year.toString();
    }
  }

  @override
  void dispose() {
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _plateCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(
        isEdit ? 'Modifier le véhicule' : 'Nouveau véhicule',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _Field(
                    controller: _brandCtrl,
                    label: 'Marque',
                    icon: Icons.directions_car,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Field(
                    controller: _modelCtrl,
                    label: 'Modèle',
                    icon: Icons.car_rental,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    controller: _plateCtrl,
                    label: 'Plaque',
                    icon: Icons.pin,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Field(
                    controller: _yearCtrl,
                    label: 'Année',
                    icon: Icons.calendar_today,
                    keyboard: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Type de boîte
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Type de boîte',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.1),
                selectedForegroundColor: AppColors.primary,
              ),
              segments: const [
                ButtonSegment(value: 'manual', label: Text('Manuelle')),
                ButtonSegment(
                    value: 'automatic', label: Text('Automatique')),
              ],
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
              : Text(isEdit ? 'Modifier' : 'Ajouter',
                  style:
                      const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_brandCtrl.text.trim().isEmpty ||
        _modelCtrl.text.trim().isEmpty ||
        _plateCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Marque, modèle et plaque sont obligatoires')));
      return;
    }

    setState(() => _loading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final data = {
        'brand': _brandCtrl.text.trim(),
        'model': _modelCtrl.text.trim(),
        'license_plate': _plateCtrl.text.trim().toUpperCase(),
        'year': int.tryParse(_yearCtrl.text) ?? DateTime.now().year,
        'type': _type,
      };

      if (widget.existing != null) {
        await client
            .from('vehicles')
            .update(data)
            .eq('id', widget.existing!.id);
      } else {
        await client.from('vehicles').insert({
          ...data,
          'status': 'available',
        });
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existing != null
                ? 'Véhicule modifié avec succès'
                : 'Véhicule ajouté avec succès'),
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
