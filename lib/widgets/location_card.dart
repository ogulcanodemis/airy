import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../widgets/animated_widgets.dart';
import 'package:geolocator/geolocator.dart';

class LocationCard extends StatelessWidget {
  final String? address;
  final Position? position;
  final bool isLoading;
  final bool hasPermission;
  final VoidCallback onRequestPermission;

  const LocationCard({
    Key? key,
    this.address,
    this.position,
    required this.isLoading,
    required this.hasPermission,
    required this.onRequestPermission,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: AppStyles.primaryGradient,
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
                          Icons.location_on,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Konum Bilgileri',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // İçerik
                  if (isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else if (!hasPermission)
                    _buildPermissionRequest()
                  else if (position != null)
                    _buildLocationInfo()
                  else
                    const Center(
                      child: Text(
                        'Konum bilgisi alınamadı',
                        style: TextStyle(color: Colors.white),
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

  Widget _buildPermissionRequest() {
    return Column(
      children: [
        const Text(
          'Hava kalitesi verilerini görmek için konum izni gerekiyor.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: onRequestPermission,
            icon: const Icon(Icons.location_searching),
            label: const Text('Konum İzni Ver'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppStyles.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Adres
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.place,
              color: Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                address ?? 'Bilinmeyen Konum',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Koordinatlar
        Row(
          children: [
            Expanded(
              child: _buildCoordinateItem(
                'Enlem',
                position!.latitude.toStringAsFixed(6),
                Icons.north,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCoordinateItem(
                'Boylam',
                position!.longitude.toStringAsFixed(6),
                Icons.east,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Ek bilgiler
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                'Yükseklik',
                '${position!.altitude.toStringAsFixed(1)} m',
                Icons.height,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoItem(
                'Doğruluk',
                '${position!.accuracy.toStringAsFixed(1)} m',
                Icons.gps_fixed,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCoordinateItem(String title, String value, IconData icon) {
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 