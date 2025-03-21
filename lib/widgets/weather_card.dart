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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF9CC3E), // Sarı
            Color(0xFFE5B82A), // Sarının koyu tonu
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
                          Icons.wb_sunny,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: const Text(
                          'Hava Durumu',
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
                            const Text(
                              'Güncellendi',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _getCurrentTime(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (weatherData.containsKey('timeNote'))
                              Text(
                                weatherData['timeNote'],
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Hava durumu açıklaması ve ikonu (Open-Meteo API'den gelirse)
                  if (weatherData.containsKey('description') && weatherData.containsKey('icon'))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (weatherData.containsKey('icon'))
                            Icon(
                              _getWeatherIcon(weatherData['icon']),
                              color: Colors.white,
                              size: 40,
                            ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              weatherData['description'] ?? 'Hava durumu',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
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
                  
                  // Veri kaynağı bilgisi
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Kaynak: ${weatherData.containsKey('source') ? weatherData['source'] : 'WAQI'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
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
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFFF9CC3E),
                size: 16,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF82E0F9),
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
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

  // Şimdiki zamanı formatlama
  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  // Hava durumu ikonunu belirleme
  IconData _getWeatherIcon(String iconCode) {
    // Open-Meteo ikonları farklı olduğu için, basit bir eşleme yapıyoruz
    if (iconCode.contains('clear')) {
      return Icons.wb_sunny;
    } else if (iconCode.contains('few')) {
      return Icons.wb_cloudy;
    } else if (iconCode.contains('scattered')) {
      return Icons.cloud;
    } else if (iconCode.contains('broken')) {
      return Icons.cloud_queue;
    } else if (iconCode.contains('shower')) {
      return Icons.grain;
    } else if (iconCode.contains('rain')) {
      return Icons.beach_access;
    } else if (iconCode.contains('thunder')) {
      return Icons.flash_on;
    } else if (iconCode.contains('snow')) {
      return Icons.ac_unit;
    } else if (iconCode.contains('mist')) {
      return Icons.blur_on;
    } else {
      return Icons.help_outline;
    }
  }
} 