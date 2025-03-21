import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/air_quality_model.dart';

class AirQualityService {
  // API anahtarları
  final String _waqiApiKey = 'd1ab1cb70a638cbd4584526599ee41577429a61f'; // WAQI API anahtarı
  final String _googleApiKey = 'AIzaSyDrU9GpzXduTW8ITmiW_py1fWFl8xysdHk'; // Google API anahtarı (artık kullanılmıyor)
  
  // API URL'leri
  final String _waqiBaseUrl = 'https://api.waqi.info/feed';
  final String _openAQBaseUrl = 'https://api.openaq.org/v2/latest'; // Artık kullanılmıyor
  final String _googleBaseUrl = 'https://airquality.googleapis.com/v1/currentConditions'; // Artık kullanılmıyor
  final String _openMeteoBaseUrl = 'https://api.open-meteo.com/v1'; // Open-Meteo API URL'si
  
  // HTTP istemcileri
  final http.Client _httpClient = http.Client();
  final Dio _dio = Dio();
  
  // Desteklenen API kaynakları
  static const String SOURCE_WAQI = 'WAQI';
  static const String SOURCE_OPENAQ = 'OpenAQ'; // Artık kullanılmıyor
  static const String SOURCE_GOOGLE = 'Google'; // Artık kullanılmıyor
  
  // Belirli bir konuma göre hava kalitesi verilerini alma (background_service.dart için)
  Future<AirQualityModel?> getAirQualityByLocation(
    double latitude, 
    double longitude, 
    {BuildContext? context}
  ) async {
    try {
      print('Hava kalitesi verisi alınıyor (getAirQualityByLocation)... (Konum: $latitude, $longitude)');
      
      // Sadece WAQI API'den hava kalitesi verisi al
      AirQualityModel? aqiModel = await getAirQualityFromWAQI(latitude, longitude);
      
      // Open-Meteo'dan hava durumu verisi al
      if (aqiModel != null) {
        try {
          print('Open-Meteo\'dan hava durumu verisi alınıyor...');
          final weatherData = await getWeatherFromOpenMeteo(latitude, longitude);
          final forecastDataList = await getForecastFromOpenMeteo(latitude, longitude);
          
          // forecastData'yı Map formatına dönüştür
          final Map<String, dynamic> forecastData = {'weather': forecastDataList};
          
          print('Open-Meteo\'den alınan tahmin verisi: ${forecastData['weather']}');
          
          if (!weatherData.isEmpty) {
            print('Open-Meteo hava durumu verisi: $weatherData');
            
            // Modeldeki hava durumu verilerini güncelle
            aqiModel.weather.addAll(weatherData);
            
            // Ek veriler içerisine weatherData ekle
            if (aqiModel.additionalData != null) {
              aqiModel.additionalData!['weatherData'] = weatherData;
              aqiModel.additionalData!['weatherData']['source'] = 'Open-Meteo';
              aqiModel.additionalData!['hasWeatherData'] = true;
            }
            
            // Tahmin verilerini ekle
            if (forecastData.isNotEmpty && forecastData.containsKey('weather')) {
              if (aqiModel.additionalData != null) {
                aqiModel.additionalData!['weatherData']['forecast'] = forecastData;
                aqiModel.additionalData!['weatherData']['hasWeeklyForecast'] = true;
              }
              
              // AirQualityModel içindeki forecast alanını da güncelle
              if (forecastData.containsKey('weather') && forecastData['weather'] != null) {
                aqiModel.forecast['weather'] = forecastData['weather'] as dynamic;
              }
            }
          }
        } catch (e) {
          print('Open-Meteo hava durumu verisi alınırken hata: $e');
          // Hata durumunda WAQI'deki hava durumu verileri kullanılacak (eğer varsa)
        }
      }
      
      return aqiModel;
    } catch (e) {
      print('Hava kalitesi verisi alınırken hata oluştu: $e');
      return null;
    }
  }
  
  // Tüm API kaynaklarından hava kalitesi verilerini alma
  Future<Map<String, AirQualityModel?>> getAirQualityFromAllSources(double latitude, double longitude, {List<String>? enabledSources}) async {
    print('WAQI kaynağından hava kalitesi verileri alınıyor...');
    
    Map<String, AirQualityModel?> results = {};
    
    // Sadece WAQI API'den veri al
    try {
      results[SOURCE_WAQI] = await getAirQualityFromWAQI(latitude, longitude);
      print('WAQI API\'den veri alındı: ${results[SOURCE_WAQI] != null ? 'Başarılı' : 'Başarısız'}');
      
      // WAQI verisi başarıyla alındıysa, Open-Meteo'dan hava durumu verisini al
      if (results[SOURCE_WAQI] != null) {
        try {
          print('Open-Meteo\'dan hava durumu verisi alınıyor...');
          final weatherData = await getWeatherFromOpenMeteo(latitude, longitude);
          final forecastDataList = await getForecastFromOpenMeteo(latitude, longitude);
          
          // forecastData'yı Map formatına dönüştür
          final Map<String, dynamic> forecastData = {'weather': forecastDataList};
          
          print('Open-Meteo\'den alınan tahmin verisi: ${forecastData['weather']}');
          
          if (!weatherData.isEmpty) {
            print('Open-Meteo hava durumu verisi: $weatherData');
            
            // Modeldeki hava durumu verilerini güncelle
            results[SOURCE_WAQI]!.weather.addAll(weatherData);
            
            // Ek veriler içerisine weatherData ekle
            if (results[SOURCE_WAQI]!.additionalData != null) {
              results[SOURCE_WAQI]!.additionalData!['weatherData'] = weatherData;
              results[SOURCE_WAQI]!.additionalData!['weatherData']['source'] = 'Open-Meteo';
              results[SOURCE_WAQI]!.additionalData!['hasWeatherData'] = true;
            }
            
            // Tahmin verilerini ekle
            if (forecastData.isNotEmpty && forecastData.containsKey('weather')) {
              if (results[SOURCE_WAQI]!.additionalData != null) {
                results[SOURCE_WAQI]!.additionalData!['weatherData']['forecast'] = forecastData;
                results[SOURCE_WAQI]!.additionalData!['weatherData']['hasWeeklyForecast'] = true;
              }
              
              // AirQualityModel içindeki forecast alanını da güncelle
              if (forecastData.containsKey('weather') && forecastData['weather'] != null) {
                results[SOURCE_WAQI]!.forecast['weather'] = forecastData['weather'] as dynamic;
              }
            }
          }
        } catch (e) {
          print('Open-Meteo hava durumu verisi alınırken hata: $e');
          // Hata durumunda WAQI'deki hava durumu verileri kullanılacak (eğer varsa)
        }
      }
    } catch (e) {
      print('WAQI API hatası: $e');
      results[SOURCE_WAQI] = null;
    }
    
    // Diğer API'ler için null değer döndür
    results[SOURCE_OPENAQ] = null;
    results[SOURCE_GOOGLE] = null;
    
    return results;
  }

  // WAQI API'den hava kalitesi verilerini alma
  Future<AirQualityModel?> getAirQualityFromWAQI(double latitude, double longitude) async {
    try {
      print('WAQI API\'den veri alınıyor... (Konum: $latitude, $longitude)');

      // Geocoding API ile şehir ve ilçe bilgisini al (sonradan kullanmak için)
      final geocodingUrl = 'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$latitude&longitude=$longitude&localityLanguage=tr';
      final geocodingResponse = await _httpClient.get(Uri.parse(geocodingUrl));
      
      String locationQuery = '';
      String cityName = '';
      String districtName = '';
      
      if (geocodingResponse.statusCode == 200) {
        final geoData = json.decode(geocodingResponse.body);
        
        // Şehir bilgisi
        cityName = geoData['city'] ?? '';
        
        // İlçe bilgisi
        districtName = geoData['locality'] ?? geoData['district'] ?? '';
        
        print('Konum detayları: Şehir=$cityName, İlçe=$districtName');
        
        // Konum sorgusu oluştur (sonradan kullanmak için)
        if (cityName.isNotEmpty && districtName.isNotEmpty) {
          locationQuery = '$cityName/$districtName'.toLowerCase();
          print('Şehir ve ilçe sorgusu hazırlandı: $locationQuery');
        } else if (cityName.isNotEmpty) {
          locationQuery = cityName.toLowerCase();
          print('Şehir sorgusu hazırlandı: $locationQuery');
        }
      }
      
      // YENİ YAKLAŞIM: MAP API ile çevredeki tüm istasyonları al ve en yakınını bul
      // Bu yaklaşımda maksimum mesafe sınırını da uygulayacağız (100 km)
      final double MAX_DISTANCE_KM = 100.0;  // Maksimum 100 km uzaklıktaki istasyonları kabul et
      
      // Map API'sinden tüm istasyonları al
      final mapUrl = '$_waqiBaseUrl/map/bounds/?token=$_waqiApiKey';
      print('Dünya üzerindeki tüm istasyonlar için sorgu: $mapUrl');
      final mapResponse = await _httpClient.get(Uri.parse(mapUrl));
      
      Map<String, dynamic>? nearestStation;
      double nearestDistance = double.infinity;
      String usedMethod = 'En yakın istasyon sorgusu';
      
      if (mapResponse.statusCode == 200) {
        final mapData = json.decode(mapResponse.body);
        
        if (mapData['status'] == 'ok' && mapData['data'] is List) {
          // Tüm istasyonları dolaş ve en yakınını bul
          for (var station in mapData['data']) {
            if (station['lat'] != null && station['lon'] != null) {
              double stLat = double.parse(station['lat'].toString());
              double stLon = double.parse(station['lon'].toString());
              
              double dist = _calculateHaversineDistance(
                latitude, longitude, stLat, stLon);
                
              // En yakını bul, ancak maximum mesafe sınırını kontrol et
              if (dist < nearestDistance && dist <= MAX_DISTANCE_KM) {
                nearestDistance = dist;
                nearestStation = station;
              }
            }
          }
          
          if (nearestStation != null) {
            print('En yakın istasyon bulundu: ${nearestStation['station']['name']}, Uzaklık: ${nearestDistance.toStringAsFixed(2)} km');
            
            // En yakın istasyonun detaylı bilgilerini al
            if (nearestStation['uid'] != null) {
              final stationUrl = '$_waqiBaseUrl/@${nearestStation['uid']}/?token=$_waqiApiKey';
              print('En yakın istasyondan veri alınıyor: $stationUrl');
              final response = await _httpClient.get(Uri.parse(stationUrl));
              
              if (response.statusCode == 200 && 
                  json.decode(response.body)['status'] == 'ok') {
                print('Kullanılan yöntem: $usedMethod');
                return _processWaqiResponse(response, latitude, longitude);
              }
            }
          } else {
            print('Belirtilen maksimum mesafe (${MAX_DISTANCE_KM}km) içinde istasyon bulunamadı');
          }
        }
      }
      
      // Eğer buraya geldiyse, istasyon bulunamadı veya hata oluştu
      // Daha önceki yöntemler (şehir/ilçe veya şehir) ile deneyelim
      http.Response? response;
      
      // 1. Şehir/ilçe bilgisi ile dene
      if (locationQuery.isNotEmpty && locationQuery.contains('/')) {
        final url = '$_waqiBaseUrl/$locationQuery/?token=$_waqiApiKey';
        print('Alternatif 1: Şehir/ilçe sorgusu: $url');
        response = await _httpClient.get(Uri.parse(url));
        
        final data = json.decode(response.body);
        if (response.statusCode == 200 && data['status'] == 'ok') {
          usedMethod = 'Şehir/ilçe sorgusu';
          print('Şehir/ilçe sorgusu başarılı: $locationQuery');
          
          // İstasyon koordinatlarını kontrol et
          if (data['data']['city'] != null && data['data']['city']['geo'] != null) {
            double stationLat = data['data']['city']['geo'][0];
            double stationLon = data['data']['city']['geo'][1];
            
            // Mesafe kontrolü yap
            double distance = _calculateHaversineDistance(
              latitude, longitude, stationLat, stationLon);
              
            if (distance <= MAX_DISTANCE_KM) {
              print('İstasyon mesafe kontrolünü geçti. Uzaklık: ${distance.toStringAsFixed(2)} km');
            } else {
              print('İstasyon çok uzak! Uzaklık: ${distance.toStringAsFixed(2)} km. Bu veri kullanılmayacak.');
              response = null; // Çok uzak, bu veriyi kullanma
            }
          }
        }
      }
      
      // 2. Sadece şehir ile dene
      if ((response == null || json.decode(response.body)['status'] != 'ok') && cityName.isNotEmpty) {
        final url = '$_waqiBaseUrl/$cityName/?token=$_waqiApiKey';
        print('Alternatif 2: Şehir sorgusu: $url');
        response = await _httpClient.get(Uri.parse(url));
        
        final data = json.decode(response.body);
        if (response.statusCode == 200 && data['status'] == 'ok') {
          usedMethod = 'Şehir sorgusu';
          print('Şehir sorgusu başarılı: $cityName');
          
          // İstasyon koordinatlarını kontrol et
          if (data['data']['city'] != null && data['data']['city']['geo'] != null) {
            double stationLat = data['data']['city']['geo'][0];
            double stationLon = data['data']['city']['geo'][1];
            
            // Mesafe kontrolü yap
            double distance = _calculateHaversineDistance(
              latitude, longitude, stationLat, stationLon);
              
            if (distance <= MAX_DISTANCE_KM) {
              print('İstasyon mesafe kontrolünü geçti. Uzaklık: ${distance.toStringAsFixed(2)} km');
            } else {
              print('İstasyon çok uzak! Uzaklık: ${distance.toStringAsFixed(2)} km. Bu veri kullanılmayacak.');
              response = null; // Çok uzak, bu veriyi kullanma
            }
          }
        }
      }
      
      // 3. Son çare olarak koordinat kullan - ancak yine mesafe kontrolü yap
      if (response == null || json.decode(response.body)['status'] != 'ok') {
        final url = '$_waqiBaseUrl/geo:$latitude;$longitude/?token=$_waqiApiKey';
        print('Alternatif 3: Koordinat sorgusu: $url');
        final tempResponse = await _httpClient.get(Uri.parse(url));
        
        final data = json.decode(tempResponse.body);
        if (tempResponse.statusCode == 200 && data['status'] == 'ok') {
          // İstasyon koordinatlarını kontrol et
          if (data['data']['city'] != null && data['data']['city']['geo'] != null) {
            double stationLat = data['data']['city']['geo'][0];
            double stationLon = data['data']['city']['geo'][1];
            
            // Mesafe kontrolü yap
            double distance = _calculateHaversineDistance(
              latitude, longitude, stationLat, stationLon);
              
            if (distance <= MAX_DISTANCE_KM) {
              print('Koordinat sorgusu istasyon mesafe kontrolünü geçti. Uzaklık: ${distance.toStringAsFixed(2)} km');
              response = tempResponse;
              usedMethod = 'Koordinat sorgusu';
            } else {
              print('Koordinat sorgusu istasyonu çok uzak! Uzaklık: ${distance.toStringAsFixed(2)} km. Bu veri kullanılmayacak.');
              // Kullanma
            }
          }
        }
      }
      
      if (response != null) {
        print('Kullanılan yöntem: $usedMethod');
        return _processWaqiResponse(response, latitude, longitude);
      } else {
        print('Tüm sorgular başarısız oldu veya istasyonlar mesafe kontrolünü geçemedi');
        return null;
      }
    } catch (e) {
      print('WAQI API istisna: $e');
      return null;
    }
  }

  // İki koordinat arasındaki mesafeyi Haversine formülü ile hesaplama (km cinsinden)
  double _calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371.0; // Dünya'nın yarıçapı (km)
    
    // Radyan cinsine çevirme
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    // Haversine formülü
    final a = 
            sin(dLat/2) * sin(dLat/2) +
            cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) * 
            sin(dLon/2) * sin(dLon/2);
            
    final c = 2 * atan2(sqrt(a), sqrt(1-a));
    final distance = earthRadius * c;
    
    return distance;
  }
  
  // Dereceleri radyana çevirme
  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  // OpenAQ API'den hava kalitesi verilerini alma - artık kullanılmıyor ama yapıyı bozmamak için tutuyoruz
  Future<AirQualityModel?> getAirQualityFromOpenAQ(double latitude, double longitude) async {
    print('OpenAQ API artık kullanılmıyor.');
    return null;
  }
  
  // Google Air Quality API'den hava kalitesi verilerini alma - artık kullanılmıyor ama yapıyı bozmamak için tutuyoruz
  Future<AirQualityModel?> getAirQualityFromGoogle(double latitude, double longitude) async {
    print('Google Air Quality API artık kullanılmıyor.');
    return null;
  }
  
  // Google'ın İngilizce kategorilerini Türkçe'ye çevirme
  String _translateCategory(String englishCategory) {
    switch (englishCategory.toLowerCase()) {
      case 'good':
        return 'İyi';
      case 'moderate':
        return 'Orta';
      case 'unhealthy for sensitive groups':
        return 'Hassas Gruplar İçin Sağlıksız';
      case 'unhealthy':
        return 'Sağlıksız';
      case 'very unhealthy':
        return 'Çok Sağlıksız';
      case 'hazardous':
        return 'Tehlikeli';
      default:
        return englishCategory;
    }
  }

  // AQI kategorisini ve rengini belirle
  String _getAQICategory(double aqi) {
    if (aqi <= 50) {
      return 'İyi';
    } else if (aqi <= 100) {
      return 'Orta';
    } else if (aqi <= 150) {
      return 'Hassas Gruplar İçin Sağlıksız';
    } else if (aqi <= 200) {
      return 'Sağlıksız';
    } else if (aqi <= 300) {
      return 'Çok Sağlıksız';
    } else {
      return 'Tehlikeli';
    }
  }
  
  // AQI kategorisine göre renk döndürür
  String _getAqiColor(String category) {
    switch (category) {
      case 'İyi':
        return '4CAF50'; // Yeşil
      case 'Orta':
        return 'FFC107'; // Sarı
      case 'Hassas Gruplar İçin Sağlıksız':
        return 'FF9800'; // Turuncu
      case 'Sağlıksız':
        return 'F44336'; // Kırmızı
      case 'Çok Sağlıksız':
        return '9C27B0'; // Mor
      case 'Tehlikeli':
        return '7E0023'; // Bordoya yakın kırmızı
      default:
        return '9E9E9E'; // Gri (Belirsiz)
    }
  }

  // Hava kalitesinin tehlikeli seviyede olup olmadığını kontrol etme
  bool isAirQualityDangerous(AirQualityModel airQuality, int threshold) {
    return airQuality.aqi > threshold;
  }
  
  // Kaynak adına göre ikon döndürme
  IconData getSourceIcon(String source) {
    switch (source) {
      case SOURCE_WAQI:
        return Icons.public;
      case SOURCE_OPENAQ:
        return Icons.cloud;
      case SOURCE_GOOGLE:
        return Icons.map;
      default:
        return Icons.help_outline;
    }
  }
  
  // Kaynak adına göre renk döndürme
  Color getSourceColor(String source) {
    switch (source) {
      case SOURCE_WAQI:
        return Colors.blue;
      case SOURCE_OPENAQ:
        return Colors.green;
      case SOURCE_GOOGLE:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // WAQI API yanıtını işleyerek AirQualityModel'e dönüştürme
  AirQualityModel? _processWaqiResponse(
    http.Response response,
    double userLatitude,
    double userLongitude,
  ) {
    try {
      final data = json.decode(response.body);
      print('WAQI API yanıtı: $data');

      if (data['status'] != 'ok' || data['data'] == null) {
        print('WAQI API geçersiz yanıt: ${data['status']}');
        return null;
      }

      // API yanıtından verileri çıkart
      final apiData = data['data'];
      final double aqi = apiData['aqi'].toDouble();
      
      // İstasyon adını ve konumunu al
      String stationName = 'Bilinmeyen İstasyon';
      double stationDistance = 0.0;
      double stationLat = userLatitude;
      double stationLon = userLongitude;
      String location = 'Bilinmeyen Konum';
      
      if (apiData['city'] != null) {
        stationName = apiData['city']['name'] ?? stationName;
        location = stationName;
        
        // İstasyon koordinatlarını al ve mesafeyi hesapla
        if (apiData['city']['geo'] != null && apiData['city']['geo'].length >= 2) {
          stationLat = apiData['city']['geo'][0].toDouble();
          stationLon = apiData['city']['geo'][1].toDouble();
          
          stationDistance = _calculateHaversineDistance(
            userLatitude, userLongitude, stationLat, stationLon);
            
          print('İstasyon: $stationName, Konum: $stationLat, $stationLon, Uzaklık: ${stationDistance.toStringAsFixed(2)} km');
        }
      }
      
      // AQI kategorisini belirle
      final String category = _getAQICategory(aqi);
      final String color = _getAqiColor(category);

      // Temel kirleticileri çıkart
      final Map<String, double> pollutants = {};
      if (apiData['iaqi'] != null) {
        final iaqi = apiData['iaqi'];
        pollutants['pm25'] = iaqi['pm25']?['v']?.toDouble() ?? 0.0;
        pollutants['pm10'] = iaqi['pm10']?['v']?.toDouble() ?? 0.0;
        pollutants['o3'] = iaqi['o3']?['v']?.toDouble() ?? 0.0;
        pollutants['no2'] = iaqi['no2']?['v']?.toDouble() ?? 0.0;
        pollutants['so2'] = iaqi['so2']?['v']?.toDouble() ?? 0.0;
        pollutants['co'] = iaqi['co']?['v']?.toDouble() ?? 0.0;
      }

      // Hava durumu verilerini çıkart
      final Map<String, dynamic> weather = {};
      if (apiData['iaqi'] != null) {
        final iaqi = apiData['iaqi'];
        
        // Sıcaklık (t)
        if (iaqi['t'] != null) {
          weather['temperature'] = iaqi['t']['v'].toDouble();
          print('Sıcaklık: ${weather['temperature']} °C');
        }
        
        // Nem (h)
        if (iaqi['h'] != null) {
          weather['humidity'] = iaqi['h']['v'].toDouble();
          print('Nem: %${weather['humidity']}');
        }
        
        // Rüzgar hızı (w)
        if (iaqi['w'] != null) {
          weather['windSpeed'] = iaqi['w']['v'].toDouble();
          print('Rüzgar Hızı: ${weather['windSpeed']} m/s');
        }
        
        // Basınç (p)
        if (iaqi['p'] != null) {
          weather['pressure'] = iaqi['p']['v'].toDouble();
          print('Basınç: ${weather['pressure']} hPa');
        }
        
        // WAQI olduğunu belirt
        weather['source'] = 'WAQI';
      }

      // Tahmin verilerini çıkart
      final Map<String, List<Map<String, dynamic>>> forecast = {};
      if (apiData['forecast'] != null && apiData['forecast']['daily'] != null) {
        final daily = apiData['forecast']['daily'];
        
        // Ozon (o3)
        if (daily['o3'] != null) {
          forecast['o3'] = List<Map<String, dynamic>>.from(daily['o3']);
          print('Ozon Tahmini: ${forecast['o3']}');
        }
        
        // PM10
        if (daily['pm10'] != null) {
          forecast['pm10'] = List<Map<String, dynamic>>.from(daily['pm10']);
        }
        
        // PM2.5
        if (daily['pm25'] != null) {
          forecast['pm25'] = List<Map<String, dynamic>>.from(daily['pm25']);
          print('PM2.5 Tahmini: ${forecast['pm25']}');
        }
        
        // UV indeksi
        if (daily['uvi'] != null) {
          forecast['uvi'] = List<Map<String, dynamic>>.from(daily['uvi']);
        }
        
        print('Tahmin verileri eklendi');
      }

      // Ölçüm zamanını al
      String measurementTime = DateTime.now().toIso8601String();
      String timeNote = '';  // Zaman hakkında ek bilgi

      if (apiData['time'] != null && apiData['time']['s'] != null) {
        measurementTime = apiData['time']['s'];
        
        final DateTime now = DateTime.now();
        final DateTime measurementDateTime = DateTime.parse(measurementTime);
        final int hoursDifference = now.difference(measurementDateTime).inHours;
        
        print('Ölçüm Zamanı: $measurementTime');
        print('Güncel Zaman: ${now.toIso8601String()}');
        
        // Ölçüm zamanı değerlendirmesi
        if (hoursDifference > 6) {
          print('Uyarı: Ölçüm verileri $hoursDifference saat öncesine ait!');
          timeNote = 'Ölçüm $hoursDifference saat önce yapıldı';
        } else if (hoursDifference > 0) {
          timeNote = 'Ölçüm $hoursDifference saat önce yapıldı';
        } else {
          timeNote = 'Güncel ölçüm';
        }
      }

      // AdditionalData oluştur
      Map<String, dynamic> additionalData = {
        'attributions': apiData['attributions'],
        'dominentpol': apiData['dominentpol'],
        'timeNote': timeNote,  // Zaman notu ekle
      };
      
      // Hava durumu verilerini additionalData'ya ekle
      bool hasWeatherData = weather.isNotEmpty;
      if (hasWeatherData) {
        // Hava durumu verilerini ekle
        additionalData['weatherData'] = weather;
        additionalData['hasWeatherData'] = true;
        
        // Zaman notunu da weather verisine ekle
        additionalData['weatherData']['timeNote'] = timeNote;
        
        // Ölçüm zamanını ekle
        additionalData['weatherData']['measurementTime'] = measurementTime;
      }
      
      // Tahmin verilerini ekle
      bool hasWeeklyForecast = forecast.isNotEmpty;
      if (hasWeeklyForecast) {
        if (!additionalData.containsKey('weatherData')) {
          additionalData['weatherData'] = {};
          additionalData['hasWeatherData'] = true;
        }
        additionalData['weatherData']['forecast'] = forecast;
        additionalData['weatherData']['hasWeeklyForecast'] = true;
      }

      return AirQualityModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        latitude: userLatitude,
        longitude: userLongitude,
        location: location,
        timestamp: DateTime.now(),
        source: SOURCE_WAQI,
        aqi: aqi,
        category: category,
        pollutants: pollutants,
        additionalData: additionalData,
        color: color,
        weather: weather,
        forecast: forecast,
        measurementTime: measurementTime,
        stationDistance: stationDistance,
        stationName: stationName,
      );
    } catch (e) {
      print('WAQI API yanıtını işlerken hata: $e');
      return null;
    }
  }

  // Open-Meteo API'sinden güncel hava durumu verilerini alma
  Future<Map<String, dynamic>> getWeatherFromOpenMeteo(double latitude, double longitude) async {
    print('Open-Meteo\'dan güncel hava durumu alınıyor...');
    try {
      // Güncel hava durumu ve günlük tahminler için URI
      final uri = Uri.parse('$_openMeteoBaseUrl/forecast?latitude=$latitude&longitude=$longitude&hourly=temperature_2m,relative_humidity_2m,precipitation,weathercode,pressure_msl,windspeed_10m&daily=weathercode,temperature_2m_max,temperature_2m_min&timezone=auto&current_weather=true');
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Open-Meteo\'dan hava durumu verisi başarıyla alındı');
        
        // Güncel hava durumu bilgilerini çıkar
        final currentWeather = data['current_weather'] as Map<String, dynamic>;
        final hourlyUnits = data['hourly_units'] as Map<String, dynamic>;
        
        // Şu anki saate karşılık gelen saatlik verileri bul
        final hourlyTimes = List<String>.from(data['hourly']['time']);
        final now = DateTime.now();
        final formattedNow = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}T${now.hour.toString().padLeft(2, '0')}:00';
        
        int currentIndex = hourlyTimes.indexWhere((time) => time == formattedNow);
        if (currentIndex == -1) {
          currentIndex = 0; // Tam eşleşme bulunamazsa ilk elemanı kullan
        }
        
        // Şu anki saat için verileri çıkar
        final currentHumidity = data['hourly']['relative_humidity_2m'][currentIndex];
        final currentPressure = data['hourly']['pressure_msl'][currentIndex];
        final currentWindSpeed = data['hourly']['windspeed_10m'][currentIndex];
        final currentPrecipitation = data['hourly']['precipitation'][currentIndex];
        
        // Weather code'unu al
        final int currentWeatherCode = currentWeather.containsKey('weathercode') 
            ? (currentWeather['weathercode'] as num).toInt() 
            : (data['hourly']['weathercode'][currentIndex] as num).toInt();
        
        // Hava durumu açıklaması ve ikonunu getir
        final weatherDescription = _getWeatherDescription(currentWeatherCode);
        final weatherIcon = _getWeatherIcon(currentWeatherCode);
        
        // Güncel sıcaklık birimi
        final tempUnit = hourlyUnits['temperature_2m'] ?? '°C';
        
        return {
          'temperature': currentWeather.containsKey('temperature') 
              ? currentWeather['temperature'] 
              : data['hourly']['temperature_2m'][currentIndex],
          'humidity': currentHumidity,
          'pressure': currentPressure,
          'wind_speed': currentWindSpeed,
          'precipitation': currentPrecipitation,
          'description': weatherDescription,
          'icon': weatherIcon,
          'temp_unit': tempUnit,
          'source': 'Open-Meteo'
        };
      } else {
        print('Open-Meteo API hatası: ${response.statusCode} - ${response.body}');
        return {};
      }
    } catch (e) {
      print('Open-Meteo API hatası: $e');
      return {};
    }
  }
  
  // Open-Meteo API'sinden 7 günlük hava tahminini al
  Future<List<Map<String, dynamic>>> getForecastFromOpenMeteo(double latitude, double longitude) async {
    print('Open-Meteo\'dan 7 günlük tahmin alınıyor...');
    try {
      // Günlük tahmin için URI
      final uri = Uri.parse('$_openMeteoBaseUrl/forecast?latitude=$latitude&longitude=$longitude&daily=weathercode,temperature_2m_max,temperature_2m_min&timezone=auto');
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Open-Meteo\'dan tahmin verisi başarıyla alındı');
        
        final List<String> dates = List<String>.from(data['daily']['time']);
        final List<num> weatherCodes = List<num>.from(data['daily']['weathercode']);
        final List<num> maxTemps = List<num>.from(data['daily']['temperature_2m_max']);
        final List<num> minTemps = List<num>.from(data['daily']['temperature_2m_min']);
        
        // En fazla 7 günlük tahmin
        final int count = min(dates.length, 7);
        List<Map<String, dynamic>> result = [];
        
        for (int i = 0; i < count; i++) {
          final description = _getWeatherDescription(weatherCodes[i].toInt());
          final icon = _getWeatherIcon(weatherCodes[i].toInt());
          
          result.add({
            'day': dates[i],
            'description': description,
            'icon': icon,
            'max': maxTemps[i],
            'min': minTemps[i]
          });
        }
        
        return result;
      } else {
        print('Open-Meteo tahmin API hatası: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Open-Meteo tahmin API hatası: $e');
      return [];
    }
  }
  
  // Weather code'dan açıklama getir
  String _getWeatherDescription(int weatherCode) {
    switch (weatherCode) {
      case 0: return 'Açık';
      case 1: return 'Çoğunlukla Açık';
      case 2: return 'Parçalı Bulutlu';
      case 3: return 'Bulutlu';
      case 45: case 48: return 'Sisli';
      case 51: case 53: case 55: return 'Hafif Çisenti';
      case 56: case 57: return 'Donmuş Çisenti';
      case 61: case 63: case 65: return 'Yağmurlu';
      case 66: case 67: return 'Donmuş Yağmur';
      case 71: case 73: case 75: return 'Kar Yağışlı';
      case 77: return 'Kar Taneleri';
      case 80: case 81: case 82: return 'Sağanak Yağış';
      case 85: case 86: return 'Kar Sağanağı';
      case 95: return 'Gök Gürültülü';
      case 96: case 99: return 'Dolu ile Fırtınalı';
      default: return 'Bilinmeyen';
    }
  }
  
  // Weather code'dan ikon kodu getir
  String _getWeatherIcon(int weatherCode) {
    switch (weatherCode) {
      case 0: return 'clear';
      case 1: return 'few';
      case 2: return 'scattered';
      case 3: return 'broken';
      case 45: case 48: return 'mist';
      case 51: case 53: case 55: case 56: case 57: return 'shower';
      case 61: case 63: case 65: case 66: case 67: return 'rain';
      case 71: case 73: case 75: case 77: case 85: case 86: return 'snow';
      case 80: case 81: case 82: return 'rain';
      case 95: case 96: case 99: return 'thunder';
      default: return 'unknown';
    }
  }
}
