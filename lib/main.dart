import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/weather_controller.dart';
import 'controllers/locations_controller.dart';
import 'views/home_view.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Weather',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue.shade400,
          secondary: Colors.blueAccent,
          surface: const Color(0xFF1E1E2E),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
      ),
      initialBinding: BindingsBuilder(() {
        Get.put(WeatherController());
        Get.put(LocationsController());
      }),
      home: const HomeView(),
    );
  }
}
