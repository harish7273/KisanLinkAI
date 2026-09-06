import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiConfig {
  /// Machine's current LAN IP on Wi-Fi (accessible from physical Android phones on same network)
  static const String machineLanIp = '10.88.48.167';

  /// Override this if you need a custom host (e.g. ngrok or deployed server)
  static String? customBackendUrl;

  /// Default Razorpay Key ID
  static const String defaultRazorpayKeyId = 'rzp_test_TOT4ASXnGKXbXF';

  /// Cached working URL once a successful handshake is made
  static String? _workingBackendUrl;

  /// Returns candidate URLs in order of priority based on environment
  static List<String> get candidateBackendUrls {
    if (customBackendUrl != null && customBackendUrl!.isNotEmpty) {
      return [customBackendUrl!];
    }
    if (_workingBackendUrl != null && _workingBackendUrl!.isNotEmpty) {
      return [_workingBackendUrl!];
    }

    if (kIsWeb) {
      return ['http://localhost:8080'];
    }

    try {
      if (Platform.isAndroid) {
        return [
          'http://$machineLanIp:8080', // Wi-Fi LAN IP (Physical Device & Emulator)
          'http://127.0.0.1:8080',     // USB Tether with ADB reverse
          'http://localhost:8080',     // Localhost
          'http://10.0.2.2:8080',      // Android Emulator QEMU alias
        ];
      }
    } catch (_) {}

    return [
      'http://localhost:8080',
      'http://$machineLanIp:8080',
    ];
  }

  /// Resolves the payment backend base URL based on running platform
  static String get paymentBackendUrl {
    if (_workingBackendUrl != null && _workingBackendUrl!.isNotEmpty) {
      return _workingBackendUrl!;
    }
    if (customBackendUrl != null && customBackendUrl!.isNotEmpty) {
      return customBackendUrl!;
    }
    if (kIsWeb) {
      return 'http://localhost:8080';
    }

    try {
      if (Platform.isAndroid) {
        return 'http://$machineLanIp:8080';
      }
    } catch (_) {}

    return 'http://localhost:8080';
  }

  static void setWorkingUrl(String url) {
    _workingBackendUrl = url;
  }
}

