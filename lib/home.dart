import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:weather_app/map_screen.dart';

import 'provider.dart';
import 'models.dart';
import 'locations.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  ScrollController scrollController = ScrollController();
  final _locationsProvider = LocationsProvider();

  @override
  void initState() {
    super.initState();
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    weatherProvider.callWeatherAPi();
    _locationsProvider.loadLocations();
  }

  String _getAqiString(int index) {
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

  Widget _buildAlerts(List<Alert> alerts) {
    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Severe Weather Alerts',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ...alerts.map((alert) {
            return Card(
              color: _getAlertColor(alert.severity),
              child: ListTile(
                title: Text(alert.event, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(alert.headline),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(alert.event),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(alert.headline, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Severity: ${alert.severity}'),
                            const SizedBox(height: 16),
                            const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(alert.desc),
                            const SizedBox(height: 16),
                            const Text('Instruction:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(alert.instruction),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _getAlertColor(String severity) {
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

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, child) {
        if (weatherProvider.loading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (weatherProvider.error != null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(weatherProvider.error!),
              ),
            ),
          );
        }

        if (weatherProvider.weather == null) {
          return Scaffold(body: Container());
        }

        Forecast today = weatherProvider.weather!.forecast.first;
        List<Forecast> forecast = weatherProvider.weather!.forecast;

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
                child: Text(weatherProvider.weather!.city),
              ),
              IconButton(
                onPressed: () {
                  weatherProvider.toggleUnit();
                },
                icon: Icon(weatherProvider.isCelsius ? Icons.thermostat : Icons.thermostat_auto),
              ),
              IconButton(
                onPressed: () {
                  final weather = weatherProvider.weather;
                  if (weather != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapScreen(
                          initialCenter: LatLng(weather.lat, weather.lon),
                          openWeatherMapApiKey: weatherProvider.openWeatherMapApiKey,
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.map),
              ),
            ],
          ),

          // Locations
          endDrawer: Drawer(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Choose location',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                              onTap: () {
                                weatherProvider.callWeatherAPi(current: false, cityName: location);
                                Navigator.pop(context);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LocationsScreen()),
                      );
                    },
                    child: const Text('Manage Locations'),
                  ),
                ],
              ),
            ),
          ),

          // Body
          body: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                _buildAlerts(weatherProvider.weather!.alerts),
                const SizedBox(height: 25),

                // - Image
                Image.asset(
                  weatherProvider.getWeatherImage(weatherProvider.weather!.description),
                  height: 150,
                  width: 150,
                  fit: BoxFit.fill,
                ),
                const SizedBox(height: 16),

                // - Temperature
                Text(
                  '${weatherProvider.weather!.temperature.toStringAsFixed(0)} ${weatherProvider.isCelsius ? '°C' : '°F'}',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // - Description
                Text(
                  weatherProvider.weather!.description,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                // - Feels Like & Humidity & Wind Speed
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Feels Like '),
                    Text(
                      '${weatherProvider.weather!.feelsLike.toStringAsFixed(0)} ${weatherProvider.isCelsius ? '°C' : '°F'}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Text('  |  ', style: TextStyle(fontSize: 24)),
                    const Text('Humidity '),
                    Text(
                      '${weatherProvider.weather!.humidity.toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Text('  |  ', style: TextStyle(fontSize: 24)),
                    const Text('Wind Speed '),
                    Text(
                      '${weatherProvider.weather!.windSpeed.toStringAsFixed(0)}m/s',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('UV Index '),
                    Text(
                      weatherProvider.weather!.uv.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Text('  |  ', style: TextStyle(fontSize: 24)),
                    const Text('Pressure '),
                    Text(
                      '${weatherProvider.weather!.pressure.toStringAsFixed(0)} hPa',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Text('  |  ', style: TextStyle(fontSize: 24)),
                    const Text('Visibility '),
                    Text(
                      '${weatherProvider.weather!.visibility.toStringAsFixed(0)} km',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('AQI '),
                    Text(
                      '${weatherProvider.weather!.airQuality.usEpaIndex} (${_getAqiString(weatherProvider.weather!.airQuality.usEpaIndex)})',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // - Today Forecast
                ...{
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        '24 Forecast',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        today.hours.length,
                        (index) => Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                // - Image
                                Image.asset(
                                  weatherProvider.getWeatherImage(today.hours[index].description),
                                  height: 50,
                                  width: 50,
                                  fit: BoxFit.fill,
                                ),

                                // - Temperature
                                Text(
                                  '${today.hours[index].temperature.toStringAsFixed(0)} ${weatherProvider.isCelsius ? '°C' : '°F'}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),

                                // - Time
                                Text(
                                  DateFormat('hh a').format(today.hours[index].date),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                },

                // - 7 Days Forecast
                ...{
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        '7 Days Forecast',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: forecast.length,
                    itemBuilder: (context, index) => Card(
                      child: ListTile(
                        // - Informations
                        onTap: () => showDialog(
                          context: context,
                          builder: (context) => ForecastWidget(forecast: forecast[index]),
                        ),

                        // - Image
                        leading: Image.asset(
                          weatherProvider.getWeatherImage(forecast[index].description),
                          width: 50,
                          height: 50,
                        ),

                        // - Temperature
                        title: Text(
                          '${forecast[index].avgTemperature.toStringAsFixed(0)} ${weatherProvider.isCelsius ? '°C' : '°F'}',
                          style: const TextStyle(fontSize: 24),
                        ),

                        // - Min | Max Temperature & Condition
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // -- Min | Max Temperature
                            Row(
                              children: [
                                const Text('Min: ', style: TextStyle(fontSize: 10)),
                                Text(
                                  '${forecast[index].minTemperature.toStringAsFixed(0)} ${weatherProvider.isCelsius ? '°C' : '°F'}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const Text('  |  ', style: TextStyle(fontSize: 10)),
                                const Text('Max: ', style: TextStyle(fontSize: 10)),
                                Text(
                                  '${forecast[index].maxTemperature.toStringAsFixed(0)} ${weatherProvider.isCelsius ? '°C' : '°F'}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),

                            // -- Condition
                            Text(
                              forecast[index].description,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),

                        // - Date
                        trailing: Text(
                          DateFormat('d | EEEE').format(forecast[index].date),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                },
              ],
            ),
          ),
        );
      },
    );
  }
}

class ForecastWidget extends StatelessWidget {
  final Forecast forecast;
  const ForecastWidget({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) => AlertDialog(
    contentPadding: EdgeInsets.zero,
    content: SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 25),

          // - Image
          Image.asset(
            WeatherProvider().getWeatherImage(forecast.description),
            height: 150,
            width: 150,
            fit: BoxFit.fill,
          ),
          const SizedBox(height: 16),

          // - Temperature
          Text(
            '${forecast.avgTemperature} °C',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          // - Description
          Text(
            forecast.description,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // - Min | Max Temperature
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Min: '),
              Text(
                '${forecast.minTemperature.toStringAsFixed(0)} °C',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text('  |  ', style: TextStyle(fontSize: 24)),
              const Text('Max: '),
              Text(
                '${forecast.maxTemperature.toStringAsFixed(0)} °C',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          // - Humidity & Wind Speed
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Humidity '),
              Text(
                '${forecast.humidity.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text('  |  ', style: TextStyle(fontSize: 24)),
              const Text('Wind Speed '),
              Text(
                '${forecast.maxWind.toStringAsFixed(0)}m/s',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          // - Rainy & Snowy
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Rainy '),
              Text(
                forecast.hasRain.toString(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text('  |  ', style: TextStyle(fontSize: 24)),
              const Text('Snowy '),
              Text(
                forecast.hasSnow.toString(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // - Sunrise
          ListTile(
            title: const Text('Sunrise', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Padding(padding: const EdgeInsets.all(8), child: Text(forecast.sunrise)),
          ),

          // - Sunset
          ListTile(
            title: const Text('Sunset', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Padding(padding: const EdgeInsets.all(8), child: Text(forecast.sunset)),
          ),

          // - Moonrise
          ListTile(
            title: const Text('Moonrise', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Padding(padding: const EdgeInsets.all(8), child: Text(forecast.moonrise)),
          ),

          // - Moonset
          ListTile(
            title: const Text('Moonset', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Padding(padding: const EdgeInsets.all(8), child: Text(forecast.moonset)),
          ),

          // - Moon Phase
          ListTile(
            title: const Text('Moon Phase', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Padding(padding: const EdgeInsets.all(8), child: Text(forecast.moonPhase)),
          ),

          // - UV Index
          ListTile(
            title: const Text('UV Index', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(forecast.uv.toString()),
            ),
          ),

          // - Today Forecast
          ...{
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '24 Forecast',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  forecast.hours.length,
                  (index) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          // - Image
                          Image.asset(
                            WeatherProvider().getWeatherImage(forecast.hours[index].description),
                            height: 50,
                            width: 50,
                            fit: BoxFit.fill,
                          ),

                          // - Temperature
                          Text(
                            '${forecast.hours[index].temperature.toStringAsFixed(0)} °C',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),

                          // - Time
                          Text(
                            DateFormat('hh a').format(forecast.hours[index].date),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          },
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}
