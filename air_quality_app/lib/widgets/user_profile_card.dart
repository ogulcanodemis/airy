import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../models/user_model.dart';
import 'animated_widgets.dart';

class UserProfileCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onLogout;
  final VoidCallback? onSettings;

  const UserProfileCard({
    Key? key,
    required this.user,
    this.onLogout,
    this.onSettings,
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
            Color(0xFF6A11CB),
            Color(0xFF2575FC),
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
              particleCount: 15,
              child: Container(
                width: double.infinity,
                height: 180, // Sabit bir yükseklik belirle
              ),
            ),
            
            // İçerik
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar ve kullanıcı bilgileri
                  Row(
                    children: [
                      // Avatar
                      BreathingAnimation(
                        minScale: 0.95,
                        maxScale: 1.05,
                        duration: const Duration(seconds: 3),
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 20),
                      
                      // Kullanıcı bilgileri
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Merhaba, ${user.displayName}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Son giriş: ${_formatDateTime(user.lastLoginAt)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Butonlar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (onSettings != null)
                        _buildActionButton(
                          icon: Icons.settings,
                          label: 'Ayarlar',
                          onPressed: onSettings!,
                        ),
                      
                      const SizedBox(width: 12),
                      
                      if (onLogout != null)
                        _buildActionButton(
                          icon: Icons.logout,
                          label: 'Çıkış Yap',
                          onPressed: onLogout!,
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.2),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
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
} 