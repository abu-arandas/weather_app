import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// WeatherController - GetX controller for weather state management
class WeatherController extends GetxController {
  // API Keys - In production, load from secure storage
  final String weatherApiKey = "0f2486c3a5b7442ba20200510242203";
  final String openWeatherMapApiKey = "0f2486c3a5b7442ba20200510242203";

  // Reactive state variables
  final Rx<Weather?> _weather = Rx<Weather?>(null);
  final RxBool _loading = false.obs;
  final RxnString _error = RxnString();
  final RxBool _isCelsius = true.obs;

  // Getters
  Weather? get weather => _weather.value;
  bool get loading => _loading.value;
  String? get error => _error.value;
  bool get isCelsius => _isCelsius.value;

  @override
  void onInit() {
    super.onInit();
    _loadPreferences();
    callWeatherApi();
  }

  /// Load user preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isCelsius.value = prefs.getBool('isCelsius') ?? true;
  }

  /// Toggle temperature unit between Celsius and Fahrenheit
  Future<void> toggleUnit() async {
    _isCelsius.value = !_isCelsius.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCelsius', _isCelsius.value);

    // Re-fetch weather to update temperatures
    if (weather != null) {
      callWeatherApi(current: false, cityName: weather!.city);
    }
  }

  /// Get current device position
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
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    );
  }

  /// Fetch weather data from API
  Future<void> callWeatherApi({bool current = true, String? cityName}) async {
    _loading.value = true;
    _error.value = null;

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

      final http.Response response = await http.get(
        Uri.parse(
          'https://api.weatherapi.com/v1/forecast.json?key=$weatherApiKey&q=$cityName&days=7&aqi=yes&alerts=yes',
        ),
      );

      final Map<String, dynamic> decodedJson = json.decode(response.body);
      _weather.value = Weather.fromJson(decodedJson, _isCelsius.value);
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _loading.value = false;
    }
  }

  /// Get weather image asset path based on weather description
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

  /// Get AQI description string
  String getAqiString(int index) {
    switch (index) {
      case 1:
        return 'Good';
      case 2:
        return 'Moderate';
      case 3:
        return 'Unhealthy for sensitive groups';
      case 4:
        return 'Unhealthy';
      case 5:
        return 'Very Unhealthy';
      case 6:
        return 'Hazardous';
      default:
        return 'Unknown';
    }
  }

  /// Get alert color based on severity
  Color getAlertColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'extreme':
        return Colors.red.shade400;
      case 'severe':
        return Colors.orange.shade400;
      case 'moderate':
        return Colors.yellow.shade400;
      default:
        return Colors.blueGrey.shade400;
    }
  }
}
