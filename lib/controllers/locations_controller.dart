import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'weather_controller.dart';

/// LocationsController - GetX controller for managing saved locations
class LocationsController extends GetxController {
  final RxList<String> _locations = <String>[].obs;
  final RxList<String> _searchResults = <String>[].obs;
  final RxBool _isSearching = false.obs;
  final RxString _searchQuery = ''.obs;

  // Debounce worker
  Worker? _debounceWorker;

  // Getters
  List<String> get locations => _locations;
  List<String> get searchResults => _searchResults;
  bool get isSearching => _isSearching.value;
  String get searchQuery => _searchQuery.value;

  @override
  void onInit() {
    super.onInit();
    loadLocations();

    // Setup debounce for search
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

  /// Load saved locations from SharedPreferences
  Future<void> loadLocations() async {
    final prefs = await SharedPreferences.getInstance();
    _locations.value = prefs.getStringList('locations') ?? [];
  }

  /// Update search query (triggers debounced search)
  void updateSearchQuery(String query) {
    _searchQuery.value = query;
    if (query.isEmpty) {
      _searchResults.clear();
    }
  }

  /// Clear search results
  void clearSearch() {
    _searchQuery.value = '';
    _searchResults.clear();
  }

  /// Perform city search
  Future<void> _performSearch() async {
    if (_searchQuery.value.isEmpty) {
      _searchResults.clear();
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
      } else {
        _searchResults.clear();
      }
    } catch (e) {
      _searchResults.clear();
    } finally {
      _isSearching.value = false;
    }
  }

  /// Add a new location
  Future<void> addLocation(String cityName) async {
    if (!_locations.contains(cityName)) {
      _locations.add(cityName);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('locations', _locations);
    }
  }

  /// Add location and fetch its weather
  Future<void> addLocationAndFetchWeather(String cityName) async {
    try {
      final weatherController = Get.find<WeatherController>();
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

  /// Delete a location
  Future<void> deleteLocation(String cityName) async {
    _locations.remove(cityName);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('locations', _locations);
  }

  /// Select a location and fetch weather
  void selectLocation(String cityName) {
    final weatherController = Get.find<WeatherController>();
    weatherController.callWeatherApi(current: false, cityName: cityName);
    Get.back(); // Close drawer
  }
}
