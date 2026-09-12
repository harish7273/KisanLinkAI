import 'package:latlong2/latlong.dart';

class LocationDirectoryService {
  LocationDirectoryService._();

  static const LatLng udumalpet = LatLng(10.5855, 77.2492);
  static const LatLng ukkadam = LatLng(10.9930, 76.9600);
  static const LatLng pollachi = LatLng(10.6609, 77.0048);
  static const LatLng gandhipuram = LatLng(11.0168, 76.9558);
  static const LatLng thondamuthur = LatLng(10.9984, 76.9012);
  static const LatLng rsPuram = LatLng(11.0083, 76.9450);
  static const LatLng bhavani = LatLng(11.4480, 77.6830);
  static const LatLng erode = LatLng(11.3410, 77.7172);
  static const LatLng mettupalayam = LatLng(11.3000, 76.9500);
  static const LatLng kinathukadavu = LatLng(10.8228, 77.0194);
  static const LatLng defaultCoimbatore = LatLng(11.0168, 76.9558);

  static final Map<String, LatLng> _hubDirectory = {
    'udumalpet': udumalpet,
    'udumalaipettai': udumalpet,
    'ukkadam': ukkadam,
    'pollachi': pollachi,
    'gandhipuram': gandhipuram,
    'thondamuthur': thondamuthur,
    'rs puram': rsPuram,
    'r.s. puram': rsPuram,
    'bhavani': bhavani,
    'erode': erode,
    'perundurai': LatLng(11.2753, 77.5833),
    'mettupalayam': mettupalayam,
    'kinathukadavu': kinathukadavu,
    'sathyamangalam': LatLng(11.5034, 77.2444),
    'tiruppur': LatLng(11.1085, 77.3411),
    'coimbatore': defaultCoimbatore,
  };

  /// Resolves an address or location name to known Tamil Nadu agricultural coordinates
  static LatLng resolveLocation(String? address, {LatLng? fallback}) {
    if (address == null || address.trim().isEmpty) {
      return fallback ?? defaultCoimbatore;
    }

    final lower = address.toLowerCase();
    for (final entry in _hubDirectory.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }

    return fallback ?? defaultCoimbatore;
  }

  /// Checks if coordinates fall within the realistic geographical bounds of India / South India
  static bool isWithinIndia(double lat, double lng) {
    return lat >= 8.0 && lat <= 36.0 && lng >= 68.0 && lng <= 97.0;
  }

  /// Convenience overload taking a LatLng object
  static bool isWithinIndiaCoord(LatLng p) => isWithinIndia(p.latitude, p.longitude);

  /// Sanitizes coordinates: if coordinates are from an Android emulator (e.g. Mountain View, CA 37.42, -122.08)
  /// or outside India, clamps them to the provided reference point or default regional hub.
  static LatLng sanitize(double lat, double lng, {LatLng? referencePoint}) {
    if (isWithinIndia(lat, lng)) {
      return LatLng(lat, lng);
    }
    // Emulator coordinate detected outside India - snap to realistic regional coordinates
    return referencePoint ?? defaultCoimbatore;
  }

  /// Convenience overload taking a LatLng object
  static LatLng sanitizeCoord(LatLng p, {LatLng? referencePoint}) {
    return sanitize(p.latitude, p.longitude, referencePoint: referencePoint);
  }
}
