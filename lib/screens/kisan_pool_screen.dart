import 'package:flutter/material.dart';
import '../services/kisan_pool_service.dart';

class KisanPoolScreen extends StatefulWidget {
  const KisanPoolScreen({super.key});

  @override
  State<KisanPoolScreen> createState() => _KisanPoolScreenState();
}

class _KisanPoolScreenState extends State<KisanPoolScreen> {
  static const Color background = Color(0xFF080A09);
  static const Color cardColor = Color(0xFF141715);
  static const Color primaryGreen = Color(0xFF00E676);
  static const Color darkGreen = Color(0xFF102819);
  static const Color borderColor = Color(0xFF223326);

  int _selectedCorridorIndex = 0;
  double _myHarvestWeight = 500.0;

  @override
  Widget build(BuildContext context) {
    final corridors = KisanPoolService.getActiveCorridors();
    final current = corridors[_selectedCorridorIndex];
    final savings = current.calculateSavings(_myHarvestWeight);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A150D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/images/kisan_logo.png',
              width: 32,
              height: 32,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.local_shipping_rounded,
                color: primaryGreen,
                size: 26,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KisanPool Shared Logistics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Consolidated Milk-Run & Freight Pooling',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route Corridor Tabs
            _buildCorridorSelector(corridors),

            const SizedBox(height: 20),

            // Vehicle Load Utilization Gauge Card
            _buildVehicleCapacityCard(current),

            const SizedBox(height: 20),

            // NRV Freight Savings Calculator
            _buildSavingsCalculator(current, savings),

            const SizedBox(height: 20),

            // Corridor Stops Timeline
            _buildStopsTimeline(current),

            const SizedBox(height: 24),

            // Join Pool Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.local_shipping_rounded),
                label: const Text(
                  'Book Slot on Next KisanPool Truck',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF13361E),
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: primaryGreen),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Slot booked on ${current.vehicleType}! Pickup scheduled for ${current.departureTime}.',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorridorSelector(List<PoolCorridor> corridors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(corridors.length, (idx) {
          final c = corridors[idx];
          final active = _selectedCorridorIndex == idx;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(c.name),
              selected: active,
              selectedColor: primaryGreen,
              backgroundColor: cardColor,
              labelStyle: TextStyle(
                color: active ? Colors.black : Colors.white70,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
              side: BorderSide(color: active ? primaryGreen : borderColor),
              onSelected: (_) => setState(() => _selectedCorridorIndex = idx),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildVehicleCapacityCard(PoolCorridor current) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: darkGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.airport_shuttle_rounded, color: primaryGreen, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            current.vehicleType,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(current.highway, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Departs: ${current.departureTime}',
                  style: const TextStyle(color: primaryGreen, fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Capacity Utilization', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text(
                '${current.currentLoadKg.toInt()} / ${current.maxCapacityKg.toInt()} kg (${current.utilizationPercentage.toStringAsFixed(0)}%)',
                style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: current.utilizationPercentage / 100,
              backgroundColor: const Color(0xFF222B24),
              color: primaryGreen,
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsCalculator(PoolCorridor current, double savings) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1D12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primaryGreen.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.savings_rounded, color: primaryGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'Net Realizable Value (NRV) Savings',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Your Crop Load:', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text('${_myHarvestWeight.toInt()} kg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _myHarvestWeight,
            min: 100,
            max: 1500,
            divisions: 14,
            activeColor: primaryGreen,
            inactiveColor: const Color(0xFF253B2B),
            onChanged: (val) => setState(() => _myHarvestWeight = val),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Solo Mini-Truck', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  Text('₹${(_myHarvestWeight * current.soloFreightCostPerKg).toInt()}', style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white38),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('KisanPool Shared', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  Text('₹${(_myHarvestWeight * current.pooledFreightCostPerKg).toInt()}', style: const TextStyle(color: primaryGreen, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Text('Saved', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text('+₹${savings.toInt()}', style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStopsTimeline(PoolCorridor current) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Corridor Stops & Milk-Run Waypoints',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 14),
          Column(
            children: current.stops.map((stop) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.radio_button_checked_rounded, color: primaryGreen, size: 16),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stop.location, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          Text('${stop.farmerName} • ${stop.crop} (${stop.quantityKg.toInt()} kg)', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text(stop.time, style: const TextStyle(color: primaryGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
