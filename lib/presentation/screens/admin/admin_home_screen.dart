import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1E65C5),
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Tableau de Bord',
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                                Text('Administration - PermisConnect',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withValues(alpha: 0.75))),
                              ],
                            ),
                            Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.admin_panel_settings_rounded,
                                  color: Colors.white, size: 22),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Indicateurs rapides
                        Row(
                          children: [
                            _buildQuickBadge(Icons.circle, '3', 'Alertes', const Color(0xFFE74C3C)),
                            const SizedBox(width: 12),
                            _buildQuickBadge(Icons.payment_rounded, '8', 'Paiements en attente', const Color(0xFFF39C12)),
                            const SizedBox(width: 12),
                            _buildQuickBadge(Icons.event_available_rounded, '5', 'Cours aujourd\'hui', const Color(0xFF27AE60)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // KPIs principaux
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildKPICard('48', 'Élèves inscrits', Icons.school_rounded,
                        const Color(0xFF1E65C5), '+3 ce mois'),
                    _buildKPICard('8', 'Moniteurs actifs', Icons.badge_rounded,
                        const Color(0xFF27AE60), '2 disponibles'),
                    _buildKPICard('156h', 'Heures programmées', Icons.access_time_rounded,
                        const Color(0xFFFF7F27), 'ce mois'),
                    _buildKPICard('2,4M F', 'Paiements reçus', Icons.payments_rounded,
                        const Color(0xFF9B59B6), 'ce mois'),
                  ],
                ),
                const SizedBox(height: 24),

                // Restes à payer
                _buildPaymentSummary(),
                const SizedBox(height: 24),

                // Accès rapides
                const Text('Actions rapides',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 14),

                GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildQuickAction(context, Icons.person_add_rounded, 'Ajouter élève', const Color(0xFF1E65C5), '/admin/students'),
                    _buildQuickAction(context, Icons.event_rounded, 'Planifier cours', const Color(0xFF27AE60), '/admin/planning'),
                    _buildQuickAction(context, Icons.receipt_long_rounded, 'Enregistrer paiement', const Color(0xFFFF7F27), '/admin/payments'),
                    _buildQuickAction(context, Icons.directions_car_rounded, 'Gérer véhicules', const Color(0xFF9B59B6), '/admin/vehicles'),
                    _buildQuickAction(context, Icons.bar_chart_rounded, 'Rapports', const Color(0xFF3498DB), '/admin/home'),
                    _buildQuickAction(context, Icons.settings_rounded, 'Paramètres', const Color(0xFF6B7280), '/admin/home'),
                  ],
                ),
                const SizedBox(height: 24),

                // Activité récente
                const Text('Activité récente',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 14),

                _buildActivityItem(Icons.person_add_rounded, 'Nouvel élève inscrit',
                    'Fatou Coulibaly - Formule Premium', 'il y a 2h', const Color(0xFF1E65C5)),
                _buildActivityItem(Icons.payments_rounded, 'Paiement reçu',
                    'Seydou Diallo - 50 000 F CFA', 'il y a 4h', const Color(0xFF27AE60)),
                _buildActivityItem(Icons.event_rounded, 'Cours planifié',
                    'Conduite - M. Ouédraogo', 'il y a 5h', const Color(0xFFFF7F27)),
                _buildActivityItem(Icons.check_circle_rounded, 'Compétence validée',
                    'Manœuvres - Issa Kouamé', 'hier', const Color(0xFF9B59B6)),

                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickBadge(IconData icon, String count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(
                child: Text(count,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  maxLines: 2,
                  style: const TextStyle(
                      fontSize: 10, color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICard(String value, String label, IconData icon, Color color, String sub) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 16, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A2E))),
          Text(sub,
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1450A0), Color(0xFF1E65C5)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E65C5).withValues(alpha: 0.3),
            blurRadius: 16, offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Finances du Mois',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildFinanceStat('2 400 000', 'Reçu', const Color(0xFF27AE60)),
              _buildFinanceDivider(),
              _buildFinanceStat('620 000', 'En attente', const Color(0xFFF39C12)),
              _buildFinanceDivider(),
              _buildFinanceStat('3 020 000', 'Total dû', Colors.white),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 2400000 / 3020000,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF27AE60)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text('79% des paiements reçus',
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.75))),
        ],
      ),
    );
  }

  Widget _buildFinanceStat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text('$value F',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color)),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  Widget _buildFinanceDivider() {
    return Container(
      width: 1, height: 30,
      color: Colors.white.withValues(alpha: 0.2),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, Color color, String route) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 10, offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A2E))),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(IconData icon, String title, String subtitle, String time, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E))),
                Text(subtitle,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Text(time,
              style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}
