import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Authoritative production cloud backend URL (Permanent HTTPS)
  static const String hostedCloudApiUrl = 'https://kisanlinkai-backend.onrender.com';

  /// Override this if testing with a custom cloud host
  static String? customBackendUrl;

  /// Razorpay Key ID
  static const String defaultRazorpayKeyId = 'rzp_test_TOT4ASXnGKXbXF';

  /// Cached working URL
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
      return [hostedCloudApiUrl, 'http://localhost:8000'];
    }

    // HTTPS cloud endpoint is always primary
    return [
      hostedCloudApiUrl,
      'http://10.0.2.2:8000', // Local emulator fallback
    ];
  }

  /// Resolves the payment backend base URL
  static String get paymentBackendUrl {
    if (_workingBackendUrl != null && _workingBackendUrl!.isNotEmpty) {
      return _workingBackendUrl!;
    }
    if (customBackendUrl != null && customBackendUrl!.isNotEmpty) {
      return customBackendUrl!;
    }
    return hostedCloudApiUrl;
  }

  static void setWorkingUrl(String url) {
    _workingBackendUrl = url;
  }
}
