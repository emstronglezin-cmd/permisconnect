import 'package:flutter/material.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  final List<Map<String, dynamic>> _vehicles = const [
    {'id': '1', 'plate': 'AB 1234 BF', 'brand': 'Toyota', 'model': 'Corolla', 'year': 2020, 'color': 'Blanc', 'type': 'Berline', 'status': 'AVAILABLE', 'mileage': 45200},
    {'id': '2', 'plate': 'CD 5678 BF', 'brand': 'Peugeot', 'model': '308', 'year': 2021, 'color': 'Gris', 'type': 'Berline', 'status': 'IN_USE', 'mileage': 32100},
    {'id': '3', 'plate': 'EF 9012 BF', 'brand': 'Renault', 'model': 'Clio', 'year': 2019, 'color': 'Rouge', 'type': 'Citadine', 'status': 'MAINTENANCE', 'mileage': 68500},
    {'id': '4', 'plate': 'GH 3456 BF', 'brand': 'Toyota', 'model': 'Yaris', 'year': 2022, 'color': 'Bleu', 'type': 'Citadine', 'status': 'AVAILABLE', 'mileage': 12400},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E65C5),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Gestion des Véhicules',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _vehicles.length + 1,
        itemBuilder: (context, i) {
          if (i == _vehicles.length) return const SizedBox(height: 80);
          final vehicle = _vehicles[i];
          final status = vehicle['status'] as String;
          Color statusColor;
          String statusLabel;
          IconData statusIcon;
          switch (status) {
            case 'AVAILABLE':
              statusColor = const Color(0xFF27AE60);
              statusLabel = 'Disponible';
              statusIcon = Icons.check_circle_rounded;
              break;
            case 'IN_USE':
              statusColor = const Color(0xFF1E65C5);
              statusLabel = 'En cours';
              statusIcon = Icons.directions_car_rounded;
              break;
            default:
              statusColor = const Color(0xFFF39C12);
              statusLabel = 'En maintenance';
              statusIcon = Icons.build_rounded;
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
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.directions_car_rounded, color: statusColor, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${vehicle['brand']} ${vehicle['model']}',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 2),
                      Text('${vehicle['plate']} • ${vehicle['year']} • ${vehicle['color']}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.speed_rounded, size: 12, color: Color(0xFF9CA3AF)),
                          const SizedBox(width: 4),
                          Text('${(vehicle['mileage'] as int).toString().replaceAllMapped(
                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                            (m) => '${m[1]} ',
                          )} km',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(statusLabel,
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(vehicle['type'] as String,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
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
