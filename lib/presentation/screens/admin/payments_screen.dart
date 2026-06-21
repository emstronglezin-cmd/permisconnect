import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/payment_provider.dart';
import '../../../presentation/providers/student_provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../data/models/payment_model.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(allPaymentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paiements'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(allPaymentsProvider.notifier).load(),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Tous'),
            Tab(text: 'Payés'),
            Tab(text: 'En attente'),
          ],
          onTap: (i) {
            final statuses = ['', 'completed', 'pending'];
            ref
                .read(allPaymentsProvider.notifier)
                .load(status: statuses[i]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPaymentDialog(context),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau paiement',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: paymentsAsync.when(
        data: (payments) {
          final totalPaid = payments
              .where((p) => p.isPaid)
              .fold<double>(0, (sum, p) => sum + p.amount);
          final totalPending = payments
              .where((p) => !p.isPaid)
              .fold<double>(0, (sum, p) => sum + p.amount);

          return Column(
            children: [
              // Résumé
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryItem(
                        label: 'Encaissé',
                        value: '${totalPaid.toStringAsFixed(0)} XOF',
                        color: AppColors.success,
                        icon: Icons.account_balance_wallet,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryItem(
                        label: 'En attente',
                        value: '${totalPending.toStringAsFixed(0)} XOF',
                        color: Colors.orange,
                        icon: Icons.pending,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryItem(
                        label: 'Total',
                        value: '${payments.length}',
                        color: AppColors.primary,
                        icon: Icons.receipt_long,
                      ),
                    ),
                  ],
                ),
              ),

              // Liste
              Expanded(
                child: payments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payments_outlined,
                                size: 56, color: Colors.grey.shade200),
                            const SizedBox(height: 12),
                            const Text('Aucun paiement',
                                style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(12, 8, 12, 100),
                        itemCount: payments.length,
                        itemBuilder: (_, i) => _PaymentCard(
                          payment: payments[i],
                          onValidate: payments[i].isPaid
                              ? null
                              : () => _validatePayment(
                                  context, payments[i]),
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
              ElevatedButton(
                onPressed: () =>
                    ref.read(allPaymentsProvider.notifier).load(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _validatePayment(
      BuildContext context, PaymentModel payment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Valider ce paiement ?'),
        content: Text(
            'Confirmer le paiement de ${payment.formattedAmount} pour ${payment.studentName ?? "cet élève"} ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Non')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white),
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final client = ref.read(supabaseClientProvider);
        await client
            .from('payments')
            .update({'status': 'completed', 'paid_at': DateTime.now().toIso8601String()}).eq(
                'id', payment.id);
        ref.read(allPaymentsProvider.notifier).load();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paiement validé !'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : $e')),
          );
        }
      }
    }
  }

  void _showAddPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _AddPaymentDialog(
        onSaved: () => ref.read(allPaymentsProvider.notifier).load(),
      ),
    );
  }
}

// ── Carte paiement ─────────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  final PaymentModel payment;
  final VoidCallback? onValidate;

  const _PaymentCard({required this.payment, this.onValidate});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (payment.status) {
      case 'completed':
        statusColor = AppColors.success;
        break;
      case 'failed':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = Colors.orange;
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
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                payment.isPaid ? Icons.check_circle : Icons.pending,
                color: statusColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.studentName ?? 'Élève',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${payment.createdAt.day}/${payment.createdAt.month}/${payment.createdAt.year}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                  if (payment.formula != null)
                    Text(
                      'Formule: ${payment.formula}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  Row(
                    children: [
                      const Icon(Icons.phone_android,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        payment.method,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  payment.formattedAmount,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      fontSize: 15),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    payment.statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                if (onValidate != null) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onValidate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Valider',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dialog ajouter paiement ────────────────────────────────────────────────

class _AddPaymentDialog extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const _AddPaymentDialog({required this.onSaved});

  @override
  ConsumerState<_AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends ConsumerState<_AddPaymentDialog> {
  final _amountCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _selectedStudentId;
  String _method = 'cash';
  String _formula = 'permis_b';
  bool _loading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsListProvider);

    return AlertDialog(
      title: const Text('Nouveau paiement',
          style: TextStyle(fontWeight: FontWeight.w700)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Élève
            studentsAsync.when(
              data: (students) => DropdownButtonFormField<String>(
                initialValue: _selectedStudentId,
                hint: const Text('Sélectionner un élève'),
                decoration: InputDecoration(
                  labelText: 'Élève',
                  prefixIcon: const Icon(Icons.school, size: 18),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
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
              loading: () => const LinearProgressIndicator(),
              error: (_, __) =>
                  const Text('Impossible de charger les élèves'),
            ),
            const SizedBox(height: 12),

            // Montant
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Montant (XOF)',
                prefixIcon:
                    const Icon(Icons.payments, size: 18),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Formule
            DropdownButtonFormField<String>(
              initialValue: _formula,
              decoration: InputDecoration(
                labelText: 'Formule',
                prefixIcon: const Icon(Icons.description, size: 18),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'permis_b', child: Text('Permis B')),
                DropdownMenuItem(
                    value: 'code_seul', child: Text('Code seul')),
                DropdownMenuItem(
                    value: 'acompte', child: Text('Acompte')),
                DropdownMenuItem(
                    value: 'solde', child: Text('Solde')),
              ],
              onChanged: (v) =>
                  setState(() => _formula = v ?? 'permis_b'),
            ),
            const SizedBox(height: 12),

            // Méthode
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: InputDecoration(
                labelText: 'Mode de paiement',
                prefixIcon: const Icon(Icons.phone_android, size: 18),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Espèces')),
                DropdownMenuItem(
                    value: 'orange_money',
                    child: Text('Orange Money')),
                DropdownMenuItem(
                    value: 'moov_money', child: Text('Moov Money')),
                DropdownMenuItem(
                    value: 'wave', child: Text('Wave')),
              ],
              onChanged: (v) =>
                  setState(() => _method = v ?? 'cash'),
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
            backgroundColor: AppColors.success,
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
              : const Text('Enregistrer',
                  style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner un élève')));
      return;
    }
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Montant invalide')));
      return;
    }

    setState(() => _loading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('payments').insert({
        'student_id': _selectedStudentId,
        'amount': amount,
        'method': _method,
        'formula': _formula,
        'status': 'completed',
        'created_at': DateTime.now().toIso8601String(),
        'paid_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paiement enregistré avec succès'),
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

// ── Widgets helpers ────────────────────────────────────────────────────────

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 13),
          ),
          Text(
            label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
