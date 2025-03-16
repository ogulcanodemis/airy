import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/notification_provider.dart';
import '../services/air_quality_service.dart';
import '../services/location_service.dart';
import '../services/platform_service.dart';
import '../services/purchase_service.dart';
import '../styles/app_styles.dart';
import '../widgets/animated_widgets.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'auth/login_screen.dart';

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
        body: AnimatedBackground(
          color1: const Color(0xFF82E0F9), // Açık mavi
          color2: const Color(0xFFF9CC3E), // Sarı
          bubbleCount: 8,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Ayarları görüntülemek için giriş yapmalısınız',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
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
        body: AnimatedBackground(
          color1: const Color(0xFF82E0F9), // Açık mavi
          color2: const Color(0xFFF9CC3E), // Sarı
          bubbleCount: 8,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Ayarlar yükleniyor...',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
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
        body: AnimatedBackground(
          color1: const Color(0xFF82E0F9), // Açık mavi
          color2: const Color(0xFFF9CC3E), // Sarı
          bubbleCount: 8,
          child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Ayarlar yüklenemedi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 16),
                ElevatedButton.icon(
                onPressed: () {
                  settingsProvider.getUserSettings(authProvider.firebaseUser!.uid);
                },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStyles.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    final settings = settingsProvider.settings!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // Beyaz arka plan
      body: AnimatedBackground(
        color1: const Color(0xFF82E0F9), // Açık mavi
        color2: const Color(0xFFF9CC3E), // Sarı
        bubbleCount: 8,
        child: SafeArea(
          child: Column(
            children: [
              // Üst kısım - Başlık ve geri butonu
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Geri butonu
                    Container(
                      decoration: BoxDecoration(
                        color: AppStyles.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppStyles.primaryColor,
                          size: 26,
                        ),
                        tooltip: 'Geri',
                        padding: const EdgeInsets.all(10.0),
                        constraints: const BoxConstraints(
                          minWidth: 46,
                          minHeight: 46,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    
                    // Başlık
                    const Text(
                      'Ayarlar',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppStyles.primaryColor,
                      ),
                    ),
                    
                    // Sağ tarafta boşluk bırakmak için
                    const SizedBox(width: 46),
                  ],
                ),
              ),
              
              // Ana içerik
              Expanded(
                child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
                    // Profil özeti
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF82E0F9), Color(0xFF5BBCD9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            child: Text(
                              authProvider.userModel?.displayName.substring(0, 1).toUpperCase() ?? 'U',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppStyles.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                                Text(
                                  authProvider.userModel?.displayName ?? 'Kullanıcı',
                                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  authProvider.userModel?.email ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Premium Üyelik Kartı
                    _buildSettingsCard(
                      title: 'Premium Üyelik',
                      icon: Icons.workspace_premium,
                      iconColor: const Color(0xFFFFD700), // Altın rengi
                      children: [
                        Consumer<SettingsProvider>(
                          builder: (context, settingsProvider, child) {
                            final isPremium = settingsProvider.settings?.isPremium ?? false;
                            
                            return Column(
                              children: [
                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFD700).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.ads_click, color: Color(0xFFFFD700)),
                                  ),
                                  title: const Text(
                                    'Reklamları Kaldır',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    isPremium 
                                        ? 'Premium üyeliğiniz aktif, reklamlar kapalı'
                                        : 'Reklamları kaldırmak için premium üyelik satın alın',
                                  ),
                                  trailing: isPremium
                                      ? const Icon(Icons.check_circle, color: Colors.green)
                                      : ElevatedButton(
                                          onPressed: () {
                                            // Premium satın alma işlemi burada yapılacak
                                            _showPremiumDialog(context);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFFFD700),
                                            foregroundColor: Colors.black,
                                          ),
                                          child: const Text('Satın Al'),
                                        ),
                                ),
                                
                                const Divider(),
                                
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'Premium üyelik ile tüm reklamları kaldırabilir ve uygulamayı kesintisiz kullanabilirsiniz. Ayrıca gelecekte eklenecek özel özelliklere de erişim kazanırsınız.',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // API Kaynak Ayarları
                    _buildSettingsCard(
                      title: 'Veri Kaynağı Ayarları',
                      icon: Icons.cloud_done,
                      iconColor: const Color(0xFF82E0F9),
                      children: [
                        // WAQI API bilgisi
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF82E0F9).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.public, color: Color(0xFF5BBCD9), size: 24),
                          ),
                          title: const Text(
                            'WAQI API',
                            style: TextStyle(fontWeight: FontWeight.bold),
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
          
          const SizedBox(height: 16),
          
          // Arka plan konum izinleri
                    _buildSettingsCard(
                      title: 'Arka Plan Konum İzinleri',
                      icon: Icons.location_on,
                      iconColor: const Color(0xFFF9CC3E),
                children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Text(
                    'Uygulamanın arka planda çalışırken de konum bilgilerinize erişmesi için gerekli izinleri kontrol edin.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: ElevatedButton.icon(
                    onPressed: () async {
                      final locationService = LocationService();
                      final hasPermission = await locationService.checkBackgroundLocationPermission(context);
                      
                      if (hasPermission) {
                        // İzinler tamam, servisi başlat
                        final platformService = PlatformService();
                        final success = await platformService.startLocationService();
                        
                                if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Arka plan konum servisi başlatıldı'),
                              backgroundColor: Colors.green,
                            ),
                          );
                                } else if (context.mounted) {
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
                              backgroundColor: const Color(0xFFF9CC3E),
                      foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            icon: const Icon(Icons.security),
                            label: const Text('İzinleri Kontrol Et'),
                          ),
                        ),
                      ],
          ),
          
          const SizedBox(height: 16),
          
          // Bildirim ayarları
                    _buildSettingsCard(
                      title: 'Bildirim Ayarları',
                      icon: Icons.notifications_active,
                      iconColor: Colors.red,
                children: [
                        SwitchListTile(
                          title: const Text(
                            'Bildirimleri Etkinleştir',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                    subtitle: const Text('Tehlikeli hava kalitesi bildirimleri alın'),
                    value: settings.notificationsEnabled,
                          activeColor: AppStyles.primaryColor,
                    onChanged: (value) {
                      settingsProvider.toggleNotifications(value);
                    },
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.notifications, color: Colors.red),
                          ),
                  ),
                  const Divider(),
                  ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.warning, color: Colors.orange),
                          ),
                          title: const Text(
                            'Bildirim Eşiği',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                    subtitle: Text('AQI ${settings.notificationThreshold} üzerinde bildirim al'),
                          trailing: SizedBox(
                            width: 120,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppStyles.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: DropdownButton<int>(
                      value: settings.notificationThreshold,
                                underline: const SizedBox(),
                                icon: const Icon(Icons.arrow_drop_down, color: AppStyles.primaryColor),
                                isExpanded: true,
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
                                    child: Text('100 (Hassas)'),
                        ),
                        DropdownMenuItem(
                          value: 150,
                          child: Text('150 (Sağlıksız)'),
                        ),
                        DropdownMenuItem(
                          value: 200,
                                    child: Text('200 (Çok S.)'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
          ),
          
          const SizedBox(height: 16),
          
          // Konum ayarları
                    _buildSettingsCard(
                      title: 'Konum Ayarları',
                      icon: Icons.location_searching,
                      iconColor: const Color(0xFF5BBCD9),
                children: [
                        SwitchListTile(
                          title: const Text(
                            'Arka Planda Konum Takibi',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                    subtitle: const Text('Uygulama kapalıyken konum güncellemelerini al'),
                    value: settings.backgroundLocationEnabled,
                          activeColor: AppStyles.primaryColor,
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
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5BBCD9).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.my_location, color: Color(0xFF5BBCD9)),
                          ),
                  ),
                  const Divider(),
                  ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF82E0F9).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.timer, color: Color(0xFF82E0F9)),
                          ),
                          title: const Text(
                            'Konum Güncelleme Aralığı',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                    subtitle: Text('${settings.locationUpdateInterval} dakikada bir güncelle'),
                          trailing: SizedBox(
                            width: 120,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppStyles.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: DropdownButton<int>(
                      value: settings.locationUpdateInterval,
                                underline: const SizedBox(),
                                icon: const Icon(Icons.arrow_drop_down, color: AppStyles.primaryColor),
                                isExpanded: true,
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
                    ),
                  ),
                  if (!locationProvider.hasPermission)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                            child: ElevatedButton.icon(
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
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                        ),
                              icon: const Icon(Icons.location_on),
                              label: const Text('Konum İzni Ver'),
                      ),
                    ),
                ],
          ),
          
          const SizedBox(height: 16),
          
          // Görünüm ayarları
                    _buildSettingsCard(
                      title: 'Görünüm Ayarları',
                      icon: Icons.palette,
                      iconColor: const Color(0xFFF9CC3E),
                      children: [
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9CC3E).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
                            child: const Icon(Icons.thermostat, color: Color(0xFFF9CC3E)),
                          ),
                          title: const Text(
                            'Sıcaklık Birimi',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: SizedBox(
                            width: 120,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppStyles.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: DropdownButton<String>(
                      value: settings.temperatureUnit,
                                underline: const SizedBox(),
                                icon: const Icon(Icons.arrow_drop_down, color: AppStyles.primaryColor),
                                isExpanded: true,
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
                    ),
                  ),
                  const Divider(),
                  ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF82E0F9).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.language, color: Color(0xFF82E0F9)),
                          ),
                          title: const Text(
                            'Dil',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: SizedBox(
                            width: 120,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppStyles.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: DropdownButton<String>(
                      value: settings.language,
                                underline: const SizedBox(),
                                icon: const Icon(Icons.arrow_drop_down, color: AppStyles.primaryColor),
                                isExpanded: true,
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
              ),
            ),
                      ],
          ),
          
          const SizedBox(height: 16),
          
          // Uygulama bilgileri
                    _buildSettingsCard(
                      title: 'Uygulama Bilgileri',
                      icon: Icons.info,
                      iconColor: Colors.purple,
                      children: [
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
                            child: const Icon(Icons.new_releases, color: Colors.purple),
                          ),
                          title: const Text(
                            'Uygulama Versiyonu',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                    subtitle: const Text('1.0.0'),
                  ),
                  const Divider(),
                  ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.cloud, color: Colors.blue),
                          ),
                          title: const Text(
                            'Veri Kaynakları',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                    subtitle: const Text('WAQI'),
                  ),
                  const Divider(),
                  ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.privacy_tip, color: Colors.teal),
                          ),
                          title: const Text(
                            'Gizlilik Politikası',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Gizlilik politikası sayfasına yönlendirme
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                            );
                    },
                  ),
                  const Divider(),
                  ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.description, color: Colors.amber),
                          ),
                          title: const Text(
                            'Kullanım Koşulları',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Kullanım koşulları sayfasına yönlendirme
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                            );
                    },
                  ),
                ],
              ),
                    
                    const SizedBox(height: 24),
                    
                    // Çıkış yap butonu
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          
                          // Konum güncellemelerini durdur
                          Provider.of<LocationProvider>(context, listen: false).stopLocationUpdates();
                          
                          // Bildirim dinlemeyi durdur
                          Provider.of<NotificationProvider>(context, listen: false).stopListeningNotifications();
                          
                          // Çıkış yap
                          await authProvider.signOut();
                          
                          if (context.mounted) {
                            // Giriş ekranına yönlendir
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text('Çıkış Yap'),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Ayarlar kartı widget'ı
  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // İçerik
          ...children,
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }
  
  // Premium satın alma dialog'u
  void _showPremiumDialog(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final purchaseService = PurchaseService();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.workspace_premium, color: Color(0xFFFFD700)),
                SizedBox(width: 8),
                Text('Premium Üyelik'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Premium üyelik avantajları:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('• Tüm reklamları kaldırır'),
                const Text('• Uygulamayı kesintisiz kullanabilirsiniz'),
                const Text('• Gelecekte eklenecek özel özelliklere erişim'),
                const SizedBox(height: 16),
                FutureBuilder(
                  future: purchaseService.initialize(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    
                    if (!purchaseService.isAvailable) {
                      return const Text(
                        'Satın alma servisi şu anda kullanılamıyor.',
                        style: TextStyle(color: Colors.red),
                      );
                    }
                    
                    final product = purchaseService.getRemoveAdsProduct();
                    
                    if (product == null) {
                      return const Text(
                        'Ürün bilgisi yüklenemedi.',
                        style: TextStyle(color: Colors.red),
                      );
                    }
                    
                    return Text(
                      'Premium üyelik ücreti: ${product.price}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Satın alma işlemini başlat
                  final bool success = await purchaseService.purchaseRemoveAds();
                  
                  if (success) {
                    // Satın alma işlemi başarıyla başlatıldı
                    // Sonuç, purchaseStream üzerinden dinleniyor
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Satın alma işlemi başlatıldı'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  } else {
                    // Satın alma işlemi başlatılamadı
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Satın alma işlemi başlatılamadı'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Satın Al'),
              ),
            ],
          );
        },
      ),
    );
  }
} 