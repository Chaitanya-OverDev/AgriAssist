import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/location_service.dart';
import 'package:agriassist/services/api_service.dart';
import 'models/weather_model.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({Key? key}) : super(key: key);

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late Future<WeatherModel> _weatherFuture;
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _weatherFuture = _fetchRealWeather();
  }

  /// 🔁 Fetches GPS, Posts to Backend, and Gets Real Weather
  Future<WeatherModel> _fetchRealWeather() async {
    try {
      Position position = await _locationService.getCurrentLocation();

      bool locationUpdated = await ApiService.updateUserLocation(
        position.latitude,
        position.longitude,
      );

      if (!locationUpdated) {
        throw Exception("Failed to sync location with server.");
      }

      final weatherData = await ApiService.getWeatherForecast();

      if (weatherData == null || !weatherData.containsKey('forecast')) {
        throw Exception("Failed to load weather data from server.");
      }

      List<DailyForecast> parsedForecast = (weatherData['forecast'] as List).map((item) {
        return DailyForecast(
          date: item['date'],
          tempMax: (item['temp_max'] as num).toDouble(),
          tempMin: (item['temp_min'] as num).toDouble(),
          rainMm: (item['rain_mm'] as num).toDouble(),
          condition: item['condition'],
        );
      }).toList();

      return WeatherModel(
        location: weatherData['location'] ?? "Unknown Location",
        forecast: parsedForecast,
      );

    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Helper to get static farmer advice based on the weather condition
  Map<String, String> _getFarmerAdvice(String condition) {
    String cond = condition.toLowerCase();
    if (cond.contains('sun') || cond.contains('clear')) {
      return {
        'good': 'Ideal for harvesting, sun-drying crops, and tilling.',
        'bad': 'High evaporation. Ensure crops are well-irrigated.'
      };
    } else if (cond.contains('cloud')) {
      return {
        'good': 'Perfect weather for spraying fertilizers and pesticides.',
        'bad': 'Not ideal for solar-drying harvested crops.'
      };
    } else if (cond.contains('rain')) {
      return {
        'good': 'Natural irrigation! Great time for transplanting saplings.',
        'bad': 'Do not spray chemicals. Avoid harvesting to prevent rot.'
      };
    } else if (cond.contains('storm') || cond.contains('thunder')) {
      return {
        'good': 'Indoor planning and maintaining farming equipment.',
        'bad': 'Risk of crop damage. Secure livestock and stay safe.'
      };
    } else {
      return {
        'good': 'Favorable for general field inspections.',
        'bad': 'Keep an eye out for sudden weather shifts.'
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF8F1), // Gentle farm green background
      body: SafeArea(
        child: FutureBuilder<WeatherModel>(
          future: _weatherFuture,
          builder: (context, snapshot) {

            // Loading State
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      "Locating and fetching weather...",
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }

            // Error State
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text(
                        "Oops! Something went wrong.\n${snapshot.error}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        onPressed: () {
                          setState(() {
                            _weatherFuture = _fetchRealWeather();
                          });
                        },
                        child: const Text("Try Again", style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                ),
              );
            }

            // No Data State
            if (!snapshot.hasData || snapshot.data!.forecast.isEmpty) {
              return const Center(child: Text("No weather data available"));
            }

            // Success State
            final weather = snapshot.data!;
            final today = weather.forecast.first;

            return Column(
              children: [
                /// Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          "Farm Weather Report",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Balancing spacer
                    ],
                  ),
                ),

                /// Today's Big Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      Text(
                        weather.location,
                        style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            _getWeatherImage(today.condition),
                            height: 80,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.cloud, size: 80, color: Colors.grey),
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${today.tempMax.toInt()}°C",
                                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              Text(
                                "Expect ${today.condition}",
                                style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500),
                              ),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// Forecast List Label
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "5-Day Forecast & Advice",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ),
                ),

                /// Scrollable Cards List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    physics: const BouncingScrollPhysics(),
                    itemCount: weather.forecast.length,
                    itemBuilder: (context, index) {
                      return _forecastTile(weather.forecast[index], index == 0);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Individual Day Card
  Widget _forecastTile(DailyForecast daily, bool isToday) {
    DateTime parsedDate = DateTime.parse(daily.date);
    String dayName = isToday ? "Today" : DateFormat('EEEE, MMM d').format(parsedDate);

    // Get the dynamic farmer advice string
    Map<String, String> advice = _getFarmerAdvice(daily.condition);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Top Row: Date, Icon, High/Low Temps
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Image.asset(
                      _getWeatherImage(daily.condition),
                      height: 36,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.cloud, size: 30, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "High: ${daily.tempMax.toInt()}°C",
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.orange),
                        ),
                        Text(
                          "Low: ${daily.tempMin.toInt()}°C",
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.blue),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(color: Color(0xFFEEEEEE)),
            ),

            /// Bottom Row: Farmer Advice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6FBF8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2F0E9)),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Good: ${advice['good']}",
                          style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.cancel, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Bad: ${advice['bad']}",
                          style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
      case "rainy":
        return "assets/images/weather/rain.png";
      case "storm":
      case "thunderstorm":
        return "assets/images/weather/storm.png";
      default:
        return "assets/images/weather/default.png"; // Fallback image
    }
  }
}