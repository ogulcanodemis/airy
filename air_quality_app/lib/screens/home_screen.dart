import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/air_quality_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/notification_provider.dart';
import '../services/air_quality_service.dart';
import '../styles/app_styles.dart';
import '../widgets/user_profile_card.dart';
import '../widgets/location_card.dart';
import '../widgets/air_quality_card.dart';
import '../widgets/advice_card.dart';
import '../widgets/pollen_card.dart';
import '../widgets/weather_card.dart';
import '../widgets/animated_widgets.dart';
import 'auth/login_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'air_quality_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Verileri başlatma
  Future<void> _initData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) return;

    final userId = authProvider.firebaseUser!.uid;
    
    // Ayarları al
    await Provider.of<SettingsProvider>(context, listen: false).getUserSettings(userId);
    
    // Konum izinlerini kontrol et
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final hasPermission = await locationProvider.checkLocationPermission(context);
    
    if (hasPermission) {
      // Mevcut konumu al
      await locationProvider.getCurrentLocation(context, userId: userId);
      
      // Konum güncellemelerini başlat
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      if (settingsProvider.settings != null && settingsProvider.settings!.backgroundLocationEnabled) {
        locationProvider.startLocationUpdates(
          userId,
          intervalMinutes: settingsProvider.settings!.locationUpdateInterval,
        );
      }
      
      // Hava kalitesi verilerini al
      if (locationProvider.currentPosition != null) {
        final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
        await Provider.of<AirQualityProvider>(context, listen: false).getAirQualityByLocation(
          locationProvider.currentPosition!.latitude,
          locationProvider.currentPosition!.longitude,
          userId,
          context: context,
          settings: settingsProvider.settings!,
          isAdmin: authProvider.userModel?.isAdmin ?? false,
        );
      }
    }
    
    // Bildirimleri dinlemeye başla
    Provider.of<NotificationProvider>(context, listen: false).startListeningNotifications(userId);
  }

  // Verileri yenileme
  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });
    
    _animationController.forward(from: 0.0);
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) return;

    final userId = authProvider.firebaseUser!.uid;
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    
    // Mevcut konumu al
    await locationProvider.getCurrentLocation(context, userId: userId);
    
    // Hava kalitesi verilerini al
    if (locationProvider.currentPosition != null) {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      await Provider.of<AirQualityProvider>(context, listen: false).getAirQualityByLocation(
        locationProvider.currentPosition!.latitude,
        locationProvider.currentPosition!.longitude,
        userId,
        context: context,
        settings: settingsProvider.settings!,
        isAdmin: authProvider.userModel?.isAdmin ?? false,
      );
    }
    
    setState(() {
      _isRefreshing = false;
    });
  }

  // Çıkış yapma
  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Konum güncellemelerini durdur
    Provider.of<LocationProvider>(context, listen: false).stopLocationUpdates();
    
    // Bildirim dinlemeyi durdur
    Provider.of<NotificationProvider>(context, listen: false).stopListeningNotifications();
    
    // Çıkış yap
    await authProvider.signOut();
    
    if (!mounted) return;
    
    // Giriş ekranına yönlendir
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);
    final airQualityProvider = Provider.of<AirQualityProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 40,
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.air,
                  size: 40,
                  color: Colors.white,
                );
              },
            ),
            const SizedBox(width: 8),
            const Text('Hava Kalitesi'),
          ],
        ),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Bildirim butonu
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
              ),
              if (notificationProvider.unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: PulseAnimation(
                    minOpacity: 0.7,
                    maxOpacity: 1.0,
                    duration: const Duration(milliseconds: 800),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${notificationProvider.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppStyles.primaryColor,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kullanıcı profil kartı
                if (authProvider.userModel != null)
                  UserProfileCard(
                    user: authProvider.userModel!,
                    onLogout: _logout,
                    onSettings: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                
                const SizedBox(height: 16),
                
                // Konum kartı
                LocationCard(
                  address: locationProvider.userLocation?.address,
                  position: locationProvider.currentPosition,
                  isLoading: locationProvider.isLoading,
                  hasPermission: locationProvider.hasPermission,
                  onRequestPermission: () async {
                    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final hasPermission = await locationProvider.checkLocationPermission(context);
                    
                    if (hasPermission && mounted && authProvider.firebaseUser != null) {
                      await locationProvider.getCurrentLocation(context, userId: authProvider.firebaseUser!.uid);
                      
                      if (locationProvider.currentPosition != null) {
                        final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
                        
                        await Provider.of<AirQualityProvider>(context, listen: false).getAirQualityByLocation(
                          locationProvider.currentPosition!.latitude,
                          locationProvider.currentPosition!.longitude,
                          authProvider.firebaseUser!.uid,
                          context: context,
                          settings: settingsProvider.settings!,
                          isAdmin: authProvider.userModel?.isAdmin ?? false,
                        );
                      }
                    }
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Hava kalitesi kartı
                if (airQualityProvider.hasAirQualityData)
                  AirQualityCard(
                    airQuality: airQualityProvider.currentAirQuality!,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AirQualityDetailsScreen(),
                        ),
                      );
                    },
                  )
                else if (airQualityProvider.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppStyles.cardShadow,
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          size: 50,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Hava kalitesi verisi bulunamadı',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          airQualityProvider.error.isEmpty
                              ? 'Lütfen internet bağlantınızı kontrol edin ve yenileyin'
                              : airQualityProvider.error,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: _refreshData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppStyles.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Yenile'),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Hava durumu kartı - WAQI API'den gelen hava durumu verileri varsa göster
                if (airQualityProvider.hasAirQualityData && 
                    airQualityProvider.currentAirQuality!.additionalData != null &&
                    airQualityProvider.currentAirQuality!.additionalData!['hasWeatherData'] == true)
                  WeatherCard(
                    weatherData: airQualityProvider.currentAirQuality!.additionalData!['weatherData'],
                    temperatureUnit: settingsProvider.settings?.temperatureUnit ?? 'celsius',
                  ),
                
                const SizedBox(height: 16),
                
                // Tavsiyeler kartı
                if (airQualityProvider.hasAirQualityData)
                  AdviceCard(
                    category: airQualityProvider.currentAirQuality!.category,
                    advice: airQualityProvider.getAirQualityAdvice(
                      airQualityProvider.currentAirQuality!.category,
                    ),
                  ),
                
                // Polen kartı (sadece Google API için)
                if (airQualityProvider.hasAirQualityData && 
                    airQualityProvider.currentAirQuality!.source == AirQualityService.SOURCE_GOOGLE &&
                    airQualityProvider.currentAirQuality!.additionalData != null &&
                    airQualityProvider.currentAirQuality!.additionalData!['hasPollenData'] == true)
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      PollenCard(
                        pollenData: airQualityProvider.currentAirQuality!.additionalData!['pollenData'],
                      ),
                    ],
                  ),
                
                // Yenileme göstergesi
                if (_isRefreshing)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: RotationTransition(
                        turns: _animationController,
                        child: const Icon(
                          Icons.refresh,
                          color: AppStyles.primaryColor,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingAnimation(
        height: 10,
        child: FloatingActionButton(
          onPressed: _refreshData,
          backgroundColor: AppStyles.primaryColor,
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
  
  // Alternatif API kaynaklarından gelen verileri gösteren bölüm
  Widget _buildAlternativeSourcesSection(AirQualityProvider airQualityProvider, SettingsProvider settingsProvider) {
    // Sadece WAQI API'si kullanıldığı için alternatif kaynaklar bölümünü göstermeye gerek yok
    return const SizedBox.shrink();
  }
}