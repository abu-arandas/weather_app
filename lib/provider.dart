import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:geocoding/geocoding.dart';

import 'models.dart';

class AppProvider {
  String apiKey = '0f2486c3a5b7442ba20200510242203';

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
      desiredAccuracy: LocationAccuracy.best,
    );
  }

  Future<Weather> callWeatherAPi(
      {required bool current, String? cityName}) async {
    Position currentPosition = await getCurrentPosition();

    if (current) {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          currentPosition.latitude, currentPosition.longitude);

      Placemark place = placemarks[0];
      cityName = place.locality!;
    }

    final Response response = await get(Uri.parse(
      'https://api.weatherapi.com/v1/forecast.json?key=0f2486c3a5b7442ba20200510242203&q=$cityName&days=7',
    ));

    final Map<String, dynamic> decodedJson = json.decode(response.body);

    return Weather.fromJson(decodedJson);
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
