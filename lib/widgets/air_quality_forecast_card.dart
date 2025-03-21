import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../widgets/animated_widgets.dart';
import 'dart:math';

class AirQualityForecastCard extends StatelessWidget {
  final Map<String, dynamic> forecastData;
  final String location;

  const AirQualityForecastCard({
    Key? key,
    required this.forecastData,
    required this.location,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF9800), // Turuncu
            Color(0xFFE65100), // Koyu turuncu
          ],
        ),
        boxShadow: AppStyles.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Dalga animasyonu
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 60,
              child: WaveAnimation(
                color: Colors.white,
                height: 10,
                speed: 0.5,
                child: const SizedBox.expand(),
              ),
            ),
            
            // İçerik
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık
                  Row(
                    children: [
                      FloatingAnimation(
                        height: 5,
                        duration: const Duration(seconds: 2),
                        child: const Icon(
                          Icons.air,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: const Text(
                          'Hava Kirliliği Tahmini',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              location,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(
                              'Güncellendi: ${_getCurrentTime()}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Haftalık tahmin listesi
                  _buildForecastList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastList() {
    // Debug bilgisi
    print('Air Quality Forecast data: $forecastData');
    
    // PM2.5 tahmin verilerini kullan
    final List<dynamic>? pm25Forecast = forecastData['pm25'];
    
    // PM10 tahmin verilerini kullan
    final List<dynamic>? pm10Forecast = forecastData['pm10'];
    
    // Ozon tahmin verilerini kullan
    final List<dynamic>? o3Forecast = forecastData['o3'];
    
    // İlk önce PM2.5 verilerini kontrol et, yoksa PM10, o da yoksa Ozon
    List<dynamic>? primaryForecast = pm25Forecast;
    String pollutantType = "PM2.5";
    
    if (primaryForecast == null || primaryForecast.isEmpty) {
      primaryForecast = pm10Forecast;
      pollutantType = "PM10";
      
      if (primaryForecast == null || primaryForecast.isEmpty) {
        primaryForecast = o3Forecast;
        pollutantType = "O3";
      }
    }
    
    if (primaryForecast == null || primaryForecast.isEmpty) {
      return const Center(
        child: Text(
          'Hava kirliliği tahmin verisi bulunamadı',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    
    // Sadece ilk 7 günü göster (veya daha az)
    final int daysToShow = min(primaryForecast.length, 7);
    
    return Column(
      children: [
        // Başlık
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            '$pollutantType Tahmini (µg/m³)',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        
        // Tahmin listesi
        ...List.generate(daysToShow, (index) {
          final forecast = primaryForecast![index];
          final day = forecast['day'] ?? '';
          
          // Tarih formatını ayarla
          String formattedDay = _formatDay(day);
          
          // AQI değeri ve renk
          final double? avgAqi = forecast['avg'] is double 
              ? forecast['avg'] 
              : (forecast['avg'] is int ? forecast['avg'].toDouble() : null);
              
          final color = _getAqiColor(avgAqi);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Gün
                Text(
                  formattedDay,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                // AQI değerleri
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Min
                    if (forecast['min'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Min',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            forecast['min'].toString(),
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      
                    const SizedBox(width: 12),
                    
                    // Max
                    if (forecast['max'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Max',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            forecast['max'].toString(),
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      
                    const SizedBox(width: 12),
                    
                    // Ortalama ve renk
                    if (avgAqi != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          avgAqi.toStringAsFixed(0),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Şimdiki zamanı formatlama
  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  String _formatDay(String day) {
    // Tarih formatını düzelt
    String formattedDate = 'Bilinmeyen';
    try {
      final date = DateTime.parse(day);
      formattedDate = '${date.day}/${date.month}';
    } catch (e) {
      formattedDate = day;
    }
    return formattedDate;
  }

  Color _getAqiColor(double? aqi) {
    if (aqi == null) {
      return Colors.grey;
    } else if (aqi <= 50) {
      return Colors.green;
    } else if (aqi <= 100) {
      return Colors.yellow;
    } else if (aqi <= 150) {
      return Colors.orange;
    } else if (aqi <= 200) {
      return Colors.red;
    } else if (aqi <= 300) {
      return Colors.purple;
    } else {
      return Colors.brown;
    }
  }
}