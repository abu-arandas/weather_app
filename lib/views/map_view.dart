import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

export 'package:latlong2/latlong.dart' show LatLng;

class MapView extends StatelessWidget {
  final LatLng initialCenter;
  final String openWeatherMapApiKey;

  const MapView({
    super.key,
    required this.initialCenter,
    required this.openWeatherMapApiKey,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showMapInfo(context),
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(initialCenter: initialCenter, initialZoom: 9.2),
        children: [
          // Base map layer
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          // Weather precipitation overlay
          TileLayer(
            urlTemplate:
                'https://tile.openweathermap.org/map/precipitation_new/{z}/{x}/{y}.png?appid={apiKey}',
            additionalOptions: {'apiKey': openWeatherMapApiKey},
          ),
          // Current location marker
          MarkerLayer(
            markers: [
              Marker(
                point: initialCenter,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMapInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map Legend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Precipitation Overlay',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildLegendItem(Colors.blue.shade100, 'Light rain'),
            _buildLegendItem(Colors.blue.shade300, 'Moderate rain'),
            _buildLegendItem(Colors.blue.shade600, 'Heavy rain'),
            _buildLegendItem(Colors.purple.shade300, 'Snow'),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    size: 12,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Current location'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
