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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.notifications_active, size: 24),
            const SizedBox(width: 8),
            const Text('Bildirimler'),
            if (notificationProvider.unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${notificationProvider.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Tüm bildirimleri okundu olarak işaretleme butonu
          if (notificationProvider.unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: () {
                if (authProvider.isAuthenticated) {
                  _showMarkAllReadConfirmation(
                    context, 
                    authProvider.firebaseUser!.uid,
                    notificationProvider,
                  );
                }
              },
              tooltip: 'Tümünü okundu olarak işaretle',
            ),
          // Bildirim silme butonu
          if (notificationProvider.notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                if (authProvider.isAuthenticated) {
                  _showDeleteAllConfirmation(
                    context, 
                    authProvider.firebaseUser!.uid,
                    notificationProvider,
                  );
                }
              },
              tooltip: 'Tüm bildirimleri sil',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppStyles.primaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: _buildNotificationsList(notificationProvider, authProvider),
      ),
    );
  }

  Widget _buildNotificationsList(NotificationProvider notificationProvider, AuthProvider authProvider) {
    print('NotificationsScreen: _buildNotificationsList çağrıldı');
    print('NotificationsScreen: isLoading: ${notificationProvider.isLoading}');
    print('NotificationsScreen: notifications.length: ${notificationProvider.notifications.length}');
    
    if (notificationProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (notificationProvider.notifications.isEmpty) {
      print('NotificationsScreen: Bildirim bulunamadı');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Bildirim bulunmuyor',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yeni bildirimler geldiğinde burada görünecek',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    // Gösterilecek bildirimleri belirle
    final allNotifications = notificationProvider.notifications;
    final hasMoreNotifications = allNotifications.length > 20;
    
    // Eğer _showAllNotifications false ise, sadece son 20 bildirimi göster
    final displayedNotifications = _showAllNotifications 
        ? allNotifications 
        : allNotifications.take(20).toList();
    
    print('NotificationsScreen: ${displayedNotifications.length} bildirim gösteriliyor');

    return RefreshIndicator(
      onRefresh: () async {
        // Bildirimleri yenileme işlemi
        if (authProvider.isAuthenticated) {
          print('NotificationsScreen: Bildirimler yenileniyor...');
          notificationProvider.stopListeningNotifications();
          notificationProvider.startListeningNotifications(
            authProvider.firebaseUser!.uid,
          );
        }
      },
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: displayedNotifications.length,
              itemBuilder: (context, index) {
                final notification = displayedNotifications[index];
                final color = notificationProvider.getNotificationColor(notification.type);
                final icon = notificationProvider.getNotificationIcon(notification.type);
                
                return Dismissible(
                  key: Key(notification.id),
                  background: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20.0),
                    child: _isDeleting && _deletingId == notification.id
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          )
                        : const Icon(
                            Icons.delete_sweep,
                            color: Colors.white,
                            size: 28,
                          ),
                  ),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await _showDeleteConfirmation(context);
                  },
                  onDismissed: (direction) {
                    if (authProvider.isAuthenticated) {
                      setState(() {
                        _isDeleting = true;
                        _deletingId = notification.id;
                      });
                      
                      notificationProvider.deleteNotification(
                        authProvider.firebaseUser!.uid,
                        notification.id,
                      ).then((_) {
                        setState(() {
                          _isDeleting = false;
                          _deletingId = null;
                        });
                      });
                    }
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 2.0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.0),
                        border: notification.isRead
                            ? null
                            : Border.all(
                                color: color.withOpacity(0.5),
                                width: 1.5,
                              ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              icon,
                              color: color,
                              size: 24,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: notification.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text(
                              notification.body,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDateTime(notification.timestamp),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                            if (notification.data != null && 
                                notification.data!.containsKey('location') && 
                                notification.data!['location'] != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      notification.data!['location'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        onTap: () {
                          if (!notification.isRead && authProvider.isAuthenticated) {
                            notificationProvider.markNotificationAsRead(
                              authProvider.firebaseUser!.uid,
                              notification.id,
                            );
                          }
                          
                          // Bildirim detaylarını gösterme
                          _showNotificationDetails(context, notification, color, icon);
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Daha fazla bildirim varsa "Tümünü Göster" butonu
          if (hasMoreNotifications)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showAllNotifications = !_showAllNotifications;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_showAllNotifications ? Icons.visibility_off : Icons.visibility),
                    const SizedBox(width: 8),
                    Text(_showAllNotifications ? 'Son 20 Bildirimi Göster' : 'Tüm Bildirimleri Göster'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Bildirim silme onayı
  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bildirimi Sil'),
        content: const Text('Bu bildirimi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    ) ?? false;
  }

  // Tüm bildirimleri okundu olarak işaretleme onayı
  void _showMarkAllReadConfirmation(
    BuildContext context,
    String userId,
    NotificationProvider notificationProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tümünü Okundu İşaretle'),
        content: const Text('Tüm bildirimleri okundu olarak işaretlemek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              notificationProvider.markAllNotificationsAsRead(userId);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tüm bildirimler okundu olarak işaretlendi'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Evet'),
          ),
        ],
      ),
    );
  }

  // Tüm bildirimleri silme onayı
  void _showDeleteAllConfirmation(
    BuildContext context,
    String userId,
    NotificationProvider notificationProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm Bildirimleri Sil'),
        content: const Text('Tüm bildirimleri silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              
              // Tüm bildirimleri sil
              setState(() {
                _isDeleting = true;
              });
              
              // Tüm bildirimleri silme işlemi
              _deleteAllNotifications(userId, notificationProvider);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  // Tüm bildirimleri silme işlemi
  Future<void> _deleteAllNotifications(String userId, NotificationProvider notificationProvider) async {
    try {
      await notificationProvider.deleteAllNotifications(userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tüm bildirimler silindi'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  // Bildirim detaylarını gösterme
  void _showNotificationDetails(
    BuildContext context,
    dynamic notification,
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
        ),
        child: Column(
          children: [
            // Başlık çubuğu
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
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
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Başlık
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          notification.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Zaman
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tarih: ${_formatDateTimeDetailed(notification.timestamp)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // İçerik
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mesaj
                    const Text(
                      'Mesaj',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        notification.body,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
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
                          const Text(
                            'Hava Kalitesi Bilgileri',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                _buildInfoRow(
                                  icon: Icons.location_on,
                                  title: 'Konum',
                                  value: notification.data!['location'],
                                ),
                                const Divider(),
                                _buildInfoRow(
                                  icon: Icons.air,
                                  title: 'AQI',
                                  value: notification.data!['aqi'].toString(),
                                ),
                                const Divider(),
                                _buildInfoRow(
                                  icon: Icons.category,
                                  title: 'Kategori',
                                  value: notification.data!['category'],
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
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  // Bilgi satırı
  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Text(
            '$title:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // Tarih formatı (kısa)
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Az önce';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dk önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
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