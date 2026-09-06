import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LiveMapWidget extends StatefulWidget {
  final LatLng? partnerLocation;
  final LatLng? farmerLocation;
  final LatLng? buyerLocation;
  final String? farmerName;
  final String? buyerName;
  final double? heading;
  final bool showPolyline;
  final double height;
  final double initialZoom;
  final bool isInteractive;

  const LiveMapWidget({
    super.key,
    this.partnerLocation,
    this.farmerLocation,
    this.buyerLocation,
    this.farmerName,
    this.buyerName,
    this.heading,
    this.showPolyline = true,
    this.height = 260,
    this.initialZoom = 14.0,
    this.isInteractive = true,
  });

  @override
  State<LiveMapWidget> createState() => _LiveMapWidgetState();
}

class _LiveMapWidgetState extends State<LiveMapWidget> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(covariant LiveMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.partnerLocation != null &&
        oldWidget.partnerLocation != widget.partnerLocation) {
      // Smoothly pan to new partner location if updated
      try {
        _mapController.move(widget.partnerLocation!, _mapController.camera.zoom);
      } catch (_) {}
    }
  }

  LatLng _getCenter() {
    if (widget.partnerLocation != null) return widget.partnerLocation!;
    if (widget.farmerLocation != null) return widget.farmerLocation!;
    if (widget.buyerLocation != null) return widget.buyerLocation!;
    // Default to Tamil Nadu coordinates (Vidhai core region)
    return const LatLng(11.0168, 76.9558);
  }

  @override
  Widget build(BuildContext context) {
    final center = _getCenter();

    // Construct route points
    final List<LatLng> routePoints = [];
    if (widget.farmerLocation != null) routePoints.add(widget.farmerLocation!);
    if (widget.partnerLocation != null) routePoints.add(widget.partnerLocation!);
    if (widget.buyerLocation != null) routePoints.add(widget.buyerLocation!);

    final List<Marker> markers = [];

    // 1. Farmer Marker
    if (widget.farmerLocation != null) {
      markers.add(
        Marker(
          point: widget.farmerLocation!,
          width: 70,
          height: 70,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E241E),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.greenAccent, width: 1),
                ),
                child: Text(
                  widget.farmerName ?? 'Farm',
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.location_pin,
                color: Color(0xFFFFC107),
                size: 32,
              ),
            ],
          ),
        ),
      );
    }

    // 2. Buyer Marker
    if (widget.buyerLocation != null) {
      markers.add(
        Marker(
          point: widget.buyerLocation!,
          width: 70,
          height: 70,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E241E),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.redAccent, width: 1),
                ),
                child: Text(
                  widget.buyerName ?? 'Buyer',
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.home_rounded,
                color: Color(0xFFFF5252),
                size: 28,
              ),
            ],
          ),
        ),
      );
    }

    // 3. Moving Partner / Vehicle Marker
    if (widget.partnerLocation != null) {
      markers.add(
        Marker(
          point: widget.partnerLocation!,
          width: 48,
          height: 48,
          child: Transform.rotate(
            angle: (widget.heading ?? 0) * (3.1415926535 / 180),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFC107).withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 3,
                  ),
                ],
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: const Icon(
                Icons.electric_moped_rounded,
                color: Colors.black,
                size: 26,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF121614),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: widget.initialZoom,
              interactionOptions: InteractionOptions(
                flags: widget.isInteractive
                    ? InteractiveFlag.all
                    : InteractiveFlag.none,
              ),
            ),
            children: [
              // High contrast dark tile layer (CartoDB Dark Matter)
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.vidhai.sem7_project',
              ),

              // Connecting Route Polyline
              if (widget.showPolyline && routePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 3.5,
                      color: const Color(0xFFFFC107),
                    ),
                  ],
                ),

              // Markers
              MarkerLayer(markers: markers),
            ],
          ),

          // Recenter Button
          if (widget.isInteractive)
            Positioned(
              right: 12,
              bottom: 12,
              child: GestureDetector(
                onTap: () {
                  _mapController.move(_getCenter(), widget.initialZoom);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E241E),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: Color(0xFFFFC107),
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
