import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/weather_model.dart';

class WeatherService {
  static const String _apiKey = "YOUR_API_KEY_HERE";

  Future<List<WeatherModel>> fetchWeather(
      double lat, double lon) async {
    final url =
        "https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception("Failed to load weather data");
    }

    final data = json.decode(response.body);

    final List list = data['list'];

    // Group by day (OpenWeather gives 3hr data)
    Map<String, dynamic> dailyMap = {};

    for (var item in list) {
      final date =
      DateTime.parse(item['dt_txt']);
      final day = DateFormat('EEEE').format(date);

      if (!dailyMap.containsKey(day)) {
        dailyMap[day] = item;
      }
    }

    List<WeatherModel> result = [];

    dailyMap.forEach((day, item) {
      result.add(
        WeatherModel(
          day: day,
          temperature: item['main']['temp'].toDouble(),
          description: item['weather'][0]['main'],
          icon: item['weather'][0]['icon'],
        ),
      );
    });

    return result.take(6).toList(); // Today + 5 days
  }
}