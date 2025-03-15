import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../widgets/animated_widgets.dart';
import 'dart:math';

class WeeklyForecastCard extends StatelessWidget {
  final Map<String, dynamic> forecastData;
  final String temperatureUnit; // 'celsius' veya 'fahrenheit'
  final String location;

  const WeeklyForecastCard({
    Key? key,
    required this.forecastData,
    required this.temperatureUnit,
    required this.location,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade300,
            Colors.purple.shade700,
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
                color: Colors.white.withOpacity(0.3),
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
                          Icons.calendar_month,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Haftalık Tahmin',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.ellipsis,
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
    print('Forecast data: $forecastData');
    
    // PM2.5 tahmin verilerini kullan (daha yaygın)
    final List<dynamic>? pm25Forecast = forecastData['pm25'];
    
    if (pm25Forecast == null || pm25Forecast.isEmpty) {
      return const Center(
        child: Text(
          'Tahmin verisi bulunamadı',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    
    // Sadece ilk 7 günü göster (veya daha az)
    final int daysToShow = min(pm25Forecast.length, 7);
    
    return Column(
      children: List.generate(daysToShow, (index) {
        final forecast = pm25Forecast[index];
        final day = forecast['day'] ?? '';
        
        // avg değerini güvenli bir şekilde al ve double'a dönüştür
        double avgValue = 0.0;
        if (forecast['avg'] != null) {
          if (forecast['avg'] is int) {
            avgValue = (forecast['avg'] as int).toDouble();
          } else if (forecast['avg'] is double) {
            avgValue = forecast['avg'] as double;
          } else if (forecast['avg'] is String) {
            avgValue = double.tryParse(forecast['avg'] as String) ?? 0.0;
          }
        }
        
        // Tarih formatını düzelt
        String formattedDate = 'Bilinmeyen';
        try {
          final date = DateTime.parse(day);
          formattedDate = '${date.day}/${date.month}';
        } catch (e) {
          formattedDate = day;
        }
        
        // AQI değerine göre renk belirle
        Color aqiColor = _getAQIColor(avgValue);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: Colors.white.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Gün
                SizedBox(
                  width: 60,
                  child: Text(
                    formattedDate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // AQI değeri
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.air,
                        color: aqiColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AQI: ${avgValue.toInt()}',
                        style: TextStyle(
                          color: aqiColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Kategori
                Flexible(
                  child: Text(
                    _getAQICategory(avgValue),
                    style: TextStyle(
                      color: aqiColor,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // AQI değerine göre kategori belirleme
  String _getAQICategory(double aqi) {
    if (aqi <= 50) {
      return 'İyi';
    } else if (aqi <= 100) {
      return 'Orta';
    } else if (aqi <= 150) {
      return 'Hassas';
    } else if (aqi <= 200) {
      return 'Sağlıksız';
    } else if (aqi <= 300) {
      return 'Çok Sağlıksız';
    } else {
      return 'Tehlikeli';
    }
  }

  // AQI değerine göre renk belirleme
  Color _getAQIColor(double aqi) {
    if (aqi <= 50) {
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