import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/provider.dart';

import 'home.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => WeatherProvider(),
        child: MaterialApp(
          title: 'Flutter Weather',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
          home: const Home(),
        ),
      );
}
