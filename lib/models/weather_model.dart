import 'dart:math';

class WeatherAlertModel {
  final String title;
  final String titleLocal;
  final String severity; // 'Warning', 'Watch', 'Advisory'
  final String description;
  final String farmingAdvisory;
  final String icon;

  WeatherAlertModel({
    required this.title,
    required this.titleLocal,
    required this.severity,
    required this.description,
    required this.farmingAdvisory,
    required this.icon,
  });
}

class DailyForecastModel {
  final String dayName;
  final double maxTemp;
  final double minTemp;
  final String condition;
  final String icon;
  final int rainProbability;

  DailyForecastModel({
    required this.dayName,
    required this.maxTemp,
    required this.minTemp,
    required this.condition,
    required this.icon,
    required this.rainProbability,
  });
}

class WeatherModel {
  final double temperature;
  final String condition;
  final int humidity;
  final double windSpeed;
  final String weatherIcon;
  final double feelsLike;
  final int rainProbability;
  final double uvIndex;
  final List<WeatherAlertModel> alerts;
  final List<DailyForecastModel> dailyForecast;

  WeatherModel({
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    this.weatherIcon = '☀️',
    this.feelsLike = 32.0,
    this.rainProbability = 15,
    this.uvIndex = 7.0,
    this.alerts = const [],
    this.dailyForecast = const [],
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('current_weather')) {
      final current = json['current_weather'] as Map<String, dynamic>;
      final code = (current['weathercode'] as num?)?.toInt() ?? 0;
      final temp = (current['temperature'] as num?)?.toDouble() ?? 30.0;
      final wind = (current['windspeed'] as num?)?.toDouble() ?? 10.0;

      int hum = 65;
      if (json.containsKey('hourly') && json['hourly']['relativehumidity_2m'] != null) {
        final humList = json['hourly']['relativehumidity_2m'] as List;
        if (humList.isNotEmpty) {
          hum = (humList.first as num).toInt();
        }
      }

      final mapped = _mapWeatherCode(code);
      final alerts = _generateAgriAlerts(temp, wind, hum, code);
      final daily = _parseDailyForecast(json['daily']);

      return WeatherModel(
        temperature: temp,
        condition: mapped['condition'] as String,
        humidity: hum,
        windSpeed: wind,
        weatherIcon: mapped['icon'] as String,
        feelsLike: double.parse((temp + (hum > 70 ? 2.5 : 0.5)).toStringAsFixed(1)),
        rainProbability: code >= 51 ? 85 : (hum > 75 ? 45 : 15),
        uvIndex: temp > 33 ? 8.5 : 6.0,
        alerts: alerts,
        dailyForecast: daily,
      );
    }

    final main = json['main'] ?? {};
    final weatherList = json['weather'] as List? ?? [];
    final cond = weatherList.isNotEmpty ? (weatherList[0]['main'] ?? 'Clear') : 'Clear';
    final temp = (main['temp'] as num?)?.toDouble() ?? 28.0;
    final hum = (main['humidity'] as num?)?.toInt() ?? 60;
    final wind = ((json['wind'] ?? {})['speed'] as num?)?.toDouble() ?? 8.0;

    return WeatherModel(
      temperature: temp,
      condition: cond.toString(),
      humidity: hum,
      windSpeed: wind,
      weatherIcon: _iconForCondition(cond.toString()),
      feelsLike: (main['feels_like'] as num?)?.toDouble() ?? temp,
      rainProbability: cond.toString().toLowerCase().contains('rain') ? 80 : 20,
      uvIndex: 6.5,
      alerts: _generateAgriAlerts(temp, wind, hum, 0),
      dailyForecast: _defaultWeekForecast(temp),
    );
  }

  static List<WeatherAlertModel> _generateAgriAlerts(double temp, double wind, int hum, int code) {
    final List<WeatherAlertModel> list = [];

    // Rain / Storm Alert
    if (code >= 51 || hum > 80) {
      list.add(WeatherAlertModel(
        title: 'Heavy Rain Warning (85% Probability)',
        titleLocal: 'கனமழை எச்சரிக்கை (85% வாய்ப்பு)',
        severity: 'Warning',
        description: 'Moderate to heavy rain expected across regional farming clusters.',
        farmingAdvisory: 'Clear field drainage channels. Postpone foliar pesticide spraying and fertilizer application.',
        icon: '🌧️',
      ));
    }

    // Heatwave Alert
    if (temp >= 35.0) {
      list.add(WeatherAlertModel(
        title: 'High Heat Advisory (${temp.round()}°C)',
        titleLocal: 'வெப்ப அலை எச்சரிக்கை (${temp.round()}°C)',
        severity: 'Advisory',
        description: 'Elevated daytime evapotranspiration rate.',
        farmingAdvisory: 'Irrigate crops during early morning or evening hours. Apply straw mulch to conserve root moisture.',
        icon: '☀️',
      ));
    }

    // Squall / Wind Alert
    if (wind >= 25.0) {
      list.add(WeatherAlertModel(
        title: 'High Wind Squall Alert (${wind.round()} km/h)',
        titleLocal: 'பலத்த காற்று எச்சரிக்கை (${wind.round()} கி.மீ/மணி)',
        severity: 'Warning',
        description: 'Strong wind gusts can cause lodging in tall standing crops.',
        farmingAdvisory: 'Provide bamboo staking support for banana trees and tomato trellises.',
        icon: '💨',
      ));
    }

    if (list.isEmpty) {
      list.add(WeatherAlertModel(
        title: 'Favorable Farming Weather',
        titleLocal: 'விவசாயத்திற்கு உகந்த வானிலை',
        severity: 'Advisory',
        description: 'Mild temperatures and optimal soil aeration conditions.',
        farmingAdvisory: 'Ideal window for field weeding, inter-cultivation, and produce harvesting.',
        icon: '🌱',
      ));
    }

    return list;
  }

  static List<DailyForecastModel> _parseDailyForecast(dynamic dailyJson) {
    if (dailyJson is Map) {
      final times = dailyJson['time'] as List? ?? [];
      final maxTemps = dailyJson['temperature_2m_max'] as List? ?? [];
      final minTemps = dailyJson['temperature_2m_min'] as List? ?? [];
      final codes = dailyJson['weathercode'] as List? ?? [];
      final rains = dailyJson['precipitation_probability_max'] as List? ?? [];

      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final List<DailyForecastModel> result = [];

      for (int i = 0; i < min(7, times.length); i++) {
        final code = i < codes.length ? (codes[i] as num).toInt() : 0;
        final mapped = _mapWeatherCode(code);
        final date = DateTime.tryParse(times[i].toString()) ?? DateTime.now().add(Duration(days: i));
        final dayName = i == 0 ? 'Today' : (i == 1 ? 'Tomorrow' : days[date.weekday - 1]);

        result.add(DailyForecastModel(
          dayName: dayName,
          maxTemp: i < maxTemps.length ? (maxTemps[i] as num).toDouble() : 32.0,
          minTemp: i < minTemps.length ? (minTemps[i] as num).toDouble() : 22.0,
          condition: mapped['condition'] as String,
          icon: mapped['icon'] as String,
          rainProbability: i < rains.length ? (rains[i] as num).toInt() : (code >= 51 ? 80 : 15),
        ));
      }
      if (result.isNotEmpty) return result;
    }
    return _defaultWeekForecast(31.0);
  }

  static List<DailyForecastModel> _defaultWeekForecast(double baseTemp) {
    final days = ['Today', 'Tomorrow', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return List.generate(7, (i) {
      final isRainy = i == 2 || i == 3;
      return DailyForecastModel(
        dayName: days[i],
        maxTemp: baseTemp + (i.isEven ? 1.0 : -1.0),
        minTemp: baseTemp - 8.0,
        condition: isRainy ? 'Light Rain' : 'Partly Cloudy',
        icon: isRainy ? '🌧️' : '⛅',
        rainProbability: isRainy ? 75 : 20,
      );
    });
  }

  static Map<String, String> _mapWeatherCode(int code) {
    if (code == 0) return {'condition': 'Clear Sky', 'icon': '☀️'};
    if (code == 1 || code == 2) return {'condition': 'Partly Cloudy', 'icon': '⛅'};
    if (code == 3) return {'condition': 'Overcast', 'icon': '☁️'};
    if (code == 45 || code == 48) return {'condition': 'Foggy', 'icon': '🌫️'};
    if (code >= 51 && code <= 55) return {'condition': 'Drizzle', 'icon': '🌦️'};
    if (code >= 61 && code <= 65) return {'condition': 'Rain', 'icon': '🌧️'};
    if (code >= 71 && code <= 77) return {'condition': 'Snow', 'icon': '❄️'};
    if (code >= 80 && code <= 82) return {'condition': 'Showers', 'icon': '🌧️'};
    if (code >= 95) return {'condition': 'Thunderstorm', 'icon': '⛈️'};
    return {'condition': 'Partly Cloudy', 'icon': '⛅'};
  }

  static String _iconForCondition(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('rain') || c.contains('shower')) return '🌧️';
    if (c.contains('thunder') || c.contains('storm')) return '⛈️';
    if (c.contains('cloud')) return '⛅';
    if (c.contains('fog') || c.contains('mist')) return '🌫️';
    return '☀️';
  }

  static WeatherModel defaultCoimbatore() {
    return WeatherModel(
      temperature: 31.5,
      condition: 'Partly Cloudy',
      humidity: 62,
      windSpeed: 11.4,
      weatherIcon: '⛅',
      feelsLike: 33.0,
      rainProbability: 25,
      uvIndex: 7.2,
      alerts: _generateAgriAlerts(31.5, 11.4, 62, 2),
      dailyForecast: _defaultWeekForecast(31.5),
    );
  }
}
