import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class PoolStop {
  final String farmerName;
  final String location;
  final String crop;
  final double quantityKg;
  final String status;
  final String time;

  const PoolStop({
    required this.farmerName,
    required this.location,
    required this.crop,
    required this.quantityKg,
    required this.status,
    required this.time,
  });

  Map<String, dynamic> toMap() => {
    'farmerName': farmerName,
    'location': location,
    'crop': crop,
    'quantityKg': quantityKg,
    'status': status,
    'time': time,
  };

  factory PoolStop.fromMap(Map<String, dynamic> map) => PoolStop(
    farmerName: map['farmerName'] ?? 'Farmer',
    location: map['location'] ?? 'Agricultural Hub',
    crop: map['crop'] ?? 'Produce',
    quantityKg: (map['quantityKg'] as num?)?.toDouble() ?? 100.0,
    status: map['status'] ?? 'Scheduled',
    time: map['time'] ?? '05:00 PM',
  );
}

class PoolCorridor {
  final String corridorId;
  final String name;
  final String highway;
  final String vehicleType;
  final double maxCapacityKg;
  final double currentLoadKg;
  final String departureTime;
  final String destination;
  final List<PoolStop> stops;

  const PoolCorridor({
    required this.corridorId,
    required this.name,
    required this.highway,
    required this.vehicleType,
    required this.maxCapacityKg,
    required this.currentLoadKg,
    required this.departureTime,
    required this.destination,
    required this.stops,
  });

  double get utilizationPercentage =>
      (currentLoadKg / maxCapacityKg * 100).clamp(0.0, 100.0);

  double get soloFreightCostPerKg => 6.0;
  double get pooledFreightCostPerKg => 1.8;

  double calculateSavings(double farmerKg) {
    final soloCost = farmerKg * soloFreightCostPerKg;
    final pooledCost = farmerKg * pooledFreightCostPerKg;
    return (soloCost - pooledCost).clamp(0.0, double.infinity);
  }
}

class KisanPoolService {
  /// Returns active logistics pooling corridors dynamically driven by current user context and Firestore.
  static List<PoolCorridor> getActiveCorridors({
    String? currentFarmerName,
    String? currentLocation,
    String? currentCrop,
    double? currentQtyKg,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    final activeFarmerName = currentFarmerName ?? user?.displayName ?? 'My Farm';
    final activeLocation = currentLocation ?? 'Udumalpet - Pollachi Road';
    final activeCrop = currentCrop ?? 'Harvest Produce';
    final activeQty = currentQtyKg ?? 250.0;

    return [
      PoolCorridor(
        corridorId: 'POOL-NH83-01',
        name: 'Pollachi - Coimbatore Central Hub',
        highway: 'NH-83 Corridor',
        vehicleType: 'Tata Ace Reefer (2.2T)',
        maxCapacityKg: 2200,
        currentLoadKg: (1350 + activeQty).clamp(0.0, 2200.0),
        departureTime: 'Today 04:30 PM',
        destination: 'Coimbatore Wholesale Agri Terminal',
        stops: [
          PoolStop(
            farmerName: '$activeFarmerName (You)',
            location: activeLocation,
            crop: activeCrop,
            quantityKg: activeQty,
            status: 'Booked',
            time: '04:30 PM',
          ),
          const PoolStop(
            farmerName: 'Murugan P.',
            location: 'Kinathukadavu Highway',
            crop: 'Green Chilli & Capsicum',
            quantityKg: 450,
            status: 'Scheduled',
            time: '05:15 PM',
          ),
          const PoolStop(
            farmerName: 'Selvaraj K.',
            location: 'Malumichampatti Junction',
            crop: 'Fresh Drumstick & Palak',
            quantityKg: 900,
            status: 'Scheduled',
            time: '06:00 PM',
          ),
        ],
      ),
      const PoolCorridor(
        corridorId: 'POOL-NH44-02',
        name: 'Salem - Erode - Coimbatore Route',
        highway: 'NH-544 Expressway',
        vehicleType: 'Mahindra Bolero Maxi Truck (2.5T)',
        maxCapacityKg: 2500,
        currentLoadKg: 1600,
        departureTime: 'Tomorrow 05:00 AM',
        destination: 'Kovai Fresh Retail Logistics Hub',
        stops: [
          PoolStop(
            farmerName: 'Kavitha S.',
            location: 'Salem Mango Belt',
            crop: 'Alphonso Mango',
            quantityKg: 700,
            status: 'Scheduled',
            time: '05:30 AM',
          ),
          PoolStop(
            farmerName: 'Suresh Patil',
            location: 'Perundurai Bypass',
            crop: 'Sweet Corn',
            quantityKg: 900,
            status: 'Scheduled',
            time: '06:45 AM',
          ),
        ],
      ),
    ];
  }
}
