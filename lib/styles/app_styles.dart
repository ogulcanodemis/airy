import 'package:flutter/material.dart';

class AppStyles {
  // Ana renkler
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color primaryDarkColor = Color(0xFF0D47A1);
  static const Color primaryLightColor = Color(0xFF64B5F6);
  static const Color accentColor = Color(0xFF03A9F4);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  
  // Metin renkleri
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color textLightColor = Color(0xFFFFFFFF);
  
  // Hava kalitesi renkleri
  static const Color airQualityGood = Color(0xFF4CAF50);
  static const Color airQualityModerate = Color(0xFFFFEB3B);
  static const Color airQualitySensitive = Color(0xFFFF9800);
  static const Color airQualityUnhealthy = Color(0xFFFF5722);
  static const Color airQualityVeryUnhealthy = Color(0xFF9C27B0);
  static const Color airQualityHazardous = Color(0xFF8B0000);
  
  // Gölge
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
  
  // Kart stili
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: cardShadow,
  );
  
  // Gradient arka planlar
  static LinearGradient primaryGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF82E0F9), Color(0xFF5BBCD9)],
  );
  
  static LinearGradient accentGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF9CC3E), Color(0xFFE5B82A)],
  );
  
  static LinearGradient airQualityGradient(String category) {
    switch (category) {
      case 'İyi':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF81C784), Color(0xFF388E3C)],
        );
      case 'Orta':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF176), Color(0xFFFBC02D)],
        );
      case 'Hassas Gruplar İçin Sağlıksız':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFB74D), Color(0xFFE65100)],
        );
      case 'Sağlıksız':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8A65), Color(0xFFBF360C)],
        );
      case 'Çok Sağlıksız':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFBA68C8), Color(0xFF4A148C)],
        );
      case 'Tehlikeli':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE57373), Color(0xFF8B0000)],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0E0E0), Color(0xFF9E9E9E)],
        );
    }
  }
  
  // Metin stilleri
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );
  
  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );
  
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: textPrimaryColor,
  );
  
  static const TextStyle captionStyle = TextStyle(
    fontSize: 14,
    color: textSecondaryColor,
  );
  
  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: textLightColor,
  );
  
  // Buton stilleri
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: textLightColor,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
    elevation: 3,
  );
  
  static ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    side: const BorderSide(color: primaryColor, width: 2),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
  );
} 