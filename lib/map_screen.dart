import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong2.dart';

class MapScreen extends StatefulWidget {
  final LatLng initialCenter;
  final String openWeatherMapApiKey;
  const MapScreen({super.key, required this.initialCenter, required this.openWeatherMapApiKey});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Map'),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: widget.initialCenter,
          initialZoom: 9.2,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          TileLayer(
            urlTemplate: 'https://tile.openweathermap.org/map/precipitation_new/{z}/{x}/{y}.png?appid={apiKey}',
            additionalOptions: {
              'apiKey': widget.openWeatherMapApiKey,
            },
            backgroundColor: Colors.transparent,
            opacity: 0.5,
          ),
        ],
      ),
    );
  }
}
