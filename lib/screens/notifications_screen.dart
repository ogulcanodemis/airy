import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../styles/app_styles.dart';
import '../widgets/animated_widgets.dart';
import '../services/firebase_service.dart';
import '../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isDeleting = false;
  String? _deletingId;
  bool _showAllNotifications = false; // Tüm bildirimleri gösterme durumu

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Bildirim sayısını kontrol et
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    print('NotificationsScreen: Bildirim sayısı: ${notificationProvider.notifications.length}');
    
    // Kullanıcı kimliğini kontrol et
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      print('NotificationsScreen: Kullanıcı kimliği: ${authProvider.firebaseUser!.uid}');
    } else {
      print('NotificationsScreen: Kullanıcı oturum açmamış');
    }

    // Bildirimleri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authProvider.firebaseUser != null) {
        notificationProvider.startListeningNotifications(authProvider.firebaseUser!.uid);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    // Bildirim dinlemeyi durdur
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    notificationProvider.stopListeningNotifications();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // Beyaz arka plan
      body: AnimatedBackground(
        color1: const Color(0xFF82E0F9), // Açık mavi
        color2: const Color(0xFFF9CC3E), // Sarı
        bubbleCount: 8,
        child: SafeArea(
          child: Column(
            children: [
              // Üst kısım - Başlık ve butonlar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Geri butonu
                    Container(
                      decoration: BoxDecoration(
                        color: AppStyles.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppStyles.primaryColor,
                          size: 26,
                        ),
                        tooltip: 'Geri',
                        padding: const EdgeInsets.all(10.0),
                        constraints: const BoxConstraints(
                          minWidth: 46,
                          minHeight: 46,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    
                    // Başlık
                    const Text(
                      'Bildirimler',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppStyles.primaryColor,
                      ),
                    ),
                    
                    // Sağ taraftaki butonlar
                    Row(
                      children: [
                        // Tüm bildirimleri okundu olarak işaretleme butonu
                        if (notificationProvider.unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: AppStyles.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.done_all,
                                color: AppStyles.primaryColor,
                                size: 26,
                              ),
                              tooltip: 'Tümünü okundu olarak işaretle',
                              padding: const EdgeInsets.all(10.0),
                              constraints: const BoxConstraints(
                                minWidth: 46,
                                minHeight: 46,
                              ),
                              onPressed: () {
                                if (authProvider.firebaseUser != null) {
                                  notificationProvider.markAllNotificationsAsRead(authProvider.firebaseUser!.uid);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Tüm bildirimler okundu olarak işaretlendi')),
                                  );
                                }
                              },
                            ),
                          ),
                        
                        // Tüm bildirimleri silme butonu
                        if (notificationProvider.notifications.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              color: AppStyles.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.delete_sweep,
                                color: AppStyles.primaryColor,
                                size: 26,
                              ),
                              tooltip: 'Tüm bildirimleri sil',
                              padding: const EdgeInsets.all(10.0),
                              constraints: const BoxConstraints(
                                minWidth: 46,
                                minHeight: 46,
                              ),
                              onPressed: () {
                                _showDeleteAllConfirmationDialog(context);
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Ana içerik
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _buildNotificationList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    if (notificationProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (notificationProvider.error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              notificationProvider.error,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (authProvider.firebaseUser != null) {
                  notificationProvider.startListeningNotifications(authProvider.firebaseUser!.uid);
                }
              },
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }
    
    if (notificationProvider.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_off,
              color: Colors.grey,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Henüz bildiriminiz yok',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notificationProvider.notifications.length,
      itemBuilder: (context, index) {
        final notification = notificationProvider.notifications[index];
        return _buildNotificationItem(notification);
      },
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final Color iconColor = notificationProvider.getNotificationColor(notification.type);
    final IconData iconData = notificationProvider.getNotificationIcon(notification.type);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Bildirimi okundu olarak işaretle
          if (!notification.isRead && authProvider.firebaseUser != null) {
            notificationProvider.markNotificationAsRead(
              authProvider.firebaseUser!.uid,
              notification.id,
            );
          }
          
          // Bildirim detaylarını göster
          _showNotificationDetails(context, notification, iconColor, iconData);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // İkon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // İçerik
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        // Okunmadı işareti
                        if (!notification.isRead)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppStyles.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tarih
                        Text(
                          _formatDateTime(notification.timestamp),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        
                        // Silme butonu
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.grey,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            _showDeleteConfirmationDialog(context, notification.id);
                          },
                        ),
                      ],
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Az önce';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, String notificationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bildirimi Sil'),
        content: const Text('Bu bildirimi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
              
              if (authProvider.firebaseUser != null) {
                notificationProvider.deleteNotification(
                  authProvider.firebaseUser!.uid,
                  notificationId,
                );
              }
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm Bildirimleri Sil'),
        content: const Text('Tüm bildirimleri silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
              
              if (authProvider.firebaseUser != null) {
                notificationProvider.deleteAllNotifications(authProvider.firebaseUser!.uid);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tüm bildirimler silindi')),
                );
              }
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  // Bildirim detaylarını gösterme
  void _showNotificationDetails(
    BuildContext context,
    NotificationModel notification,
    Color color,
    IconData icon,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 15,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Başlık çubuğu
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF82E0F9), // Açık mavi
                    Color(0xFFF9CC3E), // Sarı
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Kolu
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Başlık
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          notification.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 2.0,
                                color: Colors.black26,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Zaman
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDateTimeDetailed(notification.timestamp),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // İçerik
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mesaj
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF82E0F9).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.message,
                            color: Color(0xFF82E0F9),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Mesaj',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        notification.body,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    
                    // Hava kalitesi bilgileri
                    if (notification.data != null && 
                        notification.data!.containsKey('location') && 
                        notification.data!['location'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9CC3E).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.air,
                                  color: Color(0xFFF9CC3E),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Hava Kalitesi Bilgileri',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildDetailInfoRow(
                                  icon: Icons.location_on,
                                  title: 'Konum',
                                  value: notification.data!['location'],
                                  color: const Color(0xFF82E0F9),
                                ),
                                if (notification.data!.containsKey('aqi') && notification.data!['aqi'] != null)
                                  Column(
                                    children: [
                                      const Divider(height: 24),
                                      _buildDetailInfoRow(
                                        icon: Icons.air,
                                        title: 'AQI',
                                        value: notification.data!['aqi'].toString(),
                                        color: const Color(0xFFF9CC3E),
                                      ),
                                    ],
                                  ),
                                if (notification.data!.containsKey('category') && notification.data!['category'] != null)
                                  Column(
                                    children: [
                                      const Divider(height: 24),
                                      _buildDetailInfoRow(
                                        icon: Icons.category,
                                        title: 'Kategori',
                                        value: notification.data!['category'],
                                        color: const Color(0xFF82E0F9),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            
            // Alt butonlar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF82E0F9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: const Text('Kapat'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bilgi satırı (detay sayfası için)
  Widget _buildDetailInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  // Tarih formatı (detaylı)
  String _formatDateTimeDetailed(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$day/$month/$year $hour:$minute';
  }
} 