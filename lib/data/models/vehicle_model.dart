class VehicleModel {
  final String id;
  final String brand;
  final String model;
  final String licensePlate;
  final int year;
  final String type;
  final String status;
  final DateTime? lastMaintenanceDate;
  final DateTime? nextMaintenanceDate;
  final String? photoUrl;
  final DateTime createdAt;

  const VehicleModel({
    required this.id,
    required this.brand,
    required this.model,
    required this.licensePlate,
    required this.year,
    this.type = 'manual',
    this.status = 'available',
    this.lastMaintenanceDate,
    this.nextMaintenanceDate,
    this.photoUrl,
    required this.createdAt,
  });

  bool get isAvailable => status == 'available';
  String get fullName => '$brand $model ($year)';

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      licensePlate: json['license_plate'] as String? ?? '',
      year: json['year'] as int? ?? DateTime.now().year,
      type: json['type'] as String? ?? 'manual',
      status: json['status'] as String? ?? 'available',
      lastMaintenanceDate: json['last_maintenance_date'] != null
          ? DateTime.parse(json['last_maintenance_date'] as String)
          : null,
      nextMaintenanceDate: json['next_maintenance_date'] != null
          ? DateTime.parse(json['next_maintenance_date'] as String)
          : null,
      photoUrl: json['photo_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand': brand,
      'model': model,
      'license_plate': licensePlate,
      'year': year,
      'type': type,
      'status': status,
      'last_maintenance_date': lastMaintenanceDate?.toIso8601String(),
      'next_maintenance_date': nextMaintenanceDate?.toIso8601String(),
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
