class WeatherModel {
  final String location;
  final int todayTemp;
  final String todayCondition;
  final List<DailyForecast> forecast;

  WeatherModel({
    required this.location,
    required this.todayTemp,
    required this.todayCondition,
    required this.forecast,
  });
}

class DailyForecast {
  final String day;
  final int temp;
  final String condition;

  DailyForecast({
    required this.day,
    required this.temp,
    required this.condition,
  });
}