import 'package:flutter/material.dart';

class InstructorsScreen extends StatelessWidget {
  const InstructorsScreen({super.key});

  final List<Map<String, dynamic>> _instructors = const [
    {'id': '1', 'name': 'M. Ouédraogo Pascal', 'phone': '+226 70 11 22 33', 'license': 'B, C', 'lessons': 142, 'rating': 4.8, 'status': 'AVAILABLE', 'avatar': 'OP'},
    {'id': '2', 'name': 'Mme Kaboré Aïcha', 'phone': '+226 65 44 55 66', 'license': 'B', 'lessons': 98, 'rating': 4.6, 'status': 'BUSY', 'avatar': 'KA'},
    {'id': '3', 'name': 'M. Traoré Ibrahim', 'phone': '+226 78 77 66 55', 'license': 'B, D', 'lessons': 205, 'rating': 4.9, 'status': 'AVAILABLE', 'avatar': 'TI'},
    {'id': '4', 'name': 'Mme Sawadogo Roukya', 'phone': '+226 62 33 22 11', 'license': 'B', 'lessons': 76, 'rating': 4.4, 'status': 'OFF', 'avatar': 'SR'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E65C5),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Gestion des Moniteurs',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _instructors.length + 1,
        itemBuilder: (context, i) {
          if (i == _instructors.length) return const SizedBox(height: 80);
          final inst = _instructors[i];
          final status = inst['status'] as String;
          Color statusColor;
          String statusLabel;
          switch (status) {
            case 'AVAILABLE': statusColor = const Color(0xFF27AE60); statusLabel = 'Disponible'; break;
            case 'BUSY': statusColor = const Color(0xFFF39C12); statusLabel = 'Occupé'; break;
            default: statusColor = const Color(0xFF9CA3AF); statusLabel = 'Congé';
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
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
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E65C5).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(inst['avatar'] as String,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E65C5))),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(inst['name'] as String,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF6B7280)),
                          const SizedBox(width: 4),
                          Text(inst['phone'] as String,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, size: 13, color: const Color(0xFFF39C12)),
                          const SizedBox(width: 3),
                          Text('${inst['rating']}',
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A2E))),
                          const SizedBox(width: 10),
                          Text('Permis ${inst['license']}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                          const SizedBox(width: 10),
                          Text('${inst['lessons']} cours',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(statusLabel,
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E65C5).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.edit_rounded,
                                color: Color(0xFF1E65C5), size: 14),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE74C3C).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                color: Color(0xFFE74C3C), size: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
