import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../services/air_quality_service.dart';
import '../services/location_service.dart';
import '../styles/app_styles.dart';
import '../services/platform_service.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);
    
    if (!authProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ayarlar'),
          backgroundColor: AppStyles.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Ayarları görüntülemek için giriş yapmalısınız'),
        ),
      );
    }
    
    if (settingsProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ayarlar'),
          backgroundColor: AppStyles.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (settingsProvider.settings == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ayarlar'),
          backgroundColor: AppStyles.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Ayarlar yüklenemedi'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  settingsProvider.getUserSettings(authProvider.firebaseUser!.uid);
                },
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }
    
    final settings = settingsProvider.settings!;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // API Kaynak Ayarları
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Veri Kaynağı Ayarları',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // WAQI API bilgisi
                  ListTile(
                    title: Row(
                      children: [
                        Icon(Icons.public, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        const Text('WAQI API'),
                      ],
                    ),
                    subtitle: const Text('Dünya Hava Kalitesi İndeksi verilerini kullanıyorsunuz'),
                    trailing: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                  
                  const Divider(),
                  
                  // API bilgisi
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Bu uygulama, hava kalitesi verilerini Dünya Hava Kalitesi İndeksi (WAQI) API\'sinden almaktadır. WAQI, dünya genelinde hava kalitesi verilerini sağlayan güvenilir bir kaynaktır.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Arka plan konum izinleri
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Arka Plan Konum İzinleri',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Uygulamanın arka planda çalışırken de konum bilgilerinize erişmesi için gerekli izinleri kontrol edin.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final locationService = LocationService();
                      final hasPermission = await locationService.checkBackgroundLocationPermission(context);
                      
                      if (hasPermission) {
                        // İzinler tamam, servisi başlat
                        final platformService = PlatformService();
                        final success = await platformService.startLocationService();
                        
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Arka plan konum servisi başlatıldı'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Arka plan konum servisi başlatılamadı'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppStyles.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('İzinleri Kontrol Et'),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Bildirim ayarları
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bildirim Ayarları',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Bildirimleri Etkinleştir'),
                    subtitle: const Text('Tehlikeli hava kalitesi bildirimleri alın'),
                    value: settings.notificationsEnabled,
                    onChanged: (value) {
                      settingsProvider.toggleNotifications(value);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Bildirim Eşiği'),
                    subtitle: Text('AQI ${settings.notificationThreshold} üzerinde bildirim al'),
                    trailing: DropdownButton<int>(
                      value: settings.notificationThreshold,
                      onChanged: (value) {
                        if (value != null) {
                          settingsProvider.updateNotificationThreshold(value);
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: 50,
                          child: Text('50 (Orta)'),
                        ),
                        DropdownMenuItem(
                          value: 100,
                          child: Text('100 (Hassas Gruplar)'),
                        ),
                        DropdownMenuItem(
                          value: 150,
                          child: Text('150 (Sağlıksız)'),
                        ),
                        DropdownMenuItem(
                          value: 200,
                          child: Text('200 (Çok Sağlıksız)'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Konum ayarları
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Konum Ayarları',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Arka Planda Konum Takibi'),
                    subtitle: const Text('Uygulama kapalıyken konum güncellemelerini al'),
                    value: settings.backgroundLocationEnabled,
                    onChanged: (value) {
                      settingsProvider.toggleBackgroundLocation(value);
                      
                      if (value && locationProvider.hasPermission) {
                        locationProvider.startLocationUpdates(
                          authProvider.firebaseUser!.uid,
                          intervalMinutes: settings.locationUpdateInterval,
                        );
                      } else {
                        locationProvider.stopLocationUpdates();
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Konum Güncelleme Aralığı'),
                    subtitle: Text('${settings.locationUpdateInterval} dakikada bir güncelle'),
                    trailing: DropdownButton<int>(
                      value: settings.locationUpdateInterval,
                      onChanged: (value) {
                        if (value != null) {
                          settingsProvider.updateLocationUpdateInterval(value);
                          
                          if (settings.backgroundLocationEnabled && locationProvider.hasPermission) {
                            locationProvider.startLocationUpdates(
                              authProvider.firebaseUser!.uid,
                              intervalMinutes: value,
                            );
                          }
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: 15,
                          child: Text('15 dakika'),
                        ),
                        DropdownMenuItem(
                          value: 30,
                          child: Text('30 dakika'),
                        ),
                        DropdownMenuItem(
                          value: 60,
                          child: Text('1 saat'),
                        ),
                        DropdownMenuItem(
                          value: 120,
                          child: Text('2 saat'),
                        ),
                      ],
                    ),
                  ),
                  if (!locationProvider.hasPermission)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: () async {
                          final hasPermission = await locationProvider.checkLocationPermission(context);
                          if (hasPermission && settings.backgroundLocationEnabled) {
                            locationProvider.startLocationUpdates(
                              authProvider.firebaseUser!.uid,
                              intervalMinutes: settings.locationUpdateInterval,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Konum İzni Ver'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Görünüm ayarları
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Görünüm Ayarları',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Sıcaklık Birimi'),
                    trailing: DropdownButton<String>(
                      value: settings.temperatureUnit,
                      onChanged: (value) {
                        if (value != null) {
                          settingsProvider.updateTemperatureUnit(value);
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: 'celsius',
                          child: Text('Celsius (°C)'),
                        ),
                        DropdownMenuItem(
                          value: 'fahrenheit',
                          child: Text('Fahrenheit (°F)'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Dil'),
                    trailing: DropdownButton<String>(
                      value: settings.language,
                      onChanged: (value) {
                        if (value != null) {
                          settingsProvider.updateLanguage(value);
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: 'tr',
                          child: Text('Türkçe'),
                        ),
                        DropdownMenuItem(
                          value: 'en',
                          child: Text('English'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Uygulama bilgileri
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Uygulama Bilgileri',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Uygulama Versiyonu'),
                    subtitle: const Text('1.0.0'),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Veri Kaynakları'),
                    subtitle: const Text('WAQI'),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Gizlilik Politikası'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Gizlilik politikası sayfasına yönlendirme
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Kullanım Koşulları'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Kullanım koşulları sayfasına yönlendirme
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 