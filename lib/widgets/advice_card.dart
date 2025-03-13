import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import 'animated_widgets.dart';

class AdviceCard extends StatelessWidget {
  final String category;
  final String advice;

  const AdviceCard({
    Key? key,
    required this.category,
    required this.advice,
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
            _getCategoryColor(category).withOpacity(0.7),
            _getCategoryColor(category),
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
              top: -20,
              right: -20,
              width: 100,
              height: 100,
              child: PulseAnimation(
                duration: const Duration(seconds: 3),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ),
            
            Positioned(
              bottom: -30,
              left: -30,
              width: 120,
              height: 120,
              child: PulseAnimation(
                duration: const Duration(seconds: 4),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
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
                        child: Icon(
                          _getCategoryIcon(category),
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Tavsiyeler',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Kategori etiketi
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tavsiye metni
                  Text(
                    advice,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Önlemler
                  if (_shouldShowPrecautions(category))
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Alınabilecek Önlemler:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._getPrecautions(category).map((precaution) => 
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    precaution,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).toList(),
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

  IconData _getCategoryIcon(String category) {
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

  bool _shouldShowPrecautions(String category) {
    switch (category) {
      case 'İyi':
      case 'Orta':
        return false;
      default:
        return true;
    }
  }

  List<String> _getPrecautions(String category) {
    switch (category) {
      case 'Hassas Gruplar İçin Sağlıksız':
        return [
          'Astım hastaları, yaşlılar ve çocuklar uzun süreli dış mekan aktivitelerini sınırlamalıdır.',
          'Pencerelerinizi kapalı tutun ve iç mekan hava temizleyicileri kullanın.',
          'Fiziksel aktivitelerinizi sabah erken saatlere veya akşam geç saatlere planlayın.',
        ];
      case 'Sağlıksız':
        return [
          'Herkes dış mekan aktivitelerini sınırlamalıdır.',
          'Hassas gruplar mümkünse evde kalmalıdır.',
          'Dışarı çıkmanız gerekiyorsa, N95 veya FFP2 maske kullanın.',
          'Kapalı alanlarda hava temizleyici kullanın.',
        ];
      case 'Çok Sağlıksız':
        return [
          'Tüm dış mekan aktivitelerini iptal edin veya iç mekana taşıyın.',
          'Pencere ve kapıları sıkıca kapatın.',
          'Hava filtresi olan bir maske olmadan dışarı çıkmayın.',
          'Hassas gruplar için acil sağlık planı hazırlayın.',
        ];
      case 'Tehlikeli':
        return [
          'Acil durumlar dışında dışarı çıkmayın.',
          'Tüm pencere ve kapıları sızdırmaz hale getirin.',
          'Hava temizleyicileri maksimum ayarda çalıştırın.',
          'Solunum problemleri yaşıyorsanız hemen tıbbi yardım alın.',
          'Bölgesel tahliye uyarılarını takip edin.',
        ];
      default:
        return [];
    }
  }
} 