import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import '../models/user_location_model.dart';

class LocationService {
  // Konum izinlerini kontrol etme ve isteme
  Future<bool> handleLocationPermission({required BuildContext context}) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Konum servislerinin etkin olup olmadığını kontrol et
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konum servisleri devre dışı. Lütfen konum servislerini etkinleştirin.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    // Konum izinlerini kontrol et
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konum izinleri reddedildi. Konum bilgisi alınamıyor.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konum izinleri kalıcı olarak reddedildi. Lütfen uygulama ayarlarından konum izinlerini etkinleştirin.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    return true;
  }

  // Kullanıcının mevcut konumunu alma
  Future<Position?> getCurrentPosition({required BuildContext context}) async {
    final hasPermission = await handleLocationPermission(context: context);
    
    if (!hasPermission) {
      return null;
    }
    
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Konum alınırken hata oluştu: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    }
  }

  // Konum güncellemelerini dinleme
  Stream<Position> getPositionStream({
    int distanceFilter = 100,
    Duration? timeLimit,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
        timeLimit: timeLimit,
      ),
    );
  }

  // Koordinatlardan adres bilgisi alma
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        // Adres bileşenlerini al
        String thoroughfare = place.thoroughfare ?? ''; // Cadde
        String subThoroughfare = place.subThoroughfare ?? ''; // Bina no
        String locality = place.locality ?? ''; // İlçe
        String administrativeArea = place.administrativeArea ?? ''; // İl
        String country = place.country ?? ''; // Ülke
        String postalCode = place.postalCode ?? ''; // Posta kodu
        
        // Adres bileşenlerini birleştir
        List<String> addressParts = [];
        
        // Cadde ve bina no
        String streetAddress = '';
        if (thoroughfare.isNotEmpty) {
          streetAddress = thoroughfare;
          if (subThoroughfare.isNotEmpty) {
            streetAddress += ' No: $subThoroughfare';
          }
        }
        
        if (streetAddress.isNotEmpty) addressParts.add(streetAddress);
        
        // İlçe ve il
        if (locality.isNotEmpty) {
          if (administrativeArea.isNotEmpty && locality != administrativeArea) {
            addressParts.add('$locality, $administrativeArea');
          } else {
            addressParts.add(locality);
          }
        } else if (administrativeArea.isNotEmpty) {
          addressParts.add(administrativeArea);
        }
        
        // Ülke
        if (country.isNotEmpty && addressParts.isNotEmpty) {
          addressParts.add(country);
        }
        
        // Adres parçalarını birleştir
        String fullAddress = addressParts.join(', ');
        
        print('Adres alındı: $fullAddress');
        return fullAddress.isNotEmpty ? fullAddress : 'Bilinmeyen Konum';
      }
      
      return 'Bilinmeyen Konum';
    } catch (e) {
      print('Adres alınırken hata oluştu: $e');
      return 'Adres Bulunamadı';
    }
  }

  // Kullanıcı konum modeli oluşturma
  Future<UserLocationModel> createUserLocationModel(String userId, Position position) async {
    final String address = await getAddressFromCoordinates(position.latitude, position.longitude);
    
    return UserLocationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
      timestamp: DateTime.now(),
      isCurrentLocation: true,
    );
  }

  // İki konum arasındaki mesafeyi hesaplama (metre cinsinden)
  double calculateDistance(double startLatitude, double startLongitude, double endLatitude, double endLongitude) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
  
  // Konum ayarlarını açma
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
  
  // Uygulama ayarlarını açma
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  // Arka plan konum izinlerini kontrol etme
  Future<bool> checkBackgroundLocationPermission(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Konum servisi açık mı kontrol et
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Konum servisi kapalıysa kullanıcıya sor
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Konum Servisi Kapalı'),
          content: const Text('Arka planda konum takibi için konum servisini açmanız gerekiyor.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openLocationSettings();
              },
              child: const Text('Ayarları Aç'),
            ),
          ],
        ),
      );
      return false;
    }

    // Konum izni kontrol et
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // İzin reddedildi
        return false;
      }
    }
    
    // Arka plan konum izni kontrol et
    if (permission == LocationPermission.deniedForever) {
      // İzin kalıcı olarak reddedildi
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Konum İzni Reddedildi'),
          content: const Text('Arka planda konum takibi için uygulama ayarlarından konum iznini vermeniz gerekiyor.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openAppSettings();
              },
              child: const Text('Ayarları Aç'),
            ),
          ],
        ),
      );
      return false;
    }
    
    // Android 10 ve üzeri için arka plan konum izni kontrol et
    if (permission == LocationPermission.whileInUse) {
      // Arka plan izni yok, sadece ön planda izin var
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Arka Plan Konum İzni Gerekli'),
          content: const Text('Uygulamanın arka planda çalışırken de konum bilgilerinize erişmesi için "Her zaman izin ver" seçeneğini seçmeniz gerekiyor.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openAppSettings();
              },
              child: const Text('Ayarları Aç'),
            ),
          ],
        ),
      );
      return false;
    }
    
    return true;
  }
} 