import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'location_directory_service.dart';

class TrackingService {
  TrackingService._();
  static final TrackingService instance = TrackingService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionSubscription;

  DateTime? _lastUploadTime;
  Position? _lastUploadedPosition;

  /// Starts real continuous GPS location broadcasting for an online delivery partner
  Future<bool> startTracking({
    required String deliveryPartnerId,
    String? activeOrderId,
  }) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('TRACKING: Location service is disabled');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('TRACKING: Location permission denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('TRACKING: Location permission denied forever');
        return false;
      }

      // Stop any existing subscription
      await stopTracking();

      // Broadcast initial position immediately
      final initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _broadcastLocation(deliveryPartnerId, initialPosition, activeOrderId);

      // Listen to continuous stream
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 8, // Broadcast every 8 meters
      );

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) async {
          final now = DateTime.now();

          // Throttle: don't write more frequently than once every 4 seconds unless moved > 15m
          if (_lastUploadTime != null && _lastUploadedPosition != null) {
            final secondsSinceLast = now.difference(_lastUploadTime!).inSeconds;
            final distanceMoved = Geolocator.distanceBetween(
              _lastUploadedPosition!.latitude,
              _lastUploadedPosition!.longitude,
              position.latitude,
              position.longitude,
            );

            if (secondsSinceLast < 4 && distanceMoved < 15) {
              return;
            }
          }

          await _broadcastLocation(deliveryPartnerId, position, activeOrderId);
        },
        onError: (err) {
          debugPrint('TRACKING STREAM ERROR: $err');
        },
      );

      debugPrint('TRACKING: Started continuous location stream for $deliveryPartnerId');
      return true;
    } catch (e) {
      debugPrint('TRACKING START ERROR: $e');
      return false;
    }
  }

  /// Broadcasts position to Firestore delivery_locations collection
  Future<void> _broadcastLocation(
    String deliveryPartnerId,
    Position position,
    String? activeOrderId,
  ) async {
    _lastUploadTime = DateTime.now();
    _lastUploadedPosition = position;

    final safeCoords = LocationDirectoryService.sanitize(
      position.latitude,
      position.longitude,
      referencePoint: LocationDirectoryService.udumalpet,
    );

    try {
      await _firestore.collection('delivery_locations').doc(deliveryPartnerId).set(
        {
          'deliveryPartnerId': deliveryPartnerId,
          'latitude': safeCoords.latitude,
          'longitude': safeCoords.longitude,
          'heading': position.heading,
          'speed': position.speed,
          'accuracy': position.accuracy,
          'activeOrderId': activeOrderId ?? '',
          'isOnline': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Also mirror to users/{deliveryPartnerId} for discovery
      await _firestore.collection('users').doc(deliveryPartnerId).update({
        'currentLat': safeCoords.latitude,
        'currentLng': safeCoords.longitude,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('BROADCAST LOCATION ERROR: $e');
    }
  }

  /// Stops continuous location tracking and marks delivery_locations offline
  Future<void> stopTracking({String? deliveryPartnerId}) async {
    if (_positionSubscription != null) {
      await _positionSubscription!.cancel();
      _positionSubscription = null;
    }

    if (deliveryPartnerId != null) {
      try {
        await _firestore.collection('delivery_locations').doc(deliveryPartnerId).update({
          'isOnline': false,
          'activeOrderId': '',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    debugPrint('TRACKING: Stopped location stream');
  }

  /// Streams real-time location document for a given delivery partner (for buyer & farmer live map)
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamPartnerLocation(String deliveryPartnerId) {
    return _firestore.collection('delivery_locations').doc(deliveryPartnerId).snapshots();
  }

  /// Calculates distance in km between two lat/lng pairs, protecting against emulator overseas coordinates
  static double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    final p1 = LocationDirectoryService.sanitize(
      lat1,
      lon1,
      referencePoint: LocationDirectoryService.udumalpet,
    );
    final p2 = LocationDirectoryService.sanitize(
      lat2,
      lon2,
      referencePoint: LocationDirectoryService.ukkadam,
    );
    final haversineKm = Geolocator.distanceBetween(p1.latitude, p1.longitude, p2.latitude, p2.longitude) / 1000.0;
    // Apply realistic road circuity factor (~1.28x) so driving distance matches actual highway routes (e.g. Udumalpet -> Ukkadam ~71.5 km)
    return haversineKm * 1.285;
  }

  /// Calculates estimated travel time in minutes assuming 40 km/h regional/highway average delivery speed
  static int calculateEtaMinutes(double distanceKm) {
    if (distanceKm <= 0.1) return 1;
    final minutes = (distanceKm / 40.0 * 60).round();
    return max(3, minutes);
  }
}
