import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:weather_app/main.dart';
import 'package:weather_app/models/models.dart';
import 'package:weather_app/controllers/weather_controller.dart';

void main() {
  group('App', () {
    testWidgets('renders MaterialApp', (WidgetTester tester) async {
      await tester.pumpWidget(const App());
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('Fetching weather data...'), findsOneWidget);
    });
  });

  group('Weather model', () {
    test('fromJson parses correctly with Celsius', () {
      final json = {
        'location': {'name': 'London', 'lat': 51.5, 'lon': -0.1},
        'current': {
          'temp_c': 15.0,
          'temp_f': 59.0,
          'feelslike_c': 13.0,
          'feelslike_f': 55.4,
          'condition': {'text': 'Partly cloudy'},
          'humidity': 72,
          'wind_mph': 10.0,
          'uv': 3.0,
          'pressure_mb': 1015.0,
          'vis_km': 10.0,
          'air_quality': {
            'co': 0.3,
            'no2': 0.1,
            'o3': 0.05,
            'so2': 0.02,
            'pm2_5': 12.0,
            'pm10': 25.0,
            'us-epa-index': 2,
          },
        },
        'forecast': {
          'forecastday': [
            {
              'date': '2026-05-16',
              'day': {
                'maxtemp_c': 20.0,
                'mintemp_c': 10.0,
                'avgtemp_c': 15.0,
                'maxwind_mph': 15.0,
                'avghumidity': 65,
                'daily_chance_of_rain': 20,
                'daily_chance_of_snow': 0,
                'condition': {'text': 'Cloudy'},
                'uv': 4.0,
              },
              'astro': {
                'sunrise': '05:30 AM',
                'sunset': '08:45 PM',
                'moonrise': '03:15 PM',
                'moonset': '04:30 AM',
                'moon_phase': 'Waxing Gibbous',
              },
              'hour': [
                {
                  'time': '2026-05-16 00:00',
                  'temp_c': 12.0,
                  'temp_f': 53.6,
                  'condition': {'text': 'Clear'},
                  'humidity': 70,
                },
              ],
            },
          ],
        },
        'alerts': null,
      };

      final weather = Weather.fromJson(json, true);
      expect(weather.city, 'London');
      expect(weather.temperature, 15.0);
      expect(weather.feelsLike, 13.0);
      expect(weather.humidity, 72);
      expect(weather.windSpeedMph, 10.0);
      expect(weather.windSpeedMs, closeTo(4.4704, 0.001));
      expect(weather.airQuality.usEpaIndex, 2);
      expect(weather.forecast.length, 1);
      expect(weather.forecast.first.maxWindMph, 15.0);
      expect(weather.forecast.first.maxWindMs, closeTo(6.7056, 0.001));
      expect(weather.forecast.first.hours.length, 1);
    });

    test('fromJson parses with Fahrenheit', () {
      final json = {
        'location': {'name': 'New York', 'lat': 40.7, 'lon': -74.0},
        'current': {
          'temp_c': 10.0,
          'temp_f': 50.0,
          'feelslike_c': 8.0,
          'feelslike_f': 46.4,
          'condition': {'text': 'Sunny'},
          'humidity': 60,
          'wind_mph': 5.0,
          'uv': 2.0,
          'pressure_mb': 1020.0,
          'vis_km': 16.0,
          'air_quality': {
            'co': 0.2,
            'no2': 0.05,
            'o3': 0.03,
            'so2': 0.01,
            'pm2_5': 8.0,
            'pm10': 15.0,
            'us-epa-index': 1,
          },
        },
        'forecast': {
          'forecastday': [
            {
              'date': '2026-05-16',
              'day': {
                'maxtemp_f': 60.0,
                'mintemp_f': 40.0,
                'avgtemp_f': 50.0,
                'maxwind_mph': 10.0,
                'avghumidity': 55,
                'daily_chance_of_rain': 0,
                'daily_chance_of_snow': 0,
                'condition': {'text': 'Sunny'},
                'uv': 6.0,
              },
              'astro': {
                'sunrise': '06:00 AM',
                'sunset': '08:00 PM',
                'moonrise': '02:00 PM',
                'moonset': '03:00 AM',
                'moon_phase': 'First Quarter',
              },
              'hour': [
                {
                  'time': '2026-05-16 12:00',
                  'temp_f': 55.0,
                  'temp_c': 12.8,
                  'condition': {'text': 'Sunny'},
                  'humidity': 50,
                },
              ],
            },
          ],
        },
        'alerts': null,
      };

      final weather = Weather.fromJson(json, false);
      expect(weather.city, 'New York');
      expect(weather.temperature, 50.0);
      expect(weather.feelsLike, 46.4);
    });

    test('Alert.fromJson handles missing fields', () {
      final alert = Alert.fromJson({'headline': 'Test'});
      expect(alert.headline, 'Test');
      expect(alert.event, '');
      expect(alert.severity, '');
      expect(alert.desc, '');
      expect(alert.instruction, '');
    });
  });

  group('WeatherController', () {
    test('getWeatherImage returns correct assets', () {
      final controller = WeatherController();
      expect(controller.getWeatherImage('Sunny'), 'images/Sunny.png');
      expect(controller.getWeatherImage('Clear'), 'images/Sunny.png');
      expect(controller.getWeatherImage('Partly cloudy'), 'images/Cloudy.png');
      expect(controller.getWeatherImage('Overcast'), 'images/Cloudy.png');
      expect(controller.getWeatherImage('Light rain'), 'images/Rainy.png');
      expect(controller.getWeatherImage('Heavy drizzle'), 'images/Rainy.png');
      expect(controller.getWeatherImage('Thunderstorm'), 'images/Storm.png');
      expect(controller.getWeatherImage('Thundery outbreaks'),
          'images/Storm.png');
      expect(controller.getWeatherImage('Light snow'), 'images/Snow.png');
      expect(controller.getWeatherImage('Blizzard'), 'images/Snow.png');
      expect(controller.getWeatherImage('Fog'), 'images/Fog.png');
      expect(controller.getWeatherImage('Mist'), 'images/Fog.png');
      expect(controller.getWeatherImage('Tornado'), 'images/StormWindy.png');
      expect(controller.getWeatherImage('Squall'), 'images/StormWindy.png');
      expect(controller.getWeatherImage('Unknown condition'),
          'images/Cloud.png');
    });

    test('getAqiString returns correct labels', () {
      final controller = WeatherController();
      expect(controller.getAqiString(1), 'Good');
      expect(controller.getAqiString(2), 'Moderate');
      expect(controller.getAqiString(3), 'Unhealthy for sensitive groups');
      expect(controller.getAqiString(4), 'Unhealthy');
      expect(controller.getAqiString(5), 'Very Unhealthy');
      expect(controller.getAqiString(6), 'Hazardous');
      expect(controller.getAqiString(99), 'Unknown');
    });

    test('getAlertColor returns correct colors', () {
      final controller = WeatherController();
      expect(controller.getAlertColor('extreme'), Colors.red.shade400);
      expect(controller.getAlertColor('severe'), Colors.orange.shade400);
      expect(controller.getAlertColor('moderate'), Colors.yellow.shade400);
      expect(controller.getAlertColor('minor'), Colors.blueGrey.shade400);
    });
  });
}
