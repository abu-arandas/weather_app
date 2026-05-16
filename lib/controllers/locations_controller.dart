import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'weather_controller.dart';

class LocationsController extends GetxController {
  final RxList<String> _locations = <String>[].obs;
  final RxList<String> _searchResults = <String>[].obs;
  final RxList<String> _searchCityNames = <String>[].obs;
  final RxBool _isSearching = false.obs;
  final RxString _searchQuery = ''.obs;

  Worker? _debounceWorker;

  List<String> get locations => _locations;
  List<String> get searchResults => _searchResults;
  List<String> get searchCityNames => _searchCityNames;
  bool get isSearching => _isSearching.value;
  String get searchQuery => _searchQuery.value;

  @override
  void onInit() {
    super.onInit();
    loadLocations();

    _debounceWorker = debounce(
      _searchQuery,
      (_) => _performSearch(),
      time: const Duration(milliseconds: 500),
    );
  }

  @override
  void onClose() {
    _debounceWorker?.dispose();
    super.onClose();
  }

  Future<void> loadLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _locations.value = prefs.getStringList('locations') ?? [];
    } catch (_) {}
  }

  void updateSearchQuery(String query) {
    _searchQuery.value = query;
    if (query.isEmpty) {
      _searchResults.clear();
      _searchCityNames.clear();
    }
  }

  void clearSearch() {
    _searchQuery.value = '';
    _searchResults.clear();
    _searchCityNames.clear();
  }

  Future<void> _performSearch() async {
    if (_searchQuery.value.isEmpty) {
      _searchResults.clear();
      _searchCityNames.clear();
      return;
    }

    _isSearching.value = true;

    try {
      final weatherController = Get.find<WeatherController>();
      final apiKey = weatherController.weatherApiKey;
      final url =
          'https://api.weatherapi.com/v1/search.json?key=$apiKey&q=${_searchQuery.value}';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _searchResults.value = data.map((location) {
          final name = location['name'];
          final region = location['region'];
          final country = location['country'];
          return '$name, $region, $country';
        }).toList();
        _searchCityNames.value =
            data.map((location) => location['name'] as String).toList();
      } else {
        _searchResults.clear();
        _searchCityNames.clear();
      }
    } catch (e) {
      _searchResults.clear();
      _searchCityNames.clear();
    } finally {
      _isSearching.value = false;
    }
  }

  Future<void> addLocation(String cityName) async {
    if (!_locations.contains(cityName)) {
      _locations.add(cityName);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('locations', _locations);
      } catch (_) {}
    }
  }

  Future<void> addLocationAndFetchWeather(String displayName) async {
    try {
      final weatherController = Get.find<WeatherController>();
      final idx = _searchResults.indexOf(displayName);
      final cityName = idx >= 0 ? _searchCityNames[idx] : displayName;

      await weatherController.callWeatherApi(
        current: false,
        cityName: cityName,
      );
      await addLocation(cityName);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add location: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> deleteLocation(String cityName) async {
    _locations.remove(cityName);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('locations', _locations);
    } catch (_) {}
  }

  void selectLocation(String cityName) {
    final weatherController = Get.find<WeatherController>();
    weatherController.callWeatherApi(current: false, cityName: cityName);
    Get.back();
  }
}
