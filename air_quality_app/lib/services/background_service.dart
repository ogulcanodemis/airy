// import 'package:workmanager/workmanager.dart'; // Geçici olarak devre dışı bırakıldı
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:async'; // Timer için import
import '../main.dart'; // navigatorKey için import
import 'location_service.dart';
import 'air_quality_service.dart';
import 'firebase_service.dart';
import 'notification_service.dart';
import 'platform_service.dart'; // Platform Service için import
import '../models/user_settings_model.dart';
import '../models/notification_model.dart'; // NotificationModel için import
import 'package:provider/provider.dart';
import '../providers/air_quality_provider.dart';

// Arka plan görev tanımlayıcıları
const String checkAirQualityTask = 'checkAirQuality';
const String updateLocationTask = 'updateLocation';

// Arka plan görevlerini yönetme sınıfı
class BackgroundService {
  // Singleton pattern
  static final BackgroundService _instance = BackgroundService._internal();
  
  // Zamanlayıcılar
  Timer? _airQualityTimer;
  Timer? _locationTimer;
  
  // Platform servisi
  final PlatformService _platformService = PlatformService();
  
  // Varsayılan aralıklar (dakika)
  static const int defaultAirQualityInterval = 15;
  static const int defaultLocationInterval = 15;
  
  factory BackgroundService() {
    return _instance;
  }
  
  BackgroundService._internal();

  // Arka plan servisini başlatma
  Future<void> init() async {
    print('Arka plan servisi başlatılıyor (Timer tabanlı)...');
    
    // Test bildirimi için zamanlayıcı başlat
    _startTestNotificationTimer();
    
    // Kullanıcı oturum açmış mı kontrol et
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Kullanıcı ayarlarını al
      final firebaseService = FirebaseService();
      final settings = await firebaseService.getUserSettings(user.uid);
      
      if (settings != null) {
        // Ayarlara göre zamanlayıcıları başlat
        if (settings.notificationsEnabled) {
          registerAirQualityCheck(settings.notificationThreshold);
        }
        
        if (settings.backgroundLocationEnabled) {
          registerLocationUpdate(settings.locationUpdateInterval);
          
          // Konum izinleri varsa Foreground Service'i başlat
          if (navigatorKey.currentContext != null) {
            final locationService = LocationService();
            final hasPermission = await locationService.checkBackgroundLocationPermission(navigatorKey.currentContext!);
            
            if (hasPermission) {
              // Foreground servisi başlat
              await _platformService.startLocationService();
            }
          }
        }
      } else {
        // Varsayılan ayarlarla başlat
        registerAirQualityCheck(defaultAirQualityInterval);
        registerLocationUpdate(defaultLocationInterval);
      }
    }
    
    print('Arka plan servisi başlatıldı (Timer tabanlı)');
  }

  // Periyodik hava kalitesi kontrolü görevini kaydetme
  Future<void> registerAirQualityCheck(int intervalMinutes) async {
    print('Hava kalitesi kontrolü zamanlayıcısı başlatılıyor...');
    
    // Önceki zamanlayıcıyı iptal et
    _airQualityTimer?.cancel();
    
    // Yeni zamanlayıcı oluştur
    _airQualityTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (timer) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          print('Zamanlayıcı: Hava kalitesi kontrolü yapılıyor...');
          await checkAirQualityManually(user.uid);
        } else {
          // Kullanıcı oturumu kapatmışsa zamanlayıcıyı durdur
          timer.cancel();
        }
      },
    );
    
    print('Hava kalitesi kontrolü zamanlayıcısı başlatıldı (${intervalMinutes} dakika aralıkla)');
    
    // İlk kontrolü hemen yap
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await checkAirQualityManually(user.uid);
    }
  }

  // Periyodik konum güncelleme görevini kaydetme
  Future<void> registerLocationUpdate(int intervalMinutes) async {
    print('Konum güncelleme zamanlayıcısı başlatılıyor...');
    
    // Önceki zamanlayıcıyı iptal et
    _locationTimer?.cancel();
    
    // Yeni zamanlayıcı oluştur
    _locationTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (timer) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          print('Zamanlayıcı: Konum güncelleniyor...');
          await updateLocationManually(user.uid);
        } else {
          // Kullanıcı oturumu kapatmışsa zamanlayıcıyı durdur
          timer.cancel();
        }
      },
    );
    
    print('Konum güncelleme zamanlayıcısı başlatıldı (${intervalMinutes} dakika aralıkla)');
    
    // İlk güncellemeyi hemen yap
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await updateLocationManually(user.uid);
    }
  }

  // Görevleri iptal etme
  Future<void> cancelAllTasks() async {
    print('Tüm zamanlayıcılar durduruluyor...');
    
    _airQualityTimer?.cancel();
    _locationTimer?.cancel();
    
    _airQualityTimer = null;
    _locationTimer = null;
    
    // Foreground servisi durdur
    await _platformService.stopLocationService();
    
    print('Tüm zamanlayıcılar durduruldu');
  }

  // Kullanıcı ayarlarına göre görevleri güncelleme
  Future<void> updateTasksBasedOnSettings(UserSettingsModel settings) async {
    print('Zamanlayıcılar ayarlara göre güncelleniyor...');
    
    // Hava kalitesi kontrolü zamanlayıcısı
    if (settings.notificationsEnabled) {
      await registerAirQualityCheck(settings.notificationThreshold);
    } else {
      _airQualityTimer?.cancel();
      _airQualityTimer = null;
    }
    
    // Konum güncelleme zamanlayıcısı
    if (settings.backgroundLocationEnabled) {
      await registerLocationUpdate(settings.locationUpdateInterval);
    } else {
      _locationTimer?.cancel();
      _locationTimer = null;
    }
    
    print('Zamanlayıcılar ayarlara göre güncellendi');
  }
  
  // Manuel olarak hava kalitesi kontrolü yapma
  Future<void> checkAirQualityManually(String userId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await _performAirQualityCheck(user.uid);
    } catch (e) {
      print('Manuel hava kalitesi kontrolü hatası: $e');
    }
  }
  
  // Manuel olarak konum güncelleme
  Future<void> updateLocationManually(String userId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await _performLocationUpdate(user.uid);
    } catch (e) {
      print('Manuel konum güncelleme hatası: $e');
    }
  }
  
  // Servis durumunu kontrol etme
  bool isRunning() {
    return _airQualityTimer != null || _locationTimer != null;
  }
  
  // Uygulama kapatıldığında zamanlayıcıları durdurma
  void dispose() {
    cancelAllTasks();
  }

  // Test bildirimi için zamanlayıcı
  void _startTestNotificationTimer() {
    print('Test bildirimi zamanlayıcısı başlatılıyor (1 dakika sonra)...');
    Timer(const Duration(minutes: 1), () {
      _sendTestNotification();
    });
  }
  
  // Test bildirimi gönderme
  Future<void> _sendTestNotification() async {
    print('Test bildirimi gönderiliyor...');
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print('Test bildirimi gönderilemedi: Kullanıcı oturum açmamış');
        return;
      }
      
      // Firestore'a test bildirimi kaydet
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        title: 'Test Bildirimi',
        body: 'Bu bir test bildirimidir. Uygulama arka planda çalışırken bildirim alabiliyorsanız, bildirim sistemi düzgün çalışıyor demektir.',
        timestamp: DateTime.now(),
        isRead: false,
        type: 'info',
        data: {
          'type': 'test_notification',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      final firebaseService = FirebaseService();
      await firebaseService.saveNotification(notification);
      print('Test bildirimi Firestore\'a kaydedildi');
      
      // Firebase Cloud Functions tarafından otomatik olarak bildirim gönderilecek
    } catch (e) {
      print('Test bildirimi gönderilirken hata oluştu: $e');
    }
  }
}

// Hava kalitesi kontrolü yapma
Future<void> _performAirQualityCheck(String userId) async {
  try {
    final firebaseService = FirebaseService();
    final airQualityProvider = Provider.of<AirQualityProvider>(navigatorKey.currentContext!, listen: false);
    final notificationService = NotificationService();
    
    // Kullanıcı ayarlarını al
    final settings = await firebaseService.getUserSettings(userId);
    if (settings == null || !settings.notificationsEnabled) {
      return;
    }
    
    // Kullanıcının mevcut konumunu al
    final userLocation = await firebaseService.getCurrentUserLocation(userId);
    if (userLocation == null) {
      return;
    }
    
    await airQualityProvider.getAirQualityByLocation(
      userLocation.latitude,
      userLocation.longitude,
      userId,
      context: navigatorKey.currentContext,
      settings: settings,
    );
    
    final airQuality = airQualityProvider.currentAirQuality;
    
    if (airQuality == null) {
      return;
    }
    
    // Hava kalitesi tehlikeli seviyede mi kontrol et
    if (airQuality.aqi > settings.notificationThreshold) {
      // Bildirim gönder
      await notificationService.sendDangerousAirQualityNotification(
        userId: userId,
        location: userLocation.address,
        aqi: airQuality.aqi,
        category: airQuality.category,
      );
      
      // Uygulama açıksa bildirim göster
      if (navigatorKey.currentContext != null) {
        notificationService.showNotification(
          navigatorKey.currentContext!,
          'Tehlikeli Hava Kalitesi',
          '${userLocation.address} bölgesinde hava kalitesi tehlikeli seviyede (AQI: ${airQuality.aqi}).',
          type: 'danger',
        );
      }
    }
  } catch (e) {
    print('Hava kalitesi kontrolü hatası: $e');
  }
}

// Konum güncelleme
Future<void> _performLocationUpdate(String userId) async {
  try {
    final locationService = LocationService();
    final firebaseService = FirebaseService();
    
    // Kullanıcı ayarlarını al
    final settings = await firebaseService.getUserSettings(userId);
    if (settings == null || !settings.backgroundLocationEnabled) {
      return;
    }
    
    // navigatorKey null olabilir, bu durumda konum alma işlemi yapma
    if (navigatorKey.currentContext == null) {
      print('Context bulunamadı, konum alınamıyor');
      return;
    }
    
    // Mevcut konumu al
    final position = await locationService.getCurrentPosition(
      context: navigatorKey.currentContext!,
    );
    if (position == null) {
      return;
    }
    
    // Kullanıcı konum modeli oluştur
    final locationModel = await locationService.createUserLocationModel(userId, position);
    
    // Konumu kaydet
    await firebaseService.saveUserLocation(locationModel);
  } catch (e) {
    print('Konum güncelleme hatası: $e');
  }
} 