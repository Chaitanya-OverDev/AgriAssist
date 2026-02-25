class WeatherModel {
  final String location;
  final List<DailyForecast> forecast;

  WeatherModel({
    required this.location,
    required this.forecast,
  });
}

class DailyForecast {
  final String date;
  final double tempMax;
  final double tempMin;
  final double rainMm;
  final String condition;

  DailyForecast({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.rainMm,
    required this.condition,
  });
}