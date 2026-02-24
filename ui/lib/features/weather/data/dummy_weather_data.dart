import '../models/weather_model.dart';

class DummyWeatherData {
  static List<WeatherModel> getForecast() {
    return [
      WeatherModel(
        day: "Today",
        temperature: 29,
        description: "Sunny",
      ),
      WeatherModel(
        day: "Monday",
        temperature: 27,
        description: "Cloudy",
      ),
      WeatherModel(
        day: "Tuesday",
        temperature: 25,
        description: "Rain",
      ),
      WeatherModel(
        day: "Wednesday",
        temperature: 30,
        description: "Sunny",
      ),
      WeatherModel(
        day: "Thursday",
        temperature: 26,
        description: "Cloudy",
      ),
      WeatherModel(
        day: "Friday",
        temperature: 24,
        description: "Rain",
      ),
    ];
  }
}