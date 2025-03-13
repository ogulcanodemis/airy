import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../widgets/animated_widgets.dart';

class PollenCard extends StatelessWidget {
  final Map<String, dynamic> pollenData;

  const PollenCard({
    Key? key,
    required this.pollenData,
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
            Color(0xFF8BC34A),
            Color(0xFF4CAF50),
          ],
        ),
        boxShadow: AppStyles.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Parçacık animasyonu
            ParticleAnimation(
              color: Colors.white,
              particleCount: 10,
              child: Container(
                width: double.infinity,
                height: 180,
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
                      BreathingAnimation(
                        child: Icon(
                          Icons.grass,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Polen Seviyeleri',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Polen verileri
                  if (pollenData.isEmpty)
                    const Text(
                      'Polen verisi bulunamadı',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    )
                  else
                    Column(
                      children: pollenData.entries.map((entry) {
                        final pollenType = entry.key;
                        final pollenInfo = entry.value;
                        final level = pollenInfo['level'] ?? 'Bilinmiyor';
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              _getPollenIcon(pollenType),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pollenType,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Seviye: $level',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _getPollenLevelIndicator(level),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  
                  const SizedBox(height: 10),
                  
                  // Bilgi notu
                  const Text(
                    'Not: Polen verileri sadece Google Air Quality API tarafından sağlanmaktadır.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.white70,
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

  Widget _getPollenIcon(String pollenType) {
    IconData iconData;
    
    switch (pollenType) {
      case 'Çim':
        iconData = Icons.grass;
        break;
      case 'Ağaç':
        iconData = Icons.park;
        break;
      case 'Yabani Ot':
        iconData = Icons.eco;
        break;
      default:
        iconData = Icons.grass;
    }
    
    return Icon(
      iconData,
      color: Colors.white,
      size: 24,
    );
  }

  Widget _getPollenLevelIndicator(String level) {
    Color color;
    int filledDots;
    
    switch (level) {
      case 'Düşük':
        color = Colors.green.shade100;
        filledDots = 1;
        break;
      case 'Orta':
        color = Colors.yellow;
        filledDots = 2;
        break;
      case 'Yüksek':
        color = Colors.orange;
        filledDots = 3;
        break;
      case 'Çok Yüksek':
        color = Colors.red;
        filledDots = 4;
        break;
      case 'Aşırı':
        color = Colors.purple;
        filledDots = 5;
        break;
      default:
        color = Colors.grey;
        filledDots = 0;
    }
    
    return Row(
      children: List.generate(5, (index) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < filledDots ? color : Colors.white.withOpacity(0.3),
          ),
        );
      }),
    );
  }
} 