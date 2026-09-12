import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/language_service.dart';

class WeatherCard extends StatelessWidget {
  final String temperature;
  final String condition;
  final String location;
  final VoidCallback? onTap;

  const WeatherCard({
    super.key,
    required this.temperature,
    required this.condition,
    required this.location,
    this.onTap,
  });

  IconData getWeatherIcon() {
    final weather = condition.toLowerCase();

    if (weather.contains("cloud")) {
      return Icons.cloud_outlined;
    }

    if (weather.contains("rain")) {
      return Icons.thunderstorm_outlined;
    }

    if (weather.contains("storm")) {
      return Icons.thunderstorm_outlined;
    }

    if (weather.contains("mist") || weather.contains("fog")) {
      return Icons.foggy;
    }

    return Icons.wb_sunny_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF017422).withOpacity(.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Top Row
            Row(
              children: [
                Text(
                  tr('todays_weather', defaultText: "Today's Weather"),
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const Spacer(),

                Icon(
                  getWeatherIcon(),
                  color: Colors.white70,
                  size: 34,
                ),
              ],
            ),

            const SizedBox(height: 3),

            Center(
              child: Column(
                children: [
                  Text(
                    temperature,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFFC107),
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    condition,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 2),

            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Colors.white54,
                  size: 18,
                ),

                const SizedBox(width: 6),

                Expanded(
                  child: Text(
                    location,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ),

                Text(
                  "View",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF017422),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(width: 4),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF017422),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}