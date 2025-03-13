import 'package:flutter/material.dart';
import '../services/air_quality_service.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../models/air_quality_model.dart';
import '../models/user_settings_model.dart';

class AirQualityProvider with ChangeNotifier {
  final AirQualityService _airQualityService = AirQualityService();
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();
  
  AirQualityModel? _currentAirQuality;
  Map<String, AirQualityModel?> _sourceAirQuality = {}; // Farklı kaynaklardan gelen veriler
  List<AirQualityModel> _airQualityHistory = [];
  bool _isLoading = false;
  String _error = '';

  // Getters
  AirQualityModel? get currentAirQuality => _currentAirQuality;
  Map<String, AirQualityModel?> get sourceAirQuality => _sourceAirQuality;
  List<AirQualityModel> get airQualityHistory => _airQualityHistory;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get hasAirQualityData => _currentAirQuality != null;
  bool get hasMultipleSourceData => _sourceAirQuality.values.where((v) => v != null).length > 1;

  // Belirli bir kaynaktan hava kalitesi verisi alma
  AirQualityModel? getAirQualityFromSource(String source) {
    return _sourceAirQuality[source];
  }

  // Mevcut konuma göre hava kalitesi verilerini alma
  Future<void> getAirQualityByLocation(double latitude, double longitude, String userId, {
    BuildContext? context,
    required UserSettingsModel settings,
    bool isAdmin = false,
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      print('Hava kalitesi verileri alınıyor... (Konum: $latitude, $longitude)');
      
      // Sadece WAQI API'sini kullan
      final sourceResults = await _airQualityService.getAirQualityFromAllSources(
        latitude, 
        longitude,
        enabledSources: ['WAQI'],
      );
      
      // Sonuçları kaydet
      _sourceAirQuality = sourceResults;
      
      // WAQI verilerini ana veri olarak ayarla
      _currentAirQuality = _sourceAirQuality['WAQI'];
      
      if (_currentAirQuality == null) {
        _error = 'WAQI API\'den veri alınamadı. Lütfen daha sonra tekrar deneyin.';
        print(_error);
      } else {
        print('WAQI API\'den veri alındı. AQI: ${_currentAirQuality!.aqi}');
        
        // Firestore'a kaydet (sadece admin kullanıcılar için)
        try {
          if (isAdmin) {
            await _firebaseService.saveAirQualityData(_currentAirQuality!);
            print('Hava kalitesi verisi Firestore\'a kaydedildi');
          } else {
            print('Hava kalitesi verisi Firestore\'a kaydedilmedi: Kullanıcı admin değil');
          }
        } catch (e) {
          print('Hava kalitesi verisi Firestore\'a kaydedilemedi: $e');
        }
        
        // Tehlikeli seviyede mi kontrol et
        if (settings.notificationsEnabled && _airQualityService.isAirQualityDangerous(_currentAirQuality!, settings.notificationThreshold)) {
          // Bildirim gönder
          await _notificationService.sendDangerousAirQualityNotification(
            userId: userId,
            location: _currentAirQuality!.location,
            aqi: _currentAirQuality!.aqi,
            category: _currentAirQuality!.category,
          );
          
          // Uygulama açıkken bildirim göster
          _notificationService.showNotification(
            context,
            'Tehlikeli Hava Kalitesi',
            '${_currentAirQuality!.location} bölgesinde hava kalitesi tehlikeli seviyede (AQI: ${_currentAirQuality!.aqi}).',
            type: 'danger',
          );
        }
      }
    } catch (e) {
      _error = 'Hava kalitesi verisi alınırken hata oluştu: $e';
      
      // Hata durumunda Firestore'dan son verileri almayı dene
      await getAirQualityFromFirestore(latitude, longitude);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Firestore'dan hava kalitesi verilerini alma
  Future<void> getAirQualityFromFirestore(double latitude, double longitude) async {
    _isLoading = true;
    notifyListeners();

    try {
      final airQuality = await _firebaseService.getLatestAirQualityData(latitude, longitude);
      
      if (airQuality != null) {
        _currentAirQuality = airQuality;
        _sourceAirQuality = {airQuality.source: airQuality};
      } else {
        _error = 'Hava kalitesi verisi bulunamadı';
      }
    } catch (e) {
      _error = 'Hava kalitesi verisi alınırken hata oluştu: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Hava kalitesi geçmişini alma
  Future<void> getAirQualityHistory(double latitude, double longitude) async {
    // Bu fonksiyon, gerçek bir uygulamada Firestore'dan geçmiş verileri alacaktır
    // Şimdilik basit bir örnek olarak boş bir liste döndürüyoruz
    _airQualityHistory = [];
    notifyListeners();
  }

  // Hava kalitesi kategorisine göre renk döndürme
  Color getAirQualityColor(String category) {
    switch (category) {
      case 'İyi':
        return Colors.green;
      case 'Orta':
        return Colors.yellow;
      case 'Hassas Gruplar İçin Sağlıksız':
        return Colors.orange;
      case 'Sağlıksız':
        return Colors.red;
      case 'Çok Sağlıksız':
        return Colors.purple;
      case 'Tehlikeli':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  // Hava kalitesi kategorisine göre tavsiye döndürme
  String getAirQualityAdvice(String category) {
    switch (category) {
      case 'İyi':
        return 'Hava kalitesi iyi. Dışarıda aktivite yapmak için uygun bir gün.';
      case 'Orta':
        return 'Hava kalitesi kabul edilebilir düzeyde. Hassas gruplar için bazı kirleticiler sorun olabilir.';
      case 'Hassas Gruplar İçin Sağlıksız':
        return 'Hassas gruplar (astım hastaları, yaşlılar, çocuklar) sağlık etkileri yaşayabilir. Uzun süreli dış mekan aktivitelerini sınırlayın.';
      case 'Sağlıksız':
        return 'Herkes sağlık etkileri yaşayabilir. Hassas gruplar ciddi sağlık etkileri yaşayabilir. Dış mekan aktivitelerini sınırlayın.';
      case 'Çok Sağlıksız':
        return 'Sağlık uyarısı: Herkes daha ciddi sağlık etkileri yaşayabilir. Tüm dış mekan aktivitelerini sınırlayın.';
      case 'Tehlikeli':
        return 'Acil durum koşulları. Tüm nüfus etkilenebilir. Dış mekan aktivitelerinden kaçının ve pencerelerinizi kapalı tutun.';
      default:
        return 'Hava kalitesi verisi mevcut değil.';
    }
  }
  
  // Kaynak adına göre ikon döndürme
  IconData getSourceIcon(String source) {
    return _airQualityService.getSourceIcon(source);
  }
  
  // Kaynak adına göre renk döndürme
  Color getSourceColor(String source) {
    return _airQualityService.getSourceColor(source);
  }

  // Hata mesajını temizleme
  void clearError() {
    _error = '';
    notifyListeners();
  }
} 