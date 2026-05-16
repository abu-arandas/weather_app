import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/models.dart';

class WeatherController extends GetxController {
  final String weatherApiKey = AppConfig.weatherApiKey;
  final String openWeatherMapApiKey = AppConfig.openWeatherMapApiKey;

  final Rx<Weather?> _weather = Rx<Weather?>(null);
  final RxBool _loading = false.obs;
  final RxnString _error = RxnString();
  final RxBool _isCelsius = true.obs;

  Weather? get weather => _weather.value;
  bool get loading => _loading.value;
  String? get error => _error.value;
  bool get isCelsius => _isCelsius.value;

  @override
  void onInit() {
    super.onInit();
    _loadPreferences();
    _loadCachedWeather();
    callWeatherApi();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isCelsius.value = prefs.getBool('isCelsius') ?? true;
    } catch (_) {}
  }

  Future<void> _loadCachedWeather() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_weather');
      if (cached != null) {
        final json = jsonDecode(cached) as Map<String, dynamic>;
        _weather.value = Weather.fromJson(json, _isCelsius.value);
      }
    } catch (_) {}
  }

  Future<void> _cacheWeather(Map<String, dynamic> json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_weather', jsonEncode(json));
    } catch (_) {}
  }

  Future<void> toggleUnit() async {
    _isCelsius.value = !_isCelsius.value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isCelsius', _isCelsius.value);
    } catch (_) {}

    if (weather != null) {
      callWeatherApi(current: false, cityName: weather!.city);
    }
  }

  Future<Position> getCurrentPosition() async {
    const timeout = Duration(seconds: 30);
    final deadline = DateTime.now().add(timeout);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    while (!serviceEnabled) {
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException('Location service enablement timed out');
      }
      await Future.delayed(const Duration(seconds: 1));
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    while (permission == LocationPermission.denied) {
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException('Location permission request timed out');
      }
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied. Please enable them in settings.');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    );
  }

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

      if (response.statusCode != 200) {
        throw Exception(
            'Weather API error: ${response.statusCode} ${response.body}');
      }

      final Map<String, dynamic> decodedJson = json.decode(response.body);
      _weather.value = Weather.fromJson(decodedJson, _isCelsius.value);
      _cacheWeather(decodedJson);
    } catch (e) {
      _error.value = e.toString();
      if (_weather.value == null) {
        _loadCachedWeather();
      }
    } finally {
      _loading.value = false;
    }
  }

  String getWeatherImage(String input) {
    final weather = input.toLowerCase();

    if (weather.contains('sunny') || weather.contains('clear')) {
      return 'images/Sunny.png';
    }
    if (weather.contains('cloudy') ||
        weather.contains('overcast') ||
        weather.contains('cloud')) {
      return 'images/Cloudy.png';
    }
    if (weather.contains('thunder') ||
        weather.contains('storm') && !weather.contains('snow')) {
      return 'images/Storm.png';
    }
    if (weather.contains('drizzle') || weather.contains('rain')) {
      return 'images/Rainy.png';
    }
    if (weather.contains('snow') ||
        weather.contains('blizzard') ||
        weather.contains('ice') ||
        weather.contains('sleet')) {
      return 'images/Snow.png';
    }
    if (weather.contains('mist') ||
        weather.contains('fog') ||
        weather.contains('haze') ||
        weather.contains('smoke') ||
        weather.contains('dust') ||
        weather.contains('sand') ||
        weather.contains('ash')) {
      return 'images/Fog.png';
    }
    if (weather.contains('squall') || weather.contains('tornado')) {
      return 'images/StormWindy.png';
    }

    return 'images/Cloud.png';
  }

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
