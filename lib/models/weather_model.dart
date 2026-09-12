class WeatherModel {
  final double temperature;
  final String condition;
  final int humidity;
  final double windSpeed;
  final String weatherIcon;

  WeatherModel({
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    this.weatherIcon = '☀️',
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    // Check if Open-Meteo format
    if (json.containsKey('current_weather')) {
      final current = json['current_weather'] as Map<String, dynamic>;
      final code = (current['weathercode'] as num?)?.toInt() ?? 0;
      final temp = (current['temperature'] as num?)?.toDouble() ?? 30.0;
      final wind = (current['windspeed'] as num?)?.toDouble() ?? 10.0;

      // Calculate humidity from hourly if available
      int hum = 65;
      if (json.containsKey('hourly') && json['hourly']['relativehumidity_2m'] != null) {
        final humList = json['hourly']['relativehumidity_2m'] as List;
        if (humList.isNotEmpty) {
          hum = (humList.first as num).toInt();
        }
      }

      final mapped = _mapWeatherCode(code);

      return WeatherModel(
        temperature: temp,
        condition: mapped['condition'] as String,
        humidity: hum,
        windSpeed: wind,
        weatherIcon: mapped['icon'] as String,
      );
    }

    // OpenWeather fallback format
    final main = json['main'] ?? {};
    final weatherList = json['weather'] as List? ?? [];
    final cond = weatherList.isNotEmpty ? (weatherList[0]['main'] ?? 'Clear') : 'Clear';

    return WeatherModel(
      temperature: (main['temp'] as num?)?.toDouble() ?? 28.0,
      condition: cond.toString(),
      humidity: (main['humidity'] as num?)?.toInt() ?? 60,
      windSpeed: ((json['wind'] ?? {})['speed'] as num?)?.toDouble() ?? 8.0,
      weatherIcon: _iconForCondition(cond.toString()),
    );
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
    );
  }
}