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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF82E0F9), // Açık mavi
            Color(0xFF5BBCD9), // Açık mavinin koyu tonu
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
                          Icons.calendar_month,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: const Text(
                          'Haftalık Tahmin',
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
    print('Forecast data: $forecastData');
    
    // Önce Open-Meteo'dan gelen hava durumu tahminini kontrol et
    final List<dynamic>? weatherForecast = forecastData['weather'];
    
    // Eğer yoksa, PM2.5 tahmin verilerini kullan (daha yaygın)
    final List<dynamic>? pm25Forecast = forecastData['pm25'];
    
    if ((weatherForecast == null || weatherForecast.isEmpty) && 
        (pm25Forecast == null || pm25Forecast.isEmpty)) {
      return const Center(
        child: Text(
          'Tahmin verisi bulunamadı',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    
    // Open-Meteo'dan gelen hava durumu tahmini varsa, onu göster
    if (weatherForecast != null && weatherForecast.isNotEmpty) {
      return _buildWeatherForecast(weatherForecast);
    }
    
    // Yoksa PM2.5 tahminlerini göster
    // Sadece ilk 7 günü göster (veya daha az)
    final int daysToShow = min(pm25Forecast!.length, 7);
    
    return Column(
      children: List.generate(daysToShow, (index) {
        final forecast = pm25Forecast[index];
        final day = forecast['day'] ?? '';
        
        // Tarih formatını ayarla
        String formattedDay = _formatDay(day);
        
        // AQI değeri ve renk
        final double? avgAqi = forecast['avg'] is double 
            ? forecast['avg'] 
            : (forecast['avg'] is int ? forecast['avg'].toDouble() : null);
            
        final color = getAqiColor(avgAqi);
        
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
                overflow: TextOverflow.ellipsis,
              ),
              
              // AQI değerleri
              Row(
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
    );
  }
  
  // Open-Meteo'dan gelen hava durumu tahminlerini gösterir
  Widget _buildWeatherForecast(List<dynamic> weatherForecast) {
    // Sadece ilk 7 günü göster (veya daha az)
    final int daysToShow = min(weatherForecast.length, 7);
    
    return Column(
      children: List.generate(daysToShow, (index) {
        final forecast = weatherForecast[index];
        final day = forecast['day'] ?? '';
        
        // Tarih formatını ayarla
        String formattedDay = _formatDay(day);
        
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
                overflow: TextOverflow.ellipsis,
              ),
              
              // Hava durumu ikonu ve açıklaması
              if (forecast['icon'] != null)
                Icon(
                  _getWeatherIcon(forecast['icon']),
                  color: Colors.white,
                  size: 20,
                ),
              
              // Eğer gün isimleri uzunsa, açıklamayı gösterme
              // İkon + sıcaklık değerleri daha önemli
              
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
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
                            _formatTemperature(forecast['min'], temperatureUnit),
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                            _formatTemperature(forecast['max'], temperatureUnit),
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
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
  Color getAqiColor(double? aqi) {
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

  // Şimdiki zamanı formatlama
  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  // Sıcaklık değerini formatlama
  String _formatTemperature(dynamic temperature, String unit) {
    if (temperature is int) {
      return '$temperature°${unit == 'celsius' ? 'C' : 'F'}';
    } else if (temperature is double) {
      return '${temperature.toStringAsFixed(1)}°${unit == 'celsius' ? 'C' : 'F'}';
    } else if (temperature is String) {
      return '$temperature°${unit == 'celsius' ? 'C' : 'F'}';
    } else {
      return 'Bilinmeyen';
    }
  }

  // Tarih formatını ayarla
  String _formatDay(String day) {
    try {
      final date = DateTime.parse(day);
      return '${date.day}/${date.month}';
    } catch (e) {
      return day;
    }
  }

  // Hava durumu kodundan icon seçme
  IconData _getWeatherIcon(String iconCode) {
    // Open-Meteo ikonları farklı olduğu için, basit bir eşleme yapıyoruz
    if (iconCode.contains('01') || iconCode.contains('clear')) {
      return Icons.wb_sunny;
    } else if (iconCode.contains('02') || iconCode.contains('few')) {
      return Icons.wb_cloudy;
    } else if (iconCode.contains('03') || iconCode.contains('scattered')) {
      return Icons.cloud;
    } else if (iconCode.contains('04') || iconCode.contains('broken')) {
      return Icons.cloud_queue;
    } else if (iconCode.contains('09') || iconCode.contains('shower')) {
      return Icons.grain;
    } else if (iconCode.contains('10') || iconCode.contains('rain')) {
      return Icons.beach_access;
    } else if (iconCode.contains('11') || iconCode.contains('thunder')) {
      return Icons.flash_on;
    } else if (iconCode.contains('13') || iconCode.contains('snow')) {
      return Icons.ac_unit;
    } else if (iconCode.contains('50') || iconCode.contains('mist')) {
      return Icons.blur_on;
    } else {
      return Icons.help_outline;
    }
  }
} 