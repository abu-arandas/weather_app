class Weather {
  String city;
  double temperature;
  double feelsLike;
  String description;
  int humidity;
  double windSpeed;
  List<Forecast> forecast;

  Weather({
    required this.city,
    required this.temperature,
    required this.feelsLike,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.forecast,
  });

  factory Weather.fromJson(Map<String, dynamic> json) => Weather(
        city: json['location']['name'],
        temperature: (json['current']['temp_c']).toDouble(),
        feelsLike: (json['current']['feelslike_c']).toDouble(),
        description: json['current']['condition']['text'],
        humidity: json['current']['humidity'],
        windSpeed: (json['current']['wind_mph']).toDouble(),
        forecast: List.generate(
          json['forecast']['forecastday'].length,
          (index) => Forecast.fromJson(json['forecast']['forecastday'][index]),
        ),
      );
}

class Forecast {
  DateTime date;
  double maxTemperature, minTemperature, avgTemperature, maxWind;
  int humidity;
  bool hasRain, hasSnow;
  String description;
  String sunrise, sunset, moonrise, moonset, moonPhase;
  List<Hour> hours;

  Forecast({
    required this.date,
    required this.maxTemperature,
    required this.minTemperature,
    required this.avgTemperature,
    required this.maxWind,
    required this.humidity,
    required this.hasRain,
    required this.hasSnow,
    required this.description,
    required this.sunrise,
    required this.sunset,
    required this.moonrise,
    required this.moonset,
    required this.moonPhase,
    required this.hours,
  });

  factory Forecast.fromJson(Map<String, dynamic> json) => Forecast(
        date: DateTime.parse(json['date']),
        maxTemperature: (json['day']['maxtemp_c']).toDouble(),
        minTemperature: (json['day']['mintemp_c']).toDouble(),
        avgTemperature: (json['day']['avgtemp_c']).toDouble(),
        maxWind: (json['day']['maxwind_mph']).toDouble(),
        humidity: json['day']['avghumidity'],
        hasRain: json['day']['daily_chance_of_rain'] == 0 ? false : true,
        hasSnow: json['day']['daily_chance_of_snow'] == 0 ? false : true,
        description: json['day']['condition']['text'],
        sunrise: json['astro']['sunrise'],
        sunset: json['astro']['sunset'],
        moonrise: json['astro']['moonrise'],
        moonset: json['astro']['moonset'],
        moonPhase: json['astro']['moon_phase'],
        hours: List.generate(
          json['hour'].length,
          (index) => Hour.fromJson(json['hour'][index]),
        ),
      );
}

class Hour {
  DateTime date;
  double temperature;
  String description;
  int humidity;

  Hour({
    required this.date,
    required this.temperature,
    required this.description,
    required this.humidity,
  });

  factory Hour.fromJson(Map<String, dynamic> json) => Hour(
        date: DateTime.parse(json['time']),
        temperature: (json['temp_c']).toDouble(),
        description: json['condition']['text'],
        humidity: json['humidity'],
      );
}
