import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final w = weather ?? WeatherModel.defaultCoimbatore();
    final alerts = w.alerts;
    final forecast = w.dailyForecast;

    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLocaleNotifier,
      builder: (context, locale, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.card,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              LanguageService.tr('weather_forecast', defaultText: 'Agri Weather & Alerts'),
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Severe Weather Alerts Banner
                if (alerts.isNotEmpty) ...[
                  ...alerts.map((alert) => Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: alert.severity == 'Warning'
                              ? const Color(0xFF2E1515)
                              : const Color(0xFF142416),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: alert.severity == 'Warning'
                                ? Colors.redAccent.withValues(alpha: 0.5)
                                : AppColors.primary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(alert.icon, style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: alert.severity == 'Warning'
                                              ? Colors.redAccent.withValues(alpha: 0.2)
                                              : AppColors.primary.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          alert.severity.toUpperCase(),
                                          style: TextStyle(
                                            color: alert.severity == 'Warning' ? Colors.redAccent : AppColors.primary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          LanguageService.currentLanguage == 'ta'
                                              ? alert.titleLocal
                                              : alert.title,
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    alert.description,
                                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '💡 ${alert.farmingAdvisory}',
                                    style: GoogleFonts.poppins(
                                      color: alert.severity == 'Warning' ? Colors.amberAccent : AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                ],

                // 2. Current Weather Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            location,
                            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(w.weatherIcon, style: const TextStyle(fontSize: 48)),
                          const SizedBox(width: 14),
                          Text(
                            "${w.temperature.round()}°C",
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 52, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        LanguageService.tr(w.condition),
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Rain probability: ${w.rainProbability}% • Feels like ${w.feelsLike.round()}°C",
                        style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. Grid Stats (Input-Driven)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard(Icons.thermostat_rounded, "Feels Like", "${w.feelsLike.round()}°C"),
                    _buildStatCard(Icons.water_drop_rounded, "Humidity", "${w.humidity}%"),
                    _buildStatCard(Icons.air_rounded, "Wind Speed", "${w.windSpeed.round()} km/h"),
                    _buildStatCard(Icons.wb_sunny_rounded, "UV Index", "${w.uvIndex.toStringAsFixed(1)} (Very High)"),
                  ],
                ),

                const SizedBox(height: 26),

                // 4. 7-Day Agronomic Forecast
                Text(
                  LanguageService.tr('7_day_forecast', defaultText: '7-Day Agronomic Forecast'),
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                ...forecast.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        children: [
                          Text(item.icon, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  LanguageService.tr(item.dayName, defaultText: item.dayName),
                                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                Text(
                                  LanguageService.tr(item.condition),
                                  style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.water_drop_rounded, color: Colors.blueAccent, size: 12),
                              const SizedBox(width: 3),
                              Text(
                                '${item.rainProbability}%',
                                style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '${item.maxTemp.round()}° / ${item.minTemp.round()}°',
                                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: 24),

                // 5. Farming Insights
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            LanguageService.tr('farming_insights', defaultText: 'Smart Agronomic Insights'),
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildInsightItem(
                        Icons.schedule_rounded,
                        'Best Spraying Window',
                        w.windSpeed > 18
                            ? 'Wind speeds > 18 km/h. Postpone spraying to prevent chemical spray drift.'
                            : 'Optimal conditions between 6:30 AM - 9:00 AM. Low wind drift risk.',
                      ),
                      const SizedBox(height: 10),
                      _buildInsightItem(
                        Icons.water_drop_outlined,
                        'Irrigation Recommendation',
                        w.rainProbability > 60
                            ? 'Rain expected (over 60%). Delay scheduled drip irrigation to avoid waterlogging.'
                            : 'Soil evaporation rate is elevated. Provide 2.5 hours drip run during evening.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                LanguageService.tr(title, defaultText: title),
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(desc, style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}
