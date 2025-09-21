import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'provider.dart';
import 'models.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  ScrollController scrollController = ScrollController();
  bool scrolled = false;

  String? cityName;

  @override
  void initState() {
    super.initState();

    scrollController.addListener(() {
      setState(() => scrolled = scrollController.offset >= 25);
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: AppProvider().callWeatherAPi(current: true, cityName: cityName),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Forecast today = snapshot.data!.forecast.first;
            List<Forecast> forecast = snapshot.data!.forecast;

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
                    child: Text(cityName ?? snapshot.data!.city),
                  ),
                ],
              ),

              // Locations
              endDrawer: const Drawer(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Chose location to get it\'s data',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
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
                    const SizedBox(height: 25),

                    // - Image
                    Image.asset(
                      AppProvider().getWeatherImage(snapshot.data!.description),
                      height: 150,
                      width: 150,
                      fit: BoxFit.fill,
                    ),
                    const SizedBox(height: 16),

                    // - Temperature
                    Text(
                      '${snapshot.data!.temperature.toStringAsFixed(0)} °C',
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // - Description
                    Text(
                      snapshot.data!.description,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),

                    // - Feels Like & Humidity & Wind Speed
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Feels Like '),
                        Text(
                          '${snapshot.data!.feelsLike.toStringAsFixed(0)} °C',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          '  |  ',
                          style: TextStyle(fontSize: 24),
                        ),
                        const Text('Humidity '),
                        Text(
                          '${snapshot.data!.humidity.toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          '  |  ',
                          style: TextStyle(fontSize: 24),
                        ),
                        const Text('Wind Speed '),
                        Text(
                          '${snapshot.data!.windSpeed.toStringAsFixed(0)}m/s',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
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
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
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
                                      AppProvider().getWeatherImage(
                                          today.hours[index].description),
                                      height: 50,
                                      width: 50,
                                      fit: BoxFit.fill,
                                    ),

                                    // - Temperature
                                    Text(
                                      '${today.hours[index].temperature.toStringAsFixed(0)} °C',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),

                                    // - Time
                                    Text(
                                      DateFormat('hh a')
                                          .format(today.hours[index].date),
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
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
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
                              builder: (context) =>
                                  ForecastWidget(forecast: forecast[index]),
                            ),

                            // - Image
                            leading: Image.asset(
                              AppProvider()
                                  .getWeatherImage(forecast[index].description),
                              width: 50,
                              height: 50,
                            ),

                            // - Temperature
                            title: Text(
                              '${forecast[index].avgTemperature.toStringAsFixed(0)} °C',
                              style: const TextStyle(fontSize: 24),
                            ),

                            // - Min | Max Temperature & Condition
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // -- Min | Max Temperature
                                Row(
                                  children: [
                                    const Text(
                                      'Min: ',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                    Text(
                                      '${forecast[index].minTemperature} °C',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const Text(
                                      '  |  ',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                    const Text(
                                      'Max: ',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                    Text(
                                      '${forecast[index].maxTemperature} °C',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),

                                // -- Condition
                                Text(
                                  forecast[index].description,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),

                            // - Date
                            trailing: Text(
                              DateFormat('d | EEEE')
                                  .format(forecast[index].date),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      )
                    }
                  ],
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(snapshot.error.toString()),
                ),
              ),
            );
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else {
            return Scaffold(body: Container());
          }
        },
      );
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
                AppProvider().getWeatherImage(forecast.description),
                height: 150,
                width: 150,
                fit: BoxFit.fill,
              ),
              const SizedBox(height: 16),

              // - Temperature
              Text(
                '${forecast.avgTemperature} °C',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // - Description
              Text(
                forecast.description,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // - Min | Max Temperature
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Min: '),
                  Text(
                    '${forecast.minTemperature.toStringAsFixed(0)} °C',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    '  |  ',
                    style: TextStyle(fontSize: 24),
                  ),
                  const Text('Max: '),
                  Text(
                    '${forecast.maxTemperature.toStringAsFixed(0)} °C',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
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
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    '  |  ',
                    style: TextStyle(fontSize: 24),
                  ),
                  const Text('Wind Speed '),
                  Text(
                    '${forecast.maxWind.toStringAsFixed(0)}m/s',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
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
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    '  |  ',
                    style: TextStyle(fontSize: 24),
                  ),
                  const Text('Snowy '),
                  Text(
                    forecast.hasSnow.toString(),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // - Sunrise
              ListTile(
                title: const Text('Sunrise',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(forecast.sunrise),
                ),
              ),

              // - Sunset
              ListTile(
                title: const Text('Sunset',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(forecast.sunset),
                ),
              ),

              // - Moonrise
              ListTile(
                title: const Text('Moonrise',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(forecast.moonrise),
                ),
              ),

              // - Moonset
              ListTile(
                title: const Text('Moonset',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(forecast.moonset),
                ),
              ),

              // - Moon Phase
              ListTile(
                title: const Text('Moon Phase',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(forecast.moonPhase),
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
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
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
                                AppProvider().getWeatherImage(
                                    forecast.hours[index].description),
                                height: 50,
                                width: 50,
                                fit: BoxFit.fill,
                              ),

                              // - Temperature
                              Text(
                                '${forecast.hours[index].temperature.toStringAsFixed(0)} °C',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),

                              // - Time
                              Text(
                                DateFormat('hh a')
                                    .format(forecast.hours[index].date),
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
              const SizedBox(height: 16)
            ],
          ),
        ),
      );
}
