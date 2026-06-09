import 'package:flutter/material.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  String _selectedFilter = 'all';

  final List<Map<String, dynamic>> _payments = [
    {'id': '1', 'student': 'Kouamé Issa', 'amount': 50000, 'method': 'ORANGE_MONEY', 'status': 'VALIDATED', 'date': '15 Jan 2024', 'ref': 'OM-001234'},
    {'id': '2', 'student': 'Fatou Coulibaly', 'amount': 90000, 'method': 'CASH', 'status': 'VALIDATED', 'date': '16 Jan 2024', 'ref': 'CASH-0056'},
    {'id': '3', 'student': 'Bintou Kaboré', 'amount': 85000, 'method': 'MOOV_MONEY', 'status': 'PENDING', 'date': '17 Jan 2024', 'ref': 'MM-789012'},
    {'id': '4', 'student': 'Aïssatou Traoré', 'amount': 30000, 'method': 'CASH', 'status': 'VALIDATED', 'date': '18 Jan 2024', 'ref': 'CASH-0057'},
    {'id': '5', 'student': 'Seydou Diallo', 'amount': 42500, 'method': 'ORANGE_MONEY', 'status': 'PENDING', 'date': '19 Jan 2024', 'ref': 'OM-001235'},
    {'id': '6', 'student': 'Mamadou Sow', 'amount': 25000, 'method': 'CASH', 'status': 'FAILED', 'date': '20 Jan 2024', 'ref': 'CASH-0058'},
  ];

  List<Map<String, dynamic>> get _filteredPayments {
    if (_selectedFilter == 'all') return _payments;
    return _payments.where((p) => p['status'] == _selectedFilter).toList();
  }

  double get _totalValidated {
    return _payments
        .where((p) => p['status'] == 'VALIDATED')
        .fold(0, (sum, p) => sum + (p['amount'] as int));
  }

  double get _totalPending {
    return _payments
        .where((p) => p['status'] == 'PENDING')
        .fold(0, (sum, p) => sum + (p['amount'] as int));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Paiements',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                            GestureDetector(
                              onTap: () => _showAddPaymentDialog(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF7F27),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.add_rounded, color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text('Enregistrer',
                                        style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _buildFinanceStat(
                                '${(_totalValidated / 1000).toStringAsFixed(0)}K F',
                                'Reçu',
                                const Color(0xFF27AE60)),
                            _buildDivider(),
                            _buildFinanceStat(
                                '${(_totalPending / 1000).toStringAsFixed(0)}K F',
                                'En attente',
                                const Color(0xFFF39C12)),
                            _buildDivider(),
                            _buildFinanceStat(
                                '${_payments.length}',
                                'Transactions',
                                Colors.white),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Container(
                color: const Color(0xFF1E65C5),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'Tous'),
                      _buildFilterChip('VALIDATED', 'Validés'),
                      _buildFilterChip('PENDING', 'En attente'),
                      _buildFilterChip('FAILED', 'Échoués'),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  if (i == _filteredPayments.length) return const SizedBox(height: 80);
                  return _buildPaymentCard(_filteredPayments[i]);
                },
                childCount: _filteredPayments.length + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceStat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color)),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1, height: 30,
      color: Colors.white.withValues(alpha: 0.2),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF7F27) : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final status = payment['status'] as String;
    final method = payment['method'] as String;
    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (status) {
      case 'VALIDATED':
        statusColor = const Color(0xFF27AE60);
        statusLabel = 'Validé';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'PENDING':
        statusColor = const Color(0xFFF39C12);
        statusLabel = 'En attente';
        statusIcon = Icons.access_time_rounded;
        break;
      default:
        statusColor = const Color(0xFFE74C3C);
        statusLabel = 'Échoué';
        statusIcon = Icons.cancel_rounded;
    }

    IconData methodIcon;
    String methodLabel;
    Color methodColor;
    switch (method) {
      case 'ORANGE_MONEY':
        methodIcon = Icons.phone_android_rounded;
        methodLabel = 'Orange Money';
        methodColor = const Color(0xFFFF7F27);
        break;
      case 'MOOV_MONEY':
        methodIcon = Icons.phone_android_rounded;
        methodLabel = 'Moov Money';
        methodColor = const Color(0xFF3498DB);
        break;
      default:
        methodIcon = Icons.payments_rounded;
        methodLabel = 'Espèces';
        methodColor = const Color(0xFF27AE60);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: methodColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(methodIcon, color: methodColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment['student'] as String,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(methodLabel,
                        style: TextStyle(fontSize: 11, color: methodColor)),
                    const Text(' • ',
                        style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                    Text(payment['date'] as String,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                  ],
                ),
                Text('Réf: ${payment['ref']}',
                    style: const TextStyle(fontSize: 10, color: Color(0xFFBDBDBD))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${payment['amount']} F',
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 12),
                  const SizedBox(width: 3),
                  Text(statusLabel,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddPaymentDialog(BuildContext context) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Enregistrer un paiement',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            // Modes de paiement
            const Text('Mode de paiement',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280))),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildPaymentMethodBtn(Icons.payments_rounded, 'Espèces', const Color(0xFF27AE60)),
                const SizedBox(width: 8),
                _buildPaymentMethodBtn(Icons.phone_android_rounded, 'Orange Money', const Color(0xFFFF7F27)),
                const SizedBox(width: 8),
                _buildPaymentMethodBtn(Icons.phone_android_rounded, 'Moov Money', const Color(0xFF3498DB)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7F27),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text('Valider le paiement',
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

  Widget _buildPaymentMethodBtn(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }
}
