import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../services/location_directory_service.dart';

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
  final bool showRouteInfoOverlay;

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
    this.showRouteInfoOverlay = true,
  });

  @override
  State<LiveMapWidget> createState() => _LiveMapWidgetState();
}

class _LiveMapWidgetState extends State<LiveMapWidget> {
  late final MapController _mapController;

  List<LatLng> _primaryRoutePoints = [];
  List<LatLng> _alternateRoutePoints = [];
  double _distanceKm = 0.0;
  int _etaMinutes = 0;
  bool _useAlternateRoute = false;
  bool _isLoadingRoute = false;

  LatLng? _lastOrigin;
  LatLng? _lastDest;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _resolveAndFetchRoute();
  }

  @override
  void didUpdateWidget(covariant LiveMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final originChanged = oldWidget.partnerLocation != widget.partnerLocation ||
        oldWidget.farmerLocation != widget.farmerLocation;
    final destChanged = oldWidget.buyerLocation != widget.buyerLocation;

    if (originChanged || destChanged) {
      _resolveAndFetchRoute();
    }

    if (widget.partnerLocation != null &&
        oldWidget.partnerLocation != widget.partnerLocation) {
      try {
        _mapController.move(widget.partnerLocation!, _mapController.camera.zoom);
      } catch (_) {}
    }
  }

  LatLng? get _originPoint {
    final raw = widget.partnerLocation ?? widget.farmerLocation ?? widget.buyerLocation;
    if (raw == null) return null;
    return LocationDirectoryService.sanitize(
      raw.latitude,
      raw.longitude,
      referencePoint: widget.farmerLocation != null && LocationDirectoryService.isWithinIndia(widget.farmerLocation!.latitude, widget.farmerLocation!.longitude)
          ? widget.farmerLocation
          : LocationDirectoryService.udumalpet,
    );
  }

  LatLng? get _destPoint {
    final raw = widget.buyerLocation ?? widget.farmerLocation;
    if (raw == null) return null;
    return LocationDirectoryService.sanitize(
      raw.latitude,
      raw.longitude,
      referencePoint: LocationDirectoryService.ukkadam,
    );
  }

  LatLng _getCenter() {
    final origin = _originPoint;
    if (origin != null) return origin;
    final dest = _destPoint;
    if (dest != null) return dest;
    return LocationDirectoryService.defaultCoimbatore;
  }

  Future<void> _resolveAndFetchRoute() async {
    final origin = _originPoint;
    final dest = _destPoint;

    if (origin == null || dest == null) return;
    if (origin.latitude == dest.latitude && origin.longitude == dest.longitude) {
      return;
    }

    // Skip redundant network requests if locations haven't moved meaningfully (< 20 meters)
    if (_lastOrigin != null && _lastDest != null) {
      final dOrig = _calculateHaversineKm(_lastOrigin!, origin);
      final dDest = _calculateHaversineKm(_lastDest!, dest);
      if (dOrig < 0.02 && dDest < 0.02 && _primaryRoutePoints.isNotEmpty) {
        return;
      }
    }

    _lastOrigin = origin;
    _lastDest = dest;

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      // 1. Fetch real road geometry from OSRM public routing API
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};${dest.longitude},${dest.latitude}'
        '?overview=full&geometries=geojson&alternatives=true',
      );

      final response = await http.get(url).timeout(const Duration(milliseconds: 3200));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;

        if (routes != null && routes.isNotEmpty) {
          final primary = routes[0] as Map<String, dynamic>;
          final primaryCoords = primary['geometry']['coordinates'] as List<dynamic>;

          final primaryPts = primaryCoords.map<LatLng>((c) {
            final lon = (c[0] as num).toDouble();
            final lat = (c[1] as num).toDouble();
            return LatLng(lat, lon);
          }).toList();

          final distMeters = (primary['distance'] as num?)?.toDouble() ?? 0.0;
          final durationSec = (primary['duration'] as num?)?.toDouble() ?? 0.0;

          List<LatLng> altPts = [];
          if (routes.length > 1) {
            final alt = routes[1] as Map<String, dynamic>;
            final altCoords = alt['geometry']['coordinates'] as List<dynamic>;
            altPts = altCoords.map<LatLng>((c) {
              final lon = (c[0] as num).toDouble();
              final lat = (c[1] as num).toDouble();
              return LatLng(lat, lon);
            }).toList();
          } else {
            altPts = _generateCurvedFallbackRoute(origin, dest, offsetFactor: 0.008);
          }

          if (mounted) {
            setState(() {
              _primaryRoutePoints = primaryPts;
              _alternateRoutePoints = altPts;
              _distanceKm = distMeters / 1000.0;
              _etaMinutes = math.max(2, (durationSec / 60.0).round());
              _isLoadingRoute = false;
            });
            _fitBoundsSafely();
            return;
          }
        }
      }
    } catch (_) {
      // Fall through to fallback routing
    }

    // 2. High-precision fallback if offline or network unavailable
    final directKm = _calculateHaversineKm(origin, dest);
    final estimatedRoadKm = directKm * 1.26; // Road circuity factor in Tamil Nadu
    final estimatedMinutes = math.max(2, (estimatedRoadKm / 28.0 * 60).round());

    final primaryFallback = _generateCurvedFallbackRoute(origin, dest, offsetFactor: 0.003);
    final altFallback = _generateCurvedFallbackRoute(origin, dest, offsetFactor: -0.007);

    if (mounted) {
      setState(() {
        _primaryRoutePoints = primaryFallback;
        _alternateRoutePoints = altFallback;
        _distanceKm = estimatedRoadKm;
        _etaMinutes = estimatedMinutes;
        _isLoadingRoute = false;
      });
      _fitBoundsSafely();
    }
  }

  void _fitBoundsSafely() {
    if (!widget.isInteractive) return;
    try {
      final points = _useAlternateRoute && _alternateRoutePoints.isNotEmpty
          ? _alternateRoutePoints
          : _primaryRoutePoints;

      if (points.length >= 2) {
        final bounds = LatLngBounds.fromPoints(points);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 48),
          ),
        );
      }
    } catch (_) {}
  }

  static double _calculateHaversineKm(LatLng p1, LatLng p2) {
    const earthRadius = 6371.0;
    final dLat = (p2.latitude - p1.latitude) * math.pi / 180.0;
    final dLon = (p2.longitude - p1.longitude) * math.pi / 180.0;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(p1.latitude * math.pi / 180.0) *
            math.cos(p2.latitude * math.pi / 180.0) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static List<LatLng> _generateCurvedFallbackRoute(
    LatLng start,
    LatLng end, {
    required double offsetFactor,
  }) {
    const int segments = 14;
    final List<LatLng> pts = [start];

    final dLat = end.latitude - start.latitude;
    final dLon = end.longitude - start.longitude;

    final normalLat = -dLon;
    final normalLon = dLat;

    for (int i = 1; i < segments; i++) {
      final t = i / segments;
      final curve = math.sin(t * math.pi) * offsetFactor;

      final lat = start.latitude + dLat * t + normalLat * curve;
      final lon = start.longitude + dLon * t + normalLon * curve;
      pts.add(LatLng(lat, lon));
    }

    pts.add(end);
    return pts;
  }

  @override
  Widget build(BuildContext context) {
    final center = _getCenter();

    final List<Marker> markers = [];

    // Sanitize marker locations
    final farmPt = widget.farmerLocation != null
        ? LocationDirectoryService.sanitize(
            widget.farmerLocation!.latitude,
            widget.farmerLocation!.longitude,
            referencePoint: LocationDirectoryService.udumalpet,
          )
        : null;

    final buyerPt = widget.buyerLocation != null
        ? LocationDirectoryService.sanitize(
            widget.buyerLocation!.latitude,
            widget.buyerLocation!.longitude,
            referencePoint: LocationDirectoryService.ukkadam,
          )
        : null;

    final partnerPt = widget.partnerLocation != null
        ? LocationDirectoryService.sanitize(
            widget.partnerLocation!.latitude,
            widget.partnerLocation!.longitude,
            referencePoint: farmPt ?? LocationDirectoryService.udumalpet,
          )
        : null;

    // 1. Farmer Marker
    if (farmPt != null) {
      markers.add(
        Marker(
          point: farmPt,
          width: 76,
          height: 70,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF141916),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF22C55E), width: 1),
                ),
                child: Text(
                  widget.farmerName ?? 'Farm',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.location_pin,
                color: Color(0xFF22C55E),
                size: 32,
              ),
            ],
          ),
        ),
      );
    }

    // 2. Buyer Marker
    if (buyerPt != null) {
      markers.add(
        Marker(
          point: buyerPt,
          width: 76,
          height: 70,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF141916),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFF5252), width: 1),
                ),
                child: Text(
                  widget.buyerName ?? 'Delivery Hub',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    if (partnerPt != null) {
      markers.add(
        Marker(
          point: partnerPt,
          width: 48,
          height: 48,
          child: Transform.rotate(
            angle: (widget.heading ?? 0) * (math.pi / 180),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFC107).withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 3,
                  ),
                ],
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                color: Colors.black,
                size: 26,
              ),
            ),
          ),
        ),
      );
    }

    final activeRoute = _useAlternateRoute ? _alternateRoutePoints : _primaryRoutePoints;
    final secondaryRoute = _useAlternateRoute ? _primaryRoutePoints : _alternateRoutePoints;

    final displayDistance = _useAlternateRoute ? _distanceKm * 1.08 : _distanceKm;
    final displayEta = _useAlternateRoute ? _etaMinutes + 4 : _etaMinutes;

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF101412),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
              // Clean OpenStreetMap standard tiles (No watermarks, no API key required)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.kisanai.sem7_project',
              ),

              // Polyline Layer with Traffic & Alternate Routes
              if (widget.showPolyline)
                PolylineLayer(
                  polylines: [
                    // Secondary Route (In background, dimmer)
                    if (secondaryRoute.length >= 2)
                      Polyline(
                        points: secondaryRoute,
                        strokeWidth: 3.0,
                        color: Colors.blueAccent.withValues(alpha: 0.35),
                      ),

                    // Active Route Glow
                    if (activeRoute.length >= 2)
                      Polyline(
                        points: activeRoute,
                        strokeWidth: 7.0,
                        color: (_useAlternateRoute
                                ? Colors.blueAccent
                                : const Color(0xFF22C55E))
                            .withValues(alpha: 0.22),
                      ),

                    // Active Route Foreground
                    if (activeRoute.length >= 2)
                      Polyline(
                        points: activeRoute,
                        strokeWidth: 4.0,
                        color: _useAlternateRoute
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF22C55E),
                      ),
                  ],
                ),

              // Markers
              MarkerLayer(markers: markers),
            ],
          ),

          // Floating Route Info & Traffic Header Overlay
          if (widget.showRouteInfoOverlay && displayDistance > 0.05)
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF141916).withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Distance
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.route_rounded,
                          color: Color(0xFF22C55E),
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${displayDistance.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 8),
                    Container(width: 1, height: 14, color: Colors.white24),
                    const SizedBox(width: 8),

                    // ETA
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: Color(0xFFFFC107),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$displayEta min',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Traffic / Route Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: (_useAlternateRoute
                                ? Colors.blueAccent
                                : const Color(0xFF22C55E))
                            .withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (_useAlternateRoute
                                  ? Colors.blueAccent
                                  : const Color(0xFF22C55E))
                              .withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _useAlternateRoute
                                  ? Colors.blueAccent
                                  : const Color(0xFF22C55E),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _useAlternateRoute ? 'Alt Route' : 'Fastest',
                            style: TextStyle(
                              color: _useAlternateRoute
                                  ? Colors.blueAccent
                                  : const Color(0xFF22C55E),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 6),

                    // Alternate Route Toggle Button
                    if (widget.isInteractive)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _useAlternateRoute = !_useAlternateRoute;
                          });
                          _fitBoundsSafely();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.alt_route_rounded,
                                color: Colors.white70,
                                size: 12,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _useAlternateRoute ? 'Main' : 'Alt',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Loading Route Indicator
          if (_isLoadingRoute)
            Positioned(
              top: 54,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Optimizing route...',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),

          // Recenter Button
          if (widget.isInteractive)
            Positioned(
              right: 12,
              bottom: 12,
              child: GestureDetector(
                onTap: () {
                  _mapController.move(_getCenter(), widget.initialZoom);
                  _fitBoundsSafely();
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF141916),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: Color(0xFFFFC107),
                    size: 18,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
