import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sem7_project/services/location_directory_service.dart';
import 'package:sem7_project/services/tracking_service.dart';

void main() {
  group('LocationDirectoryService Tests', () {
    test('Hub coordinates are in Tamil Nadu, India', () {
      expect(LocationDirectoryService.isWithinIndiaCoord(LocationDirectoryService.udumalpet), isTrue);
      expect(LocationDirectoryService.isWithinIndiaCoord(LocationDirectoryService.ukkadam), isTrue);
      expect(LocationDirectoryService.isWithinIndiaCoord(LocationDirectoryService.pollachi), isTrue);
      expect(LocationDirectoryService.isWithinIndiaCoord(LocationDirectoryService.gandhipuram), isTrue);
    });

    test('California emulator coordinates are detected as outside India and sanitized', () {
      const emulatorCoord = LatLng(37.4220, -122.0841); // Mountain View, CA
      expect(LocationDirectoryService.isWithinIndiaCoord(emulatorCoord), isFalse);

      final sanitized = LocationDirectoryService.sanitizeCoord(
        emulatorCoord,
        referencePoint: LocationDirectoryService.udumalpet,
      );
      expect(sanitized.latitude, LocationDirectoryService.udumalpet.latitude);
      expect(sanitized.longitude, LocationDirectoryService.udumalpet.longitude);
    });

    test('Distance calculation for Udumalpet -> Ukkadam (~71.5 km)', () {
      final distance = TrackingService.calculateDistanceKm(
        LocationDirectoryService.udumalpet.latitude,
        LocationDirectoryService.udumalpet.longitude,
        LocationDirectoryService.ukkadam.latitude,
        LocationDirectoryService.ukkadam.longitude,
      );
      // Realistic regional distance between Udumalpet and Ukkadam is ~71.5 km (tolerance 60 - 80 km)
      expect(distance, inInclusiveRange(60.0, 80.0));

      final eta = TrackingService.calculateEtaMinutes(distance);
      // At ~40 km/h avg speed, ~71.5 km takes ~107 minutes (~1h 47m)
      expect(eta, inInclusiveRange(90, 130));
    });

    test('Distance calculation for Pollachi -> Gandhipuram (~44.0 km)', () {
      final distance = TrackingService.calculateDistanceKm(
        LocationDirectoryService.pollachi.latitude,
        LocationDirectoryService.pollachi.longitude,
        LocationDirectoryService.gandhipuram.latitude,
        LocationDirectoryService.gandhipuram.longitude,
      );
      // Realistic distance between Pollachi and Gandhipuram is ~44 km (tolerance 35 - 55 km)
      expect(distance, inInclusiveRange(35.0, 55.0));

      final eta = TrackingService.calculateEtaMinutes(distance);
      // At ~40 km/h avg speed, ~44 km takes ~66 minutes
      expect(eta, inInclusiveRange(50, 80));
    });

    test('Resolves named locations correctly', () {
      final loc1 = LocationDirectoryService.resolveLocation('Udumalpet Organic Farm');
      expect(loc1.latitude, LocationDirectoryService.udumalpet.latitude);

      final loc2 = LocationDirectoryService.resolveLocation('Gandhipuram Central Agro Market');
      expect(loc2.latitude, LocationDirectoryService.gandhipuram.latitude);
    });
  });
}
