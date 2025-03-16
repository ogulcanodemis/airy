import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../models/air_quality_model.dart';
import 'air_quality_gauge.dart';
import 'animated_widgets.dart';

class AirQualityCard extends StatelessWidget {
  final AirQualityModel airQuality;
  final VoidCallback? onTap;

  const AirQualityCard({
    Key? key,
    required this.airQuality,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Hava kalitesi kategorisine göre renk belirle
    final String category = airQuality.category;
    
    // Yeni renk şemasına göre gradient belirle
    final LinearGradient cardGradient;
    if (category == 'İyi' || category == 'Orta') {
      // İyi ve orta kategoriler için sarı gradient
      cardGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF9CC3E), // Sarı
          Color(0xFFE5B82A), // Sarının koyu tonu
        ],
      );
    } else {
      // Diğer kategoriler için mavi gradient
      cardGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF82E0F9), // Açık mavi
          Color(0xFF5BBCD9), // Açık mavinin koyu tonu
        ],
      );
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppStyles.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Arka plan gradient
              Container(
                decoration: BoxDecoration(
                  gradient: cardGradient,
                ),
              ),
              
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
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık ve kategori
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                airQuality.location,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                children: [
                                  Text(
                                    'Güncelleme: ${_formatDateTime(airQuality.timestamp)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFFFF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Kaynak: ${airQuality.source}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: category == 'İyi' || category == 'Orta'
                                            ? const Color(0xFFF9CC3E) // Sarı
                                            : const Color(0xFF82E0F9), // Açık mavi
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF), // Beyaz
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            airQuality.category,
                            style: TextStyle(
                              color: category == 'İyi' || category == 'Orta'
                                  ? const Color(0xFFF9CC3E) // Sarı
                                  : const Color(0xFF82E0F9), // Açık mavi
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // AQI göstergesi ve değerler
                    Row(
                      children: [
                        // AQI göstergesi
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: BreathingAnimation(
                              minScale: 0.95,
                              maxScale: 1.05,
                              duration: const Duration(seconds: 4),
                              child: AirQualityGauge(
                                aqi: airQuality.aqi,
                                category: airQuality.category,
                                size: 150,
                              ),
                            ),
                          ),
                        ),
                        
                        // Kirletici değerleri
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPollutantItem('PM2.5', airQuality.pollutants['pm25']),
                              _buildPollutantItem('PM10', airQuality.pollutants['pm10']),
                              _buildPollutantItem('O3', airQuality.pollutants['o3']),
                              _buildPollutantItem('NO2', airQuality.pollutants['no2']),
                              _buildPollutantItem('SO2', airQuality.pollutants['so2']),
                              _buildPollutantItem('CO', airQuality.pollutants['co']),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Tavsiye
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF), // Beyaz
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getAdviceIcon(airQuality.category),
                            color: category == 'İyi' || category == 'Orta'
                                ? const Color(0xFFF9CC3E) // Sarı
                                : const Color(0xFF82E0F9), // Açık mavi
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _getAdviceText(airQuality.category),
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Detaylar butonu
                    if (onTap != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: onTap,
                          icon: const Icon(Icons.info_outline, color: Colors.white),
                          label: const Text(
                            'Detaylar',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: category == 'İyi' || category == 'Orta'
                                ? const Color(0xFF82E0F9) // Açık mavi
                                : const Color(0xFFF9CC3E), // Sarı
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
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
      ),
    );
  }

  Widget _buildPollutantItem(String name, double? value) {
    if (value == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF), // Beyaz
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              name,
              style: const TextStyle(
                color: Color(0xFF212121), // Koyu gri
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${value.toStringAsFixed(1)} µg/m³',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Az önce';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'İyi':
        return AppStyles.airQualityGood;
      case 'Orta':
        return AppStyles.airQualityModerate;
      case 'Hassas Gruplar İçin Sağlıksız':
        return AppStyles.airQualitySensitive;
      case 'Sağlıksız':
        return AppStyles.airQualityUnhealthy;
      case 'Çok Sağlıksız':
        return AppStyles.airQualityVeryUnhealthy;
      case 'Tehlikeli':
        return AppStyles.airQualityHazardous;
      default:
        return Colors.grey;
    }
  }

  IconData _getAdviceIcon(String category) {
    switch (category) {
      case 'İyi':
        return Icons.check_circle;
      case 'Orta':
        return Icons.thumb_up;
      case 'Hassas Gruplar İçin Sağlıksız':
        return Icons.warning;
      case 'Sağlıksız':
        return Icons.report_problem;
      case 'Çok Sağlıksız':
        return Icons.dangerous;
      case 'Tehlikeli':
        return Icons.emergency;
      default:
        return Icons.info;
    }
  }

  String _getAdviceText(String category) {
    switch (category) {
      case 'İyi':
        return 'Hava kalitesi iyi. Dışarıda aktivite yapmak için uygun bir gün.';
      case 'Orta':
        return 'Hava kalitesi kabul edilebilir düzeyde. Hassas gruplar için bazı kirleticiler sorun olabilir.';
      case 'Hassas Gruplar İçin Sağlıksız':
        return 'Hassas gruplar (astım hastaları, yaşlılar, çocuklar) sağlık etkileri yaşayabilir. Uzun süreli dış mekan aktivitelerini sınırlayın.';
      case 'Sağlıksız':
        return 'Herkes sağlık etkileri yaşayabilir. Hassas gruplar ciddi sağlık etkileri yaşayabilir. Dış mekan aktivitelerini sınırlayın.';
      case 'Çok Sağlıksız':
        return 'Sağlık uyarısı: Herkes daha ciddi sağlık etkileri yaşayabilir. Tüm dış mekan aktivitelerini sınırlayın.';
      case 'Tehlikeli':
        return 'Acil durum koşulları. Tüm nüfus etkilenebilir. Dış mekan aktivitelerinden kaçının ve pencerelerinizi kapalı tutun.';
      default:
        return 'Hava kalitesi verisi mevcut değil.';
    }
  }
} 