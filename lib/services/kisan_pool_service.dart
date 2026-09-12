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
  static List<PoolCorridor> getActiveCorridors() {
    return [
      PoolCorridor(
        corridorId: 'POOL-NH83-01',
        name: 'Pollachi - Coimbatore Central Hub',
        highway: 'NH-83 Corridor',
        vehicleType: 'Tata Ace Reefer (2.2T)',
        maxCapacityKg: 2200,
        currentLoadKg: 1850,
        departureTime: 'Today 04:30 PM',
        destination: 'Coimbatore Wholesale Agri Terminal',
        stops: [
          PoolStop(
            farmerName: 'harish (You)',
            location: 'Pollachi Agro Belt',
            crop: 'Organic Tomato',
            quantityKg: 500,
            status: 'Booked',
            time: '04:30 PM',
          ),
          PoolStop(
            farmerName: 'Murugan P.',
            location: 'Kinathukadavu Highway',
            crop: 'Green Chilli & Capsicum',
            quantityKg: 450,
            status: 'Scheduled',
            time: '05:15 PM',
          ),
          PoolStop(
            farmerName: 'Selvaraj K.',
            location: 'Malumichampatti Junction',
            crop: 'Fresh Drumstick & Palak',
            quantityKg: 900,
            status: 'Scheduled',
            time: '06:00 PM',
          ),
        ],
      ),
      PoolCorridor(
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
