import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/weather_model.dart';
import '../services/language_service.dart';

class WeatherDetailsScreen extends StatelessWidget {
  final WeatherModel? weather;
  final String location;

  const WeatherDetailsScreen({
    super.key,
    required this.weather,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLocaleNotifier,
      builder: (context, locale, _) {
        return Scaffold(
          backgroundColor: AppColors.background,

          appBar: AppBar(
            backgroundColor: AppColors.card,
            elevation: 0,
            centerTitle: true,
            title: Text(
              LanguageService.tr("Weather Forecast"),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),

          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                // Current Weather
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [

                      const Text(
                        "📍",
                        style: TextStyle(fontSize: 26),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        location,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        "${weather?.temperature.round() ?? "--"}°C",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        LanguageService.tr(weather?.condition ?? "Sunny"),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Weather Stats
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.3,
                  children: [

                    WeatherInfoCard(
                      icon: Icons.thermostat,
                      title: LanguageService.tr("Feels Like"),
                      value: "31°C",
                    ),

                    WeatherInfoCard(
                      icon: Icons.water_drop,
                      title: LanguageService.tr("Humidity"),
                      value: "72%",
                    ),

                    WeatherInfoCard(
                      icon: Icons.air,
                      title: LanguageService.tr("Wind"),
                      value: "12 km/h",
                    ),

                    WeatherInfoCard(
                      icon: Icons.wb_sunny,
                      title: LanguageService.tr("uv_index"),
                      value: LanguageService.tr("High"),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // 7 Day Forecast

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    LanguageService.tr("7_day_forecast"),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),

                const SizedBox(height: 15),

                ...List.generate(
                  7,
                  (index) => ForecastTile(
                    day: LanguageService.tr([
                      "Today",
                      "Tomorrow",
                      "Sunday",
                      "Monday",
                      "Tuesday",
                      "Wednesday",
                      "Thursday"
                    ][index]),
                  ),
                ),

                const SizedBox(height: 30),

                // Farming Insights

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        "🌱 ${LanguageService.tr('farming_insights')}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      InsightRow(
                        icon: Icons.water_drop,
                        text: LanguageService.tr("best_irrigation_time"),
                      ),

                      InsightRow(
                        icon: Icons.cloud,
                        text: LanguageService.tr("no_heavy_rain"),
                      ),

                      InsightRow(
                        icon: Icons.agriculture,
                        text: LanguageService.tr("suitable_harvest"),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}

class WeatherInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const WeatherInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Icon(
            icon,
            color: AppColors.primary,
            size: 30,
          ),

          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white60,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class ForecastTile extends StatelessWidget {
  final String day;

  const ForecastTile({
    super.key,
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Text(
          "🌤",
          style: TextStyle(fontSize: 22),
        ),
        title: Text(
          day,
          style: const TextStyle(color: Colors.white),
        ),
        trailing: const Text(
          "30° / 24°",
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}

class InsightRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const InsightRow({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [

          Icon(
            icon,
            color: AppColors.primary,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}