import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'screens/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/air_quality_provider.dart';
import 'providers/location_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/notification_provider.dart';

// Global navigatorKey tanımlama
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase'i başlat
  await Firebase.initializeApp();
  
  // Bildirim servisini başlat
  await NotificationService().init();
  
  // Arka plan servisini başlat
  await BackgroundService().init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => AirQualityProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey, // navigatorKey'i MaterialApp'e ekle
        title: 'Hava Kalitesi Uygulaması',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
