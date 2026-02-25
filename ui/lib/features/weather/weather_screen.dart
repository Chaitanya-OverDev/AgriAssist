import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import 'models/weather_model.dart';
import 'data/dummy_weather_data.dart'; // Adjust path as needed

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({Key? key}) : super(key: key);

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late Future<WeatherModel> _weatherFuture;
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  double _sheetSize = 0.45;

  @override
  void initState() {
    super.initState();
    // Instantly load dummy data
    _weatherFuture = DummyWeatherData.getForecast();

    _sheetController.addListener(() {
      setState(() {
        _sheetSize = _sheetController.size;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.bgGradientTop,
              AppColors.bgGradientBottom,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<WeatherModel>(
            future: _weatherFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: Text("No weather data available"));
              }

              final weather = snapshot.data!;
              final today = weather.forecast.first;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    /// Top Bar
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        const Text(
                          "Weather Forecast",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// Animated Today Section
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      transform: Matrix4.identity()..translate(0.0, (_sheetSize - 0.45) * -60),
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 250),
                        scale: 1 - ((_sheetSize - 0.45) * 0.3),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 250),
                          opacity: 1 - ((_sheetSize - 0.45) * 0.6),
                          child: Stack(
                            children: [
                              Column(
                                children: [
                                  Text(
                                    weather.location,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  Image.asset(
                                    _getWeatherImage(today.condition),
                                    height: 140,
                                    // Fallback if image not found: errorBuilder
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.cloud, size: 140, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    "${today.tempMax.toInt()}°C",
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Expect ${today.condition.toLowerCase()} today",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                              if (_sheetSize > 0.55)
                                Positioned.fill(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: (_sheetSize - 0.55) * 15,
                                      sigmaY: (_sheetSize - 0.55) * 15,
                                    ),
                                    child: Container(color: Colors.transparent),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    /// Swipe Up Forecast Sheet
                    Expanded(
                      child: DraggableScrollableSheet(
                        controller: _sheetController,
                        initialChildSize: 0.45,
                        minChildSize: 0.45,
                        maxChildSize: 0.85,
                        builder: (context, scrollController) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 50,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: AppColors.borderDefault,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Next 5 Days",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                Expanded(
                                  child: ListView.builder(
                                    controller: scrollController,
                                    itemCount: weather.forecast.length,
                                    itemBuilder: (context, index) {
                                      // Skip today (index 0) in the list if you only want the future days,
                                      // but leaving it in matches your original logic.
                                      return _forecastTile(weather.forecast[index]);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _forecastTile(DailyForecast daily) {
    // Convert "2026-02-25" to "Wed", "Thu"
    DateTime parsedDate = DateTime.parse(daily.date);
    String dayName = DateFormat('EEE').format(parsedDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgGradientTop.withOpacity(0.6),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              dayName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Image.asset(
                _getWeatherImage(daily.condition),
                height: 40,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.cloud, size: 30, color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              "${daily.tempMax.toInt()}°C",
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getWeatherImage(String condition) {
    switch (condition.toLowerCase()) {
      case "sunny":
      case "clear":
        return "assets/images/weather/sunny.png";
      case "cloudy":
      case "clouds":
        return "assets/images/weather/cloudy.png";
      case "rain":
        return "assets/images/weather/rain.png";
      case "storm":
        return "assets/images/weather/storm.png";
      default:
        return "assets/images/weather/default.png"; // Make sure this asset exists
    }
  }
}