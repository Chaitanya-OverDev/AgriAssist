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

  /// 🔁 Logic remains identical to ensure backend compatibility
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

  Map<String, String> _getFarmerAdvice(String condition) {
    String cond = condition.toLowerCase();
    if (cond.contains('sun') || cond.contains('clear')) {
      return {
        'good': 'Ideal for harvesting and sun-drying.',
        'bad': 'High evaporation. Check irrigation.'
      };
    } else if (cond.contains('cloud')) {
      return {
        'good': 'Perfect for spraying fertilizers.',
        'bad': 'Not ideal for solar-drying crops.'
      };
    } else if (cond.contains('rain')) {
      return {
        'good': 'Natural irrigation! Great for transplanting.',
        'bad': 'Avoid harvesting to prevent rot.'
      };
    } else if (cond.contains('storm') || cond.contains('thunder')) {
      return {
        'good': 'Indoor planning and equipment maintenance.',
        'bad': 'Secure livestock and stay safe.'
      };
    }
    return {
      'good': 'Favorable for field inspections.',
      'bad': 'Watch for sudden weather shifts.'
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5), // Ultra clean light grey/green
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black87, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "AgriWeather",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<WeatherModel>(
        future: _weatherFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          if (!snapshot.hasData || snapshot.data!.forecast.isEmpty) {
            return const Center(child: Text("No weather data available"));
          }

          final weather = snapshot.data!;
          final today = weather.forecast.first;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              /// Top Summary Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _buildMainWeatherCard(weather.location, today),
                ),
              ),

              /// Forecast Header
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    "Weekly Forecast",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ),

              /// Forecast List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      return _forecastTile(weather.forecast[index], index == 0);
                    },
                    childCount: weather.forecast.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainWeatherCard(String location, DailyForecast today) {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity, // Ensures card takes full width
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF81C784)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row( // Using a Row to split the card into two sides
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// Left Side: Text Details
          Expanded( // ⬅️ THIS IS THE FIX: It prevents text from pushing the icon off screen
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Constrains the height
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Expanded( // Prevents long city names from overflowing
                      child: Text(
                        location,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "${today.tempMax.toInt()}°C",
                  style: const TextStyle(
                    fontSize: 52, // Slightly reduced to ensure fit on smaller devices
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  today.condition,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),

          /// Right Side: Weather Icon
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Image.asset(
              _getWeatherImage(today.condition),
              height: 80, // Reduced from 100 to provide more breathing room
              width: 80,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const Icon(Icons.wb_sunny, size: 70, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _forecastTile(DailyForecast daily, bool isToday) {
    DateTime parsedDate = DateTime.parse(daily.date);
    String dayName = isToday ? "Today" : DateFormat('EEE, d MMM').format(parsedDate);
    Map<String, String> advice = _getFarmerAdvice(daily.condition);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Image.asset(
          _getWeatherImage(daily.condition),
          height: 40,
          errorBuilder: (c, e, s) => const Icon(Icons.cloud_queue, color: Colors.grey),
        ),
        title: Text(
          dayName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text("${daily.tempMax.toInt()}° / ${daily.tempMin.toInt()}°"),
        trailing: const Icon(Icons.expand_more, color: Colors.grey),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                const Divider(),
                const SizedBox(height: 8),
                _adviceRow(Icons.check_circle_outline, "Action", advice['good']!, Colors.green),
                const SizedBox(height: 12),
                _adviceRow(Icons.warning_amber_rounded, "Caution", advice['bad']!, Colors.orange),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _adviceRow(IconData icon, String label, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
              children: [
                TextSpan(text: "$label: ", style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text("Sync Error", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => setState(() => _weatherFuture = _fetchRealWeather()),
            child: const Text("Retry Connection", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  String _getWeatherImage(String condition) {
    switch (condition.toLowerCase()) {
      case "sunny": case "clear": return "assets/images/weather/sunny.png";
      case "cloudy": case "clouds": return "assets/images/weather/cloudy.png";
      case "rain": case "rainy": return "assets/images/weather/rain.png";
      case "storm": case "thunderstorm": return "assets/images/weather/storm.png";
      default: return "assets/images/weather/default.png";
    }
  }
}