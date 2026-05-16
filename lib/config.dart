class AppConfig {
  AppConfig._();

  static String get weatherApiKey =>
      const String.fromEnvironment('WEATHER_API_KEY');

  static String get openWeatherMapApiKey =>
      const String.fromEnvironment('OPENWEATHERMAP_API_KEY');
}
