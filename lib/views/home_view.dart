import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/weather_controller.dart';
import '../controllers/locations_controller.dart';
import '../models/models.dart';
import 'locations_view.dart';
import 'map_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final weatherController = Get.find<WeatherController>();
    final locationsController = Get.find<LocationsController>();
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Obx(() {
      // Loading state
      if (weatherController.loading) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Fetching weather data...',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                ),
              ],
            ),
          ),
        );
      }

      // Error state
      if (weatherController.error != null) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Oops! Something went wrong',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade300,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    weatherController.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => weatherController.callWeatherApi(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // No data state
      if (weatherController.weather == null) {
        return const Scaffold(body: SizedBox.shrink());
      }

      final weather = weatherController.weather!;
      final today = weather.forecast.first;
      final forecast = weather.forecast;

      return Scaffold(
        key: scaffoldKey,

        // App Bar
        appBar: AppBar(
          title: const Text(
            'Weather App',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: () => scaffoldKey.currentState!.openEndDrawer(),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 4),
                  Text(weather.city),
                ],
              ),
            ),
            IconButton(
              onPressed: () => weatherController.toggleUnit(),
              tooltip: weatherController.isCelsius
                  ? 'Switch to Fahrenheit'
                  : 'Switch to Celsius',
              icon: Icon(
                weatherController.isCelsius
                    ? Icons.thermostat
                    : Icons.thermostat_auto,
              ),
            ),
            IconButton(
              onPressed: () {
                Get.to(
                  () => MapView(
                    initialCenter: LatLng(weather.lat, weather.lon),
                    openWeatherMapApiKey:
                        weatherController.openWeatherMapApiKey,
                  ),
                );
              },
              tooltip: 'Weather Map',
              icon: const Icon(Icons.map),
            ),
          ],
        ),

        // Locations Drawer
        endDrawer: Drawer(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Choose Location',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Obx(
                      () => ListView.builder(
                        itemCount: locationsController.locations.length,
                        itemBuilder: (context, index) {
                          final location = locationsController.locations[index];
                          return ListTile(
                            leading: const Icon(Icons.location_city),
                            title: Text(location),
                            onTap: () =>
                                locationsController.selectLocation(location),
                          );
                        },
                      ),
                    ),
                  ),
                  const Divider(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.back();
                        Get.to(() => const LocationsView());
                      },
                      icon: const Icon(Icons.edit_location_alt),
                      label: const Text('Manage Locations'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Body with pull-to-refresh
        body: RefreshIndicator(
          onRefresh: () => weatherController.callWeatherApi(
            current: false,
            cityName: weather.city,
          ),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Alerts
                _buildAlerts(weatherController, weather.alerts),
                const SizedBox(height: 25),

                // Weather Image
                Hero(
                  tag: 'weather_icon',
                  child: Image.asset(
                    weatherController.getWeatherImage(weather.description),
                    height: 150,
                    width: 150,
                    fit: BoxFit.fill,
                  ),
                ),
                const SizedBox(height: 16),

                // Temperature
                Text(
                  '${weather.temperature.toStringAsFixed(0)} ${weatherController.isCelsius ? '°C' : '°F'}',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  weather.description,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade300,
                  ),
                ),
                const SizedBox(height: 24),

                // Weather Details Card
                _buildWeatherDetailsCard(weatherController, weather),
                const SizedBox(height: 16),

                // Air Quality Card
                _buildAirQualityCard(weatherController, weather),
                const SizedBox(height: 24),

                // 24h Forecast
                _build24HourForecast(weatherController, today),

                // 7 Days Forecast
                _build7DayForecast(weatherController, forecast),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildAlerts(WeatherController controller, List<Alert> alerts) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '⚠️ Severe Weather Alerts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ...alerts.map(
            (alert) => Card(
              color: controller.getAlertColor(alert.severity),
              child: ListTile(
                title: Text(
                  alert.event,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(alert.headline),
                onTap: () => _showAlertDialog(alert),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAlertDialog(Alert alert) {
    Get.dialog(
      AlertDialog(
        title: Text(alert.event),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                alert.headline,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Severity: ${alert.severity}'),
              const SizedBox(height: 16),
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(alert.desc),
              if (alert.instruction.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Instruction:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(alert.instruction),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildWeatherDetailsCard(
    WeatherController controller,
    Weather weather,
  ) {
    final unit = controller.isCelsius ? '°C' : '°F';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDetailItem(
                  Icons.thermostat_outlined,
                  'Feels Like',
                  '${weather.feelsLike.toStringAsFixed(0)} $unit',
                ),
                _buildDetailItem(
                  Icons.water_drop_outlined,
                  'Humidity',
                  '${weather.humidity}%',
                ),
                _buildDetailItem(
                  Icons.air,
                  'Wind',
                  '${weather.windSpeedMs.toStringAsFixed(1)} m/s',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDetailItem(
                  Icons.wb_sunny_outlined,
                  'UV Index',
                  weather.uv.toStringAsFixed(0),
                ),
                _buildDetailItem(
                  Icons.speed,
                  'Pressure',
                  '${weather.pressure.toStringAsFixed(0)} hPa',
                ),
                _buildDetailItem(
                  Icons.visibility,
                  'Visibility',
                  '${weather.visibility.toStringAsFixed(0)} km',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.blue.shade300),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildAirQualityCard(WeatherController controller, Weather weather) {
    final aqi = weather.airQuality.usEpaIndex;
    final aqiString = controller.getAqiString(aqi);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getAqiColor(aqi),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                aqi.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Air Quality Index',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    aqiString,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAqiColor(int aqi) {
    switch (aqi) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.yellow.shade700;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      case 6:
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  Widget _build24HourForecast(WeatherController controller, Forecast today) {
    return ExpansionTile(
      title: const Text(
        '24 Hour Forecast',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      initiallyExpanded: true,
      children: [
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: today.hours.length,
            itemBuilder: (context, index) {
              final hour = today.hours[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        controller.getWeatherImage(hour.description),
                        height: 40,
                        width: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${hour.temperature.toStringAsFixed(0)} ${controller.isCelsius ? '°C' : '°F'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('hh a').format(hour.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _build7DayForecast(
    WeatherController controller,
    List<Forecast> forecast,
  ) {
    return ExpansionTile(
      title: const Text(
        '7 Day Forecast',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      initiallyExpanded: true,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: forecast.length,
          itemBuilder: (context, index) {
            final day = forecast[index];
            return Card(
              child: ListTile(
                onTap: () => _showForecastDetails(controller, day),
                leading: Image.asset(
                  controller.getWeatherImage(day.description),
                  width: 50,
                  height: 50,
                ),
                title: Text(
                  '${day.avgTemperature.toStringAsFixed(0)} ${controller.isCelsius ? '°C' : '°F'}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.arrow_downward,
                          size: 12,
                          color: Colors.blue.shade300,
                        ),
                        Text(
                          ' ${day.minTemperature.toStringAsFixed(0)}°',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_upward,
                          size: 12,
                          color: Colors.red.shade300,
                        ),
                        Text(
                          ' ${day.maxTemperature.toStringAsFixed(0)}°',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    Text(
                      day.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                trailing: Text(
                  DateFormat('EEE\nd').format(day.date),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showForecastDetails(WeatherController controller, Forecast forecast) {
    final unit = controller.isCelsius ? '°C' : '°F';

    Get.dialog(
      AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),
              Image.asset(
                controller.getWeatherImage(forecast.description),
                height: 100,
                width: 100,
              ),
              const SizedBox(height: 16),
              Text(
                '${forecast.avgTemperature.toStringAsFixed(0)} $unit',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(forecast.description, style: const TextStyle(fontSize: 18)),
              Text(
                DateFormat('EEEE, MMMM d').format(forecast.date),
                style: TextStyle(color: Colors.grey.shade400),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDetailItem(
                      Icons.arrow_downward,
                      'Min',
                      '${forecast.minTemperature.toStringAsFixed(0)} $unit',
                    ),
                    _buildDetailItem(
                      Icons.arrow_upward,
                      'Max',
                      '${forecast.maxTemperature.toStringAsFixed(0)} $unit',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDetailItem(
                      Icons.water_drop,
                      'Humidity',
                      '${forecast.humidity}%',
                    ),
                    _buildDetailItem(
                      Icons.air,
                      'Wind',
                      '${forecast.maxWindMs.toStringAsFixed(1)} m/s',
                    ),
                    _buildDetailItem(
                      Icons.wb_sunny,
                      'UV',
                      forecast.uv.toStringAsFixed(0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Astro info
              ListTile(
                leading: const Icon(
                  Icons.wb_sunny_outlined,
                  color: Colors.orange,
                ),
                title: const Text('Sunrise / Sunset'),
                subtitle: Text('${forecast.sunrise} - ${forecast.sunset}'),
              ),
              ListTile(
                leading: const Icon(Icons.nightlight_round, color: Colors.blue),
                title: const Text('Moonrise / Moonset'),
                subtitle: Text('${forecast.moonrise} - ${forecast.moonset}'),
              ),
              ListTile(
                leading: const Icon(Icons.brightness_3),
                title: const Text('Moon Phase'),
                subtitle: Text(forecast.moonPhase),
              ),

              // Hourly forecast
              const Padding(
                padding: EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Hourly Forecast',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: forecast.hours.length,
                  itemBuilder: (context, index) {
                    final hour = forecast.hours[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              controller.getWeatherImage(hour.description),
                              height: 36,
                              width: 36,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${hour.temperature.toStringAsFixed(0)} $unit',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat('hh a').format(hour.date),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }
}
