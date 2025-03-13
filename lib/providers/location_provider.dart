import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/firebase_service.dart';
import '../models/user_location_model.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  final FirebaseService _firebaseService = FirebaseService();
  
  Position? _currentPosition;
  UserLocationModel? _userLocation;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isLoading = false;
  String _error = '';
  bool _hasPermission = false;

  // Getters
  Position? get currentPosition => _currentPosition;
  UserLocationModel? get userLocation => _userLocation;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get hasPermission => _hasPermission;
  bool get hasLocation => _currentPosition != null;

  // Konum izinlerini kontrol etme
  Future<bool> checkLocationPermission(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      _hasPermission = await _locationService.handleLocationPermission(context: context);
    } catch (e) {
      _error = 'Konum izinleri kontrol edilirken hata oluştu: $e';
      _hasPermission = false;
    }

    _isLoading = false;
    notifyListeners();
    return _hasPermission;
  }

  // Mevcut konumu alma
  Future<void> getCurrentLocation(BuildContext context, {String? userId}) async {
    if (!_hasPermission) {
      _hasPermission = await checkLocationPermission(context);
      if (!_hasPermission) return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _currentPosition = await _locationService.getCurrentPosition(context: context);
      
      // Konum alındıktan sonra adres bilgisini de al
      if (_currentPosition != null && userId != null) {
        final locationModel = await _locationService.createUserLocationModel(userId, _currentPosition!);
        _userLocation = locationModel;
        
        print('Konum alındı: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
        print('Adres: ${_userLocation!.address}');
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Konum alınırken hata oluştu: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Konum güncellemelerini dinlemeye başlama
  void startLocationUpdates(String userId, {int distanceFilter = 100, int intervalMinutes = 15}) {
    if (!_hasPermission) return;

    // Önceki aboneliği iptal et
    stopLocationUpdates();

    // Yeni abonelik oluştur
    _positionStreamSubscription = _locationService.getPositionStream(
      distanceFilter: distanceFilter,
      timeLimit: Duration(minutes: intervalMinutes),
    ).listen((Position position) async {
      _currentPosition = position;
      
      // Kullanıcı konum modeli oluştur
      final locationModel = await _locationService.createUserLocationModel(userId, position);
      _userLocation = locationModel;
      
      // Firestore'a kaydet
      await _firebaseService.saveUserLocation(locationModel);
      
      notifyListeners();
    }, onError: (e) {
      _error = 'Konum güncellemesi alınırken hata oluştu: $e';
      notifyListeners();
    });
  }

  // Konum güncellemelerini dinlemeyi durdurma
  void stopLocationUpdates() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  // Kullanıcının son konumunu Firestore'dan alma
  Future<void> getUserLastLocation(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _userLocation = await _firebaseService.getCurrentUserLocation(userId);
      
      if (_userLocation != null) {
        _currentPosition = Position(
          latitude: _userLocation!.latitude,
          longitude: _userLocation!.longitude,
          timestamp: _userLocation!.timestamp,
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
    } catch (e) {
      _error = 'Kullanıcı konumu alınırken hata oluştu: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // İki konum arasındaki mesafeyi hesaplama
  double calculateDistance(double startLatitude, double startLongitude, double endLatitude, double endLongitude) {
    return _locationService.calculateDistance(startLatitude, startLongitude, endLatitude, endLongitude);
  }

  // Hata mesajını temizleme
  void clearError() {
    _error = '';
    notifyListeners();
  }

  @override
  void dispose() {
    stopLocationUpdates();
    super.dispose();
  }
} 