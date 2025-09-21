import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:geocoding/geocoding.dart';

import 'models.dart';

import 'package:shared_preferences/shared_preferences.dart';

class WeatherProvider with ChangeNotifier {
  // In a real app, these keys would not be hardcoded. They would be loaded
  // from a secure location, such as environment variables.
  // Due to limitations in this environment, we are hardcoding them for now.
  String weatherApiKey = "0f2486c3a5b7442ba20200510242203";
  String openWeatherMapApiKey = "0f2486c3a5b7442ba20200510242203"; // User provided the same key for both

  Weather? _weather;
  Weather? get weather => _weather;
  bool _loading = false;
  bool get loading => _loading;
  String? _error;
  String? get error => _error;
  bool _isCelsius = true;
  bool get isCelsius => _isCelsius;

  WeatherProvider() {
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isCelsius = prefs.getBool('isCelsius') ?? true;
    notifyListeners();
  }

  Future<void> toggleUnit() async {
    _isCelsius = !_isCelsius;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCelsius', _isCelsius);
    notifyListeners();
  }

  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    while (!serviceEnabled) {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    }

    permission = await Geolocator.checkPermission();
    while (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.best),
    );
  }

  Future<void> callWeatherAPi({bool current = true, String? cityName}) async {
    _loading = true;
    _error = null;
     WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      Position? currentPosition;
      if (current) {
        currentPosition = await getCurrentPosition();
        List<Placemark> placemarks = await placemarkFromCoordinates(
          currentPosition.latitude,
          currentPosition.longitude,
        );
        Placemark place = placemarks[0];
        cityName = place.locality!;
      }

      final Response response = await get(
        Uri.parse('https://api.weatherapi.com/v1/forecast.json?key=$weatherApiKey&q=$cityName&days=7&aqi=yes&alerts=yes'),
      );

      final Map<String, dynamic> decodedJson = json.decode(response.body);
      _weather = Weather.fromJson(decodedJson, _isCelsius);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String getWeatherImage(String input) {
    String weather = input.toLowerCase();
    String assetPath = 'images/';

    switch (weather) {
      case 'thunderstorm':
        return '${assetPath}Storm.png';

      case 'drizzle':
      case 'rain':
        return '${assetPath}Rainy.png';

      case 'snow':
        return '${assetPath}Snow.png';

      case 'clear':
        return '${assetPath}Sunny.png';

      case 'clouds':
        return '${assetPath}Cloudy.png';

      case 'mist':
      case 'fog':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'sand':
      case 'ash':
        return '${assetPath}Fog.png';

      case 'squall':
      case 'tornado':
        return '${assetPath}StormWindy.png';

      default:
        return '${assetPath}Cloud.png';
    }
  }
}
