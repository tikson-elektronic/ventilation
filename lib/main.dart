import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'screens/dashboard_screen.dart';
import 'screens/discovery_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  runApp(const VentApp());
}

class VentApp extends StatelessWidget {
  const VentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Engine Room Ventilation',
      debugShowCheckedModeBanner: false,
      theme: buildVentTheme(),
      home: const bool.fromEnvironment('demo')
          ? DashboardScreen(
              panel: PanelInfo(
                name: 'Engine Room Ventilation', vendor: 'Tikson-Elektronic', version: '1.0.0.0',
                host: '127.0.0.1', httpPort: 8787, apiBase: 'http://127.0.0.1:8787',
                channels: const [],
              ),
            )
          : const DiscoveryScreen(),
    );
  }
}
