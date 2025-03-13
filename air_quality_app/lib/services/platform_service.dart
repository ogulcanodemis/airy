import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class PlatformService {
  static const MethodChannel _channel = MethodChannel('com.airquality.air_quality_app/background_service');
  
  // Singleton pattern
  static final PlatformService _instance = PlatformService._internal();
  
  factory PlatformService() {
    return _instance;
  }
  
  PlatformService._internal();
  
  // Konum servisini başlatma
  Future<bool> startLocationService() async {
    try {
      // Önce konum izinlerini kontrol et
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Konum izinleri reddedildi. Foreground Service başlatılamıyor.');
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('Konum izinleri kalıcı olarak reddedildi. Foreground Service başlatılamıyor.');
        return false;
      }
      
      final bool result = await _channel.invokeMethod('startLocationService');
      print('Konum servisi başlatıldı: $result');
      return result;
    } on PlatformException catch (e) {
      print('Konum servisi başlatılırken hata oluştu: ${e.message}');
      return false;
    }
  }
  
  // Konum servisini durdurma
  Future<bool> stopLocationService() async {
    try {
      final bool result = await _channel.invokeMethod('stopLocationService');
      print('Konum servisi durduruldu: $result');
      return result;
    } on PlatformException catch (e) {
      print('Konum servisi durdurulurken hata oluştu: ${e.message}');
      return false;
    }
  }
} 