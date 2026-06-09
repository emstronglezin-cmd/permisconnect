import 'package:flutter/material.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'all';

  final List<Map<String, dynamic>> _students = [
    {'id': '1', 'name': 'Kouamé Issa', 'phone': '+226 70 12 34 56', 'formula': 'Standard', 'hours': 22, 'totalHours': 30, 'paid': 81500, 'total': 120000, 'status': 'ACTIVE', 'avatar': 'KI'},
    {'id': '2', 'name': 'Fatou Coulibaly', 'phone': '+226 65 98 76 54', 'formula': 'Premium', 'hours': 15, 'totalHours': 45, 'paid': 90000, 'total': 180000, 'status': 'ACTIVE', 'avatar': 'FC'},
    {'id': '3', 'name': 'Seydou Diallo', 'phone': '+226 78 45 23 10', 'formula': 'Basique', 'hours': 20, 'totalHours': 20, 'paid': 85000, 'total': 85000, 'status': 'COMPLETED', 'avatar': 'SD'},
    {'id': '4', 'name': 'Aïssatou Traoré', 'phone': '+226 62 33 44 55', 'formula': 'Standard', 'hours': 8, 'totalHours': 30, 'paid': 60000, 'total': 120000, 'status': 'ACTIVE', 'avatar': 'AT'},
    {'id': '5', 'name': 'Mamadou Sow', 'phone': '+226 70 99 88 77', 'formula': 'Premium', 'hours': 0, 'totalHours': 45, 'paid': 0, 'total': 180000, 'status': 'SUSPENDED', 'avatar': 'MS'},
    {'id': '6', 'name': 'Bintou Kaboré', 'phone': '+226 75 11 22 33', 'formula': 'Basique', 'hours': 12, 'totalHours': 20, 'paid': 85000, 'total': 85000, 'status': 'ACTIVE', 'avatar': 'BK'},
  ];

  List<Map<String, dynamic>> get _filteredStudents {
    return _students.where((s) {
      final matchSearch = _searchQuery.isEmpty ||
          (s['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (s['phone'] as String).contains(_searchQuery);
      final matchFilter = _filterStatus == 'all' || s['status'] == _filterStatus;
      return matchSearch && matchFilter;
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF1E65C5),
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text('Gestion des Élèves',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Colors.white)),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_rounded, color: Colors.white),
                onPressed: () => _showAddStudentDialog(context),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(110),
              child: Container(
                color: const Color(0xFF1E65C5),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    // Barre de recherche
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Rechercher un élève...',
                          hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF6B7280), size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Filtres
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilter('all', 'Tous (${_students.length})'),
                          _buildFilter('ACTIVE', 'Actifs'),
                          _buildFilter('COMPLETED', 'Terminés'),
                          _buildFilter('SUSPENDED', 'Suspendus'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  if (i == _filteredStudents.length) return const SizedBox(height: 80);
                  return _buildStudentCard(_filteredStudents[i]);
                },
                childCount: _filteredStudents.length + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter(String value, String label) {
    final isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF7F27) : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF7F27) : Colors.white.withValues(alpha: 0.4),
          ),
        ),
        child: Text(label,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.white)),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final status = student['status'] as String;
    final hours = student['hours'] as int;
    final totalHours = student['totalHours'] as int;
    final paid = student['paid'] as int;
    final total = student['total'] as int;
    final progress = totalHours > 0 ? hours / totalHours : 0.0;
    final paymentProgress = total > 0 ? paid / total : 0.0;

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'ACTIVE': statusColor = const Color(0xFF27AE60); statusLabel = 'Actif'; break;
      case 'COMPLETED': statusColor = const Color(0xFF1E65C5); statusLabel = 'Terminé'; break;
      case 'SUSPENDED': statusColor = const Color(0xFFE74C3C); statusLabel = 'Suspendu'; break;
      default: statusColor = const Color(0xFF9CA3AF); statusLabel = status;
    }

    final avatarColors = [
      const Color(0xFF1E65C5), const Color(0xFFFF7F27), const Color(0xFF27AE60),
      const Color(0xFF9B59B6), const Color(0xFFE74C3C), const Color(0xFF3498DB),
    ];
    final avatarColor = avatarColors[int.parse(student['id'] as String) % avatarColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: avatarColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(student['avatar'] as String,
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: avatarColor)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student['name'] as String,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E))),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF6B7280)),
                          const SizedBox(width: 4),
                          Text(student['phone'] as String,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(statusLabel,
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor)),
                    ),
                    const SizedBox(height: 4),
                    Text(student['formula'] as String,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Heures',
                              style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                          Text('$hours/$totalHours h',
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A2E))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E65C5)),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Paiement',
                              style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                          Text('${(paymentProgress * 100).toInt()}%',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: paymentProgress >= 1.0
                                      ? const Color(0xFF27AE60)
                                      : const Color(0xFFF39C12))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: paymentProgress,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            paymentProgress >= 1.0 ? const Color(0xFF27AE60) : const Color(0xFFF39C12),
                          ),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionBtn(Icons.edit_rounded, const Color(0xFF1E65C5), () {}),
                const SizedBox(width: 8),
                _buildActionBtn(Icons.payments_rounded, const Color(0xFF27AE60), () {}),
                const SizedBox(width: 8),
                _buildActionBtn(Icons.more_vert_rounded, const Color(0xFF9CA3AF), () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  void _showAddStudentDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
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
              const Text('Ajouter un élève',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              _buildInput('Nom complet', Icons.person_outlined),
              const SizedBox(height: 12),
              _buildInput('Téléphone', Icons.phone_outlined),
              const SizedBox(height: 12),
              _buildInput('Email', Icons.email_outlined),
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
                  child: const Text('Enregistrer',
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }
}
