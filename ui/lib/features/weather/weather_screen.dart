import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/location_service.dart';
import 'package:agriassist/services/api_service.dart';
import 'package:agriassist/l10n/app_localizations.dart';
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

  Future<WeatherModel> _fetchRealWeather() async {

    try {

      Position position =
      await _locationService.getCurrentLocation();

      bool locationUpdated =
      await ApiService.updateUserLocation(
        position.latitude,
        position.longitude,
      );

      if (!locationUpdated) {
        throw Exception("Failed to sync location with server.");
      }

      final weatherData =
      await ApiService.getWeatherForecast();

      if (weatherData == null ||
          !weatherData.containsKey('forecast')) {
        throw Exception("Failed to load weather data.");
      }

      List<DailyForecast> parsedForecast =
      (weatherData['forecast'] as List).map((item) {

        return DailyForecast(
          date: item['date'],
          tempMax: (item['temp_max'] as num).toDouble(),
          tempMin: (item['temp_min'] as num).toDouble(),
          rainMm: (item['rain_mm'] as num).toDouble(),
          condition: item['condition'],
        );

      }).toList();

      return WeatherModel(
        location: weatherData['location'] ??
            "Unknown Location",
        forecast: parsedForecast,
      );

    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Map<String, String> _getFarmerAdvice(
      String condition,
      BuildContext context) {

    final t = AppLocalizations.of(context)!;

    String cond = condition.toLowerCase();

    if (cond.contains('sun') || cond.contains('clear')) {
      return {
        'good': t.adviceSunnyGood,
        'bad': t.adviceSunnyBad
      };
    }

    else if (cond.contains('cloud')) {
      return {
        'good': t.adviceCloudGood,
        'bad': t.adviceCloudBad
      };
    }

    else if (cond.contains('rain')) {
      return {
        'good': t.adviceRainGood,
        'bad': t.adviceRainBad
      };
    }

    else if (cond.contains('storm') ||
        cond.contains('thunder')) {
      return {
        'good': t.adviceStormGood,
        'bad': t.adviceStormBad
      };
    }

    return {
      'good': t.adviceDefaultGood,
      'bad': t.adviceDefaultBad
    };
  }

  @override
  Widget build(BuildContext context) {

    final t = AppLocalizations.of(context)!;

    return Scaffold(

      backgroundColor: const Color(0xFFF4F7F5),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,

        leading: IconButton(
          icon: const Icon(Icons.chevron_left,
              color: Colors.black87,
              size: 30),
          onPressed: () => Navigator.pop(context),
        ),

        title: Text(
          t.agriWeather,
          style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w800,
              letterSpacing: 1),
        ),

        centerTitle: true,
      ),

      body: FutureBuilder<WeatherModel>(
        future: _weatherFuture,

        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {

            return const Center(
                child: CircularProgressIndicator(
                    color: Colors.green));
          }

          if (snapshot.hasError) {
            return _buildErrorState(
                snapshot.error.toString(),
                context);
          }

          if (!snapshot.hasData ||
              snapshot.data!.forecast.isEmpty) {

            return Center(
              child: Text(t.noWeatherData),
            );
          }

          final weather = snapshot.data!;
          final today = weather.forecast.first;

          return CustomScrollView(
            physics:
            const BouncingScrollPhysics(),

            slivers: [

              SliverToBoxAdapter(
                child: Padding(
                  padding:
                  const EdgeInsets.all(20),

                  child: _buildMainWeatherCard(
                      weather.location,
                      today),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8),

                  child: Text(
                    t.weeklyForecast,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              SliverPadding(
                padding:
                const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10),

                sliver: SliverList(

                  delegate:
                  SliverChildBuilderDelegate(
                        (context, index) {

                      return _forecastTile(
                          weather.forecast[index],
                          index == 0);
                    },

                    childCount:
                    weather.forecast.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainWeatherCard(
      String location,
      DailyForecast today) {

    return Container(

      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(

        gradient: const LinearGradient(
          colors: [
            Color(0xFF2E7D32),
            Color(0xFF81C784)
          ],
        ),

        borderRadius:
        BorderRadius.circular(32),
      ),

      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,

        children: [

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Row(
                  children: [

                    const Icon(
                        Icons.location_on,
                        color: Colors.white70,
                        size: 14),

                    const SizedBox(width: 4),

                    Expanded(
                      child: Text(
                        location,
                        overflow:
                        TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  "${today.tempMax.toInt()}°C",

                  style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),

                Text(
                  today.condition,
                  style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70),
                ),
              ],
            ),
          ),

          Image.asset(
            _getWeatherImage(
                today.condition),

            height: 80,
            width: 80,

            errorBuilder:
                (c, e, s) =>
            const Icon(
                Icons.wb_sunny,
                size: 70,
                color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _forecastTile(
      DailyForecast daily,
      bool isToday) {

    final t = AppLocalizations.of(context)!;

    DateTime parsedDate =
    DateTime.parse(daily.date);

    String dayName = isToday
        ? t.today
        : DateFormat('EEE, d MMM')
        .format(parsedDate);

    Map<String, String> advice =
    _getFarmerAdvice(
        daily.condition,
        context);

    return Container(

      margin:
      const EdgeInsets.only(bottom: 16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(24),
      ),

      child: ExpansionTile(

        tilePadding:
        const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8),

        leading: Image.asset(
          _getWeatherImage(
              daily.condition),

          height: 40,
        ),

        title: Text(
          dayName,
          style: const TextStyle(
              fontWeight:
              FontWeight.bold),
        ),

        subtitle: Text(
            "${daily.tempMax.toInt()}° / ${daily.tempMin.toInt()}°"),

        trailing: const Icon(
            Icons.expand_more),

        children: [

          Padding(
            padding:
            const EdgeInsets.fromLTRB(
                20, 0, 20, 20),

            child: Column(
              children: [

                const Divider(),

                const SizedBox(height: 8),

                _adviceRow(
                    Icons.check_circle_outline,
                    t.action,
                    advice['good']!,
                    Colors.green),

                const SizedBox(height: 12),

                _adviceRow(
                    Icons.warning_amber_rounded,
                    t.caution,
                    advice['bad']!,
                    Colors.orange),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _adviceRow(
      IconData icon,
      String label,
      String text,
      Color color) {

    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [

        Icon(icon,
            color: color,
            size: 20),

        const SizedBox(width: 10),

        Expanded(
          child: RichText(

            text: TextSpan(

              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4),

              children: [

                TextSpan(
                    text: "$label: ",
                    style: TextStyle(
                        fontWeight:
                        FontWeight.bold,
                        color: color)),

                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(
      String error,
      BuildContext context) {

    final t = AppLocalizations.of(context)!;

    return Center(

      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,

        children: [

          const Icon(Icons.cloud_off,
              size: 80,
              color: Colors.grey),

          const SizedBox(height: 16),

          Text(
            t.syncError,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),

          Padding(
            padding:
            const EdgeInsets.all(20),

            child: Text(
              error,
              textAlign: TextAlign.center,
            ),
          ),

          ElevatedButton(

            onPressed: () {

              setState(() {
                _weatherFuture =
                    _fetchRealWeather();
              });
            },

            child: Text(
                t.retryConnection),
          )
        ],
      ),
    );
  }

  String _getWeatherImage(
      String condition) {

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
        return "assets/images/weather/default.png";
    }
  }
}