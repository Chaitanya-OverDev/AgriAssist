import '../models/weather_model.dart';

class DummyWeatherData {
  static Future<WeatherModel> getForecast() async {
    // Simulate a tiny network delay for a smooth UI transition
    await Future.delayed(const Duration(milliseconds: 300));

    return WeatherModel(
      location: "Buldhana, Maharashtra",
      forecast: [
        DailyForecast(date: "2026-02-25", tempMax: 30.9, tempMin: 25.8, rainMm: 0.0, condition: "Cloudy"),
        DailyForecast(date: "2026-02-26", tempMax: 34.2, tempMin: 23.8, rainMm: 0.0, condition: "Sunny"),
        DailyForecast(date: "2026-02-27", tempMax: 34.3, tempMin: 22.2, rainMm: 0.0, condition: "Sunny"),
        DailyForecast(date: "2026-02-28", tempMax: 34.9, tempMin: 22.5, rainMm: 0.0, condition: "Sunny"),
        DailyForecast(date: "2026-03-01", tempMax: 35.9, tempMin: 23.6, rainMm: 0.0, condition: "Sunny"),
      ],
    );
  }
}