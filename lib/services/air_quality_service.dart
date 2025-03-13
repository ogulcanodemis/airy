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
      
      // Sadece WAQI API'den veri al
      return await getAirQualityFromWAQI(latitude, longitude);
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
      
      final url = '$_waqiBaseUrl/geo:$latitude;$longitude/?token=$_waqiApiKey';
      final response = await _httpClient.get(Uri.parse(url));
      
      print('WAQI API yanıt durumu: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'ok') {
          final result = data['data'];
          
          // API yanıtını logla
          print('WAQI API yanıtı: ${result.toString().substring(0, min(500, result.toString().length))}...');
          
          // AQI değeri
          final aqi = result['aqi'] is int ? result['aqi'].toDouble() : (result['aqi'] ?? 0.0);
          
          // Kirleticiler
          final Map<String, dynamic> iaqi = result['iaqi'] ?? {};
          final Map<String, double> pollutants = {};
          
          iaqi.forEach((key, value) {
            if (value is Map && value.containsKey('v')) {
              final dynamic v = value['v'];
              if (v is num) {
                pollutants[key] = v.toDouble();
              }
            }
          });
          
          // Kategori belirleme
          String category = _getAQICategory(aqi);
          
          // Konum bilgisi
          String location = result['city']?['name'] ?? 'Bilinmeyen Konum';
          
          // Hava durumu bilgileri
          Map<String, dynamic> weatherData = {};
          
          // Sıcaklık bilgisi
          if (iaqi.containsKey('t')) {
            final temp = iaqi['t']?['v'];
            if (temp is num) {
              weatherData['temperature'] = temp.toDouble();
              print('Sıcaklık: ${temp.toDouble()} °C');
            }
          }
          
          // Nem bilgisi
          if (iaqi.containsKey('h')) {
            final humidity = iaqi['h']?['v'];
            if (humidity is num) {
              weatherData['humidity'] = humidity.toDouble();
              print('Nem: %${humidity.toDouble()}');
            }
          }
          
          // Rüzgar hızı
          if (iaqi.containsKey('w')) {
            final windSpeed = iaqi['w']?['v'];
            if (windSpeed is num) {
              weatherData['windSpeed'] = windSpeed.toDouble();
              print('Rüzgar Hızı: ${windSpeed.toDouble()} m/s');
            }
          }
          
          // Basınç
          if (iaqi.containsKey('p')) {
            final pressure = iaqi['p']?['v'];
            if (pressure is num) {
              weatherData['pressure'] = pressure.toDouble();
              print('Basınç: ${pressure.toDouble()} hPa');
            }
          }
          
          // Tahmin bilgisi
          if (result.containsKey('forecast') && result['forecast'] is Map) {
            final forecast = result['forecast'];
            if (forecast.containsKey('daily') && forecast['daily'] is Map) {
              final daily = forecast['daily'];
              
              // Sıcaklık tahmini
              if (daily.containsKey('o3') && daily['o3'] is List && daily['o3'].isNotEmpty) {
                final o3Forecast = daily['o3'];
                weatherData['o3Forecast'] = o3Forecast;
                print('Ozon Tahmini: ${o3Forecast.toString().substring(0, min(100, o3Forecast.toString().length))}...');
              }
              
              // PM2.5 tahmini
              if (daily.containsKey('pm25') && daily['pm25'] is List && daily['pm25'].isNotEmpty) {
                final pm25Forecast = daily['pm25'];
                weatherData['pm25Forecast'] = pm25Forecast;
                print('PM2.5 Tahmini: ${pm25Forecast.toString().substring(0, min(100, pm25Forecast.toString().length))}...');
              }
            }
          }
          
          // Zaman bilgisi
          if (result.containsKey('time') && result['time'] is Map) {
            final time = result['time'];
            if (time.containsKey('s')) {
              weatherData['measurementTime'] = time['s'];
              print('Ölçüm Zamanı: ${time['s']}');
            }
          }
          
          return AirQualityModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            latitude: latitude,
            longitude: longitude,
            location: location,
            timestamp: DateTime.now(),
            aqi: aqi,
            pollutants: pollutants,
            category: category,
            source: SOURCE_WAQI,
            additionalData: weatherData.isNotEmpty ? {
              'weatherData': weatherData,
              'hasWeatherData': true,
            } : null,
          );
        } else {
          print('WAQI API yanıt hatası: ${data['status']}');
          return null;
        }
      } else {
        print('WAQI API HTTP hatası: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('WAQI API istisna: $e');
      return null;
    }
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

  // AQI değerine göre kategori belirleme
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
} 