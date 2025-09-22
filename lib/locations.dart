import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'provider.dart';

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationsProvider with ChangeNotifier {
  List<String> _locations = [];
  List<String> get locations => _locations;

  Future<void> loadLocations() async {
    final prefs = await SharedPreferences.getInstance();
    _locations = prefs.getStringList('locations') ?? [];
    notifyListeners();
  }

  Future<void> addLocation(String cityName) async {
    if (!_locations.contains(cityName)) {
      _locations.add(cityName);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('locations', _locations);
      notifyListeners();
    }
  }

  Future<List<String>> searchCities(String query) async {
    if (query.isEmpty) {
      return [];
    }

    final weatherProvider = WeatherProvider();
    final apiKey = weatherProvider.weatherApiKey;
    final url = 'https://api.weatherapi.com/v1/search.json?key=$apiKey&q=$query';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((location) {
          final name = location['name'];
          final region = location['region'];
          final country = location['country'];
          return '$name, $region, $country';
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<void> addLocationAndFetchWeather(String cityName) async {
    try {
      await WeatherProvider().callWeatherAPi(current: false, cityName: cityName);
      await addLocation(cityName);
    } catch (e) {
      throw Exception('City not found');
    }
  }

  Future<void> deleteLocation(String cityName) async {
    _locations.remove(cityName);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('locations', _locations);
    notifyListeners();
  }
}

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  final _locationsProvider = LocationsProvider();
  final _searchController = TextEditingController();
  List<String> _searchResults = [];
  Timer? _debounce;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _locationsProvider.loadLocations();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (_searchController.text.isNotEmpty) {
        setState(() {
          _isSearching = true;
        });
        final results = await _locationsProvider.searchCities(_searchController.text);
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _searchResults = [];
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Locations')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search for a city',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchController.text.isNotEmpty
                    ? ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final location = _searchResults[index];
                          return ListTile(
                            title: Text(location),
                            onTap: () {
                              _locationsProvider.addLocationAndFetchWeather(location);
                              _searchController.clear();
                              Navigator.pop(context);
                            },
                          );
                        },
                      )
                    : AnimatedBuilder(
                        animation: _locationsProvider,
                        builder: (context, child) {
                          return ListView.builder(
                            itemCount: _locationsProvider.locations.length,
                            itemBuilder: (context, index) {
                              final location = _locationsProvider.locations[index];
                              return ListTile(
                                title: Text(location),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    _locationsProvider.deleteLocation(location);
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
