import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/background_service.dart';
import '../models/user_settings_model.dart';

class SettingsProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final BackgroundService _backgroundService = BackgroundService();
  
  UserSettingsModel? _settings;
  bool _isLoading = false;
  String _error = '';

  // Getters
  UserSettingsModel? get settings => _settings;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get hasSettings => _settings != null;

  // Kullanıcı ayarlarını alma
  Future<void> getUserSettings(String userId) async {
    if (_isLoading) return; // Zaten yükleniyor ise tekrar çağrılmasını engelle
    
    _isLoading = true;
    // build sırasında çağrılırsa hata verebilir, bu yüzden Future.microtask kullanıyoruz
    Future.microtask(() => notifyListeners());

    try {
      _settings = await _firebaseService.getUserSettings(userId);
      
      if (_settings != null) {
        // Arka plan görevlerini ayarla
        await _backgroundService.updateTasksBasedOnSettings(_settings!);
      } else {
        // Varsayılan ayarları oluştur
        _settings = UserSettingsModel.createDefaultSettings(userId);
        await _firebaseService.saveUserSettings(_settings!);
      }
    } catch (e) {
      _error = 'Kullanıcı ayarları alınırken hata oluştu: $e';
    }

    _isLoading = false;
    // build sırasında çağrılırsa hata verebilir, bu yüzden Future.microtask kullanıyoruz
    Future.microtask(() => notifyListeners());
  }

  // Bildirimleri etkinleştirme/devre dışı bırakma
  Future<void> toggleNotifications(bool enabled) async {
    if (_settings == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedSettings = _settings!.copyWith(
        notificationsEnabled: enabled,
      );
      
      await _firebaseService.updateUserSettings(updatedSettings);
      await _backgroundService.updateTasksBasedOnSettings(updatedSettings);
      
      _settings = updatedSettings;
    } catch (e) {
      _error = 'Bildirim ayarları güncellenirken hata oluştu: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Arka plan konum güncellemelerini etkinleştirme/devre dışı bırakma
  Future<void> toggleBackgroundLocation(bool enabled) async {
    if (_settings == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedSettings = _settings!.copyWith(
        backgroundLocationEnabled: enabled,
      );
      
      await _firebaseService.updateUserSettings(updatedSettings);
      await _backgroundService.updateTasksBasedOnSettings(updatedSettings);
      
      _settings = updatedSettings;
    } catch (e) {
      _error = 'Arka plan konum ayarları güncellenirken hata oluştu: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Bildirim eşik değerini güncelleme
  Future<void> updateNotificationThreshold(int threshold) async {
    if (_settings == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedSettings = _settings!.copyWith(
        notificationThreshold: threshold,
      );
      
      await _firebaseService.updateUserSettings(updatedSettings);
      
      _settings = updatedSettings;
    } catch (e) {
      _error = 'Bildirim eşik değeri güncellenirken hata oluştu: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Konum güncelleme aralığını güncelleme
  Future<void> updateLocationUpdateInterval(int intervalMinutes) async {
    if (_settings == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedSettings = _settings!.copyWith(
        locationUpdateInterval: intervalMinutes,
      );
      
      await _firebaseService.updateUserSettings(updatedSettings);
      await _backgroundService.updateTasksBasedOnSettings(updatedSettings);
      
      _settings = updatedSettings;
    } catch (e) {
      _error = 'Konum güncelleme aralığı güncellenirken hata oluştu: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Favori konumları güncelleme
  Future<void> updateFavoriteLocations(List<String> favoriteLocations) async {
    if (_settings == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedSettings = _settings!.copyWith(
        favoriteLocations: favoriteLocations,
      );
      
      await _firebaseService.updateUserSettings(updatedSettings);
      
      _settings = updatedSettings;
    } catch (e) {
      _error = 'Favori konumlar güncellenirken hata oluştu: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Sıcaklık birimini güncelleme
  Future<void> updateTemperatureUnit(String unit) async {
    if (_settings == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedSettings = _settings!.copyWith(
        temperatureUnit: unit,
      );
      
      await _firebaseService.updateUserSettings(updatedSettings);
      
      _settings = updatedSettings;
    } catch (e) {
      _error = 'Sıcaklık birimi güncellenirken hata oluştu: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Dil ayarını güncelleme
  Future<void> updateLanguage(String language) async {
    if (_settings == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedSettings = _settings!.copyWith(
        language: language,
      );
      
      await _firebaseService.updateUserSettings(updatedSettings);
      
      _settings = updatedSettings;
    } catch (e) {
      _error = 'Dil ayarı güncellenirken hata oluştu: $e';
    }

    _isLoading = false;
    notifyListeners();
  }
  
  // API kaynağını etkinleştirme/devre dışı bırakma
  Future<void> toggleApiSource(String source, bool enabled) async {
    if (_settings == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Mevcut API kaynaklarını kopyala
      final Map<String, bool> updatedApiSources = Map.from(_settings!.enabledApiSources);
      
      // Belirtilen kaynağı güncelle
      updatedApiSources[source] = enabled;
      
      // En az bir kaynak etkin olmalı
      if (!updatedApiSources.containsValue(true)) {
        _error = 'En az bir API kaynağı etkin olmalıdır';
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      final updatedSettings = _settings!.copyWith(
        enabledApiSources: updatedApiSources,
      );
      
      await _firebaseService.updateUserSettings(updatedSettings);
      
      _settings = updatedSettings;
    } catch (e) {
      _error = 'API kaynağı ayarları güncellenirken hata oluştu: $e';
    }

    _isLoading = false;
    notifyListeners();
  }
  
  // Tercih edilen API kaynağını güncelleme
  Future<void> updatePreferredApiSource(String source) async {
    if (_settings == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Seçilen kaynak etkin değilse hata ver
      if (!_settings!.isApiSourceEnabled(source)) {
        _error = 'Seçilen API kaynağı etkin değil';
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      final updatedSettings = _settings!.copyWith(
        preferredApiSource: source,
      );
      
      await _firebaseService.updateUserSettings(updatedSettings);
      
      _settings = updatedSettings;
    } catch (e) {
      _error = 'Tercih edilen API kaynağı güncellenirken hata oluştu: $e';
    }

    _isLoading = false;
    notifyListeners();
  }
  
  // API sonuçlarını birleştirme ayarını güncelleme
  Future<void> toggleMergeApiResults(bool merge) async {
    if (_settings == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedSettings = _settings!.copyWith(
        mergeApiResults: merge,
      );
      
      await _firebaseService.updateUserSettings(updatedSettings);
      
      _settings = updatedSettings;
    } catch (e) {
      _error = 'API sonuçları birleştirme ayarı güncellenirken hata oluştu: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Hata mesajını temizleme
  void clearError() {
    _error = '';
    notifyListeners();
  }
} 