import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../widgets/animated_widgets.dart';

class WeatherCard extends StatelessWidget {
  final Map<String, dynamic> weatherData;
  final String temperatureUnit; // 'celsius' veya 'fahrenheit'

  const WeatherCard({
    Key? key,
    required this.weatherData,
    required this.temperatureUnit,
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
            Colors.blue.shade300,
            Colors.blue.shade700,
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
                          Icons.wb_sunny,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Hava Durumu',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Güncellendi',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            _formatMeasurementTime(weatherData['measurementTime']),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Ana hava durumu bilgileri
                  Row(
                    children: [
                      // Sıcaklık
                      if (weatherData.containsKey('temperature'))
                        Expanded(
                          child: _buildWeatherItem(
                            'Sıcaklık',
                            _formatTemperature(weatherData['temperature'], temperatureUnit),
                            Icons.thermostat,
                          ),
                        ),
                      
                      const SizedBox(width: 16),
                      
                      // Nem
                      if (weatherData.containsKey('humidity'))
                        Expanded(
                          child: _buildWeatherItem(
                            'Nem',
                            '${weatherData['humidity'].toStringAsFixed(1)}%',
                            Icons.water_drop,
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Ek hava durumu bilgileri
                  Row(
                    children: [
                      // Rüzgar hızı
                      if (weatherData.containsKey('windSpeed'))
                        Expanded(
                          child: _buildWeatherItem(
                            'Rüzgar',
                            '${weatherData['windSpeed'].toStringAsFixed(1)} m/s',
                            Icons.air,
                          ),
                        ),
                      
                      const SizedBox(width: 16),
                      
                      // Basınç
                      if (weatherData.containsKey('pressure'))
                        Expanded(
                          child: _buildWeatherItem(
                            'Basınç',
                            '${weatherData['pressure'].toStringAsFixed(0)} hPa',
                            Icons.compress,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherItem(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Sıcaklık birimini dönüştürme
  String _formatTemperature(double celsius, String unit) {
    if (unit == 'fahrenheit') {
      // Celsius'tan Fahrenheit'a dönüştürme
      final fahrenheit = (celsius * 9 / 5) + 32;
      return '${fahrenheit.toStringAsFixed(1)}°F';
    } else {
      // Varsayılan olarak Celsius
      return '${celsius.toStringAsFixed(1)}°C';
    }
  }

  // Ölçüm zamanını formatlama
  String _formatMeasurementTime(String? timeString) {
    if (timeString == null) return '';
    
    try {
      final dateTime = DateTime.parse(timeString);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      // Eğer parse edilemezse, direkt olarak string'i döndür
      return timeString;
    }
  }
} 