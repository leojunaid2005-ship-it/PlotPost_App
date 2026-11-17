import 'package:flutter/material.dart';

import 'services/api_client.dart';
import 'screens/splash_screen.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadPlotPostThemePreference();
  await ApiClient.instance.restoreSession();
  runApp(const PlotPostApp());
}

class PlotPostApp extends StatelessWidget {
  const PlotPostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: plotPostThemeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'PlotPost',
          debugShowCheckedModeBanner: false,
          theme: buildPlotPostTheme(Brightness.light),
          darkTheme: buildPlotPostTheme(Brightness.dark),
          themeMode: mode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
