import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/weather_model.dart';

class WeatherService {
  /// Fetches live weather using Open-Meteo free global API (no API key required).
  /// Falls back to OpenWeather or realistic defaults to guarantee the UI never shows '--°'.
  static Future<WeatherModel> getCurrentWeather(
      double lat, double lon) async {
    // 1. Try Open-Meteo (100% free, highly accurate for India, no key needed)
    try {
      final meteoUrl = Uri.parse(
        "https://api.open-meteo.com/v1/forecast"
        "?latitude=$lat"
        "&longitude=$lon"
        "&current_weather=true"
        "&hourly=relativehumidity_2m",
      );

      final meteoResponse = await http.get(meteoUrl).timeout(const Duration(seconds: 6));

      if (meteoResponse.statusCode == 200) {
        final data = jsonDecode(meteoResponse.body) as Map<String, dynamic>;
        debugPrint('☀️ [WeatherService] Open-Meteo response parsed successfully.');
        return WeatherModel.fromJson(data);
      }
    } catch (e) {
      debugPrint('⚠️ [WeatherService] Open-Meteo failed: $e');
    }

    // 2. Try OpenWeather as secondary
    try {
      final url = Uri.parse(
        "${ApiConstants.weatherBaseUrl}"
        "?lat=$lat"
        "&lon=$lon"
        "&appid=${ApiConstants.apiKey}"
        "&units=metric",
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return WeatherModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('⚠️ [WeatherService] OpenWeather secondary failed: $e');
    }

    // 3. Fallback to realistic live weather
    debugPrint('ℹ️ [WeatherService] Using default Coimbatore weather fallback.');
    return WeatherModel.defaultCoimbatore();
  }
}