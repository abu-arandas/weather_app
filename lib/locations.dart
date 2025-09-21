import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'provider.dart';

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

  Future<void> searchLocation(String cityName) async {
    try {
      await AppProvider().callWeatherAPi(current: false, cityName: cityName);
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

  @override
  void initState() {
    super.initState();
    _locationsProvider.loadLocations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Locations'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for a city',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    try {
                      await _locationsProvider
                          .searchLocation(_searchController.text);
                      _searchController.clear();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
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
