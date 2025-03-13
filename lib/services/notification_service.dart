import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import 'firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Bildirim türleri
  static const String _dangerType = 'danger';
  static const String _warningType = 'warning';
  static const String _infoType = 'info';

  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();

  // Bildirim servisini başlatma
  Future<void> init() async {
    // FCM izinleri
    await _requestPermissions();
    
    // FCM token alma
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
    
    // Token'ı Firestore'a kaydet (kullanıcı giriş yapmışsa)
    if (token != null && _auth.currentUser != null) {
      await saveFcmToken(token);
    }
    
    // Token yenilendiğinde
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('FCM Token yenilendi: $newToken');
      if (_auth.currentUser != null) {
        saveFcmToken(newToken);
      }
    });
    
    // Arka planda gelen FCM mesajlarını dinleme
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Uygulama açıkken gelen FCM mesajlarını dinleme
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Bildirime tıklandığında
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  // FCM token'ı Firestore'a kaydetme
  Future<void> saveFcmToken(String token) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;
      
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      
      print('FCM token Firestore\'a kaydedildi');
    } catch (e) {
      print('FCM token kaydedilirken hata oluştu: $e');
    }
  }

  // FCM izinleri isteme
  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: true, // Kritik bildirimler için izin iste
      announcement: true, // Bildirim duyuruları için izin iste
    );
    
    print('FCM izin durumu: ${settings.authorizationStatus}');
    
    // iOS için bildirim kanalı oluştur
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // Tehlikeli hava kalitesi bildirimi gönderme
  Future<void> sendDangerousAirQualityNotification({
    required String userId,
    required String location,
    required double aqi,
    required String category,
  }) async {
    // Bildirim modeli oluştur
    final notification = NotificationModel.createDangerousAirQualityNotification(
      userId: userId,
      location: location,
      aqi: aqi,
      category: category,
    );
    
    // Firestore'a kaydet
    await _firebaseService.saveNotification(notification);
    
    // Not: Artık bildirimler Firebase Cloud Functions tarafından otomatik olarak gönderilecek
    print('Tehlikeli hava kalitesi bildirimi Firestore\'a kaydedildi: ${notification.title}');
    
    // Kullanıcı arayüzünde bildirim göstermek için bir yöntem
    // Bu, uygulama açıkken kullanılabilir
    _showInAppNotification(notification.title, notification.body);
  }

  // Uygulama içi bildirim gösterme (SnackBar veya Dialog olarak)
  void _showInAppNotification(String title, String body) {
    // Bu metod, global bir key kullanarak herhangi bir yerden SnackBar gösterebilir
    // Örnek: navigatorKey.currentState?.overlay?.context
    print('Uygulama içi bildirim gösteriliyor: $title - $body');
    
    // Not: Bu metodu kullanmak için, main.dart dosyasında bir GlobalKey<NavigatorState> tanımlamanız
    // ve MaterialApp widget'ına bu key'i vermeniz gerekir.
    // Daha sonra bu key'i kullanarak herhangi bir yerden SnackBar gösterebilirsiniz.
  }

  // Bildirim türüne göre renk belirleme
  Color _getNotificationColor(String type) {
    switch (type) {
      case _dangerType:
        return const Color(0xFFFF0000); // Kırmızı
      case _warningType:
        return const Color(0xFFFF9800); // Turuncu
      case _infoType:
        return const Color(0xFF2196F3); // Mavi
      default:
        return const Color(0xFF4CAF50); // Yeşil
    }
  }
  
  // Bildirim gösterme metodu (uygulama açıkken)
  void showNotification(BuildContext? context, String title, String body, {String type = 'info'}) {
    // Eğer context null ise, bildirim gösterme
    if (context == null) {
      print('Context null olduğu için bildirim gösterilemiyor: $title - $body');
      return;
    }
    
    final Color backgroundColor = _getNotificationColor(type);
    
    // SnackBar göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'Tamam',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

// Arka planda FCM mesajlarını işleme
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Arka planda mesaj alındı: ${message.messageId}');
  
  // Burada arka planda bildirim işleme mantığı olabilir
  // Not: Bu fonksiyon, uygulama arka plandayken veya kapalıyken çalışır
}

// Ön planda FCM mesajlarını işleme
void _handleForegroundMessage(RemoteMessage message) {
  print('Ön planda mesaj alındı: ${message.messageId}');
  
  // Yerel bildirim gösterme
  final notification = message.notification;
  final data = message.data;
  
  if (notification != null) {
    print('Bildirim alındı (FCM): ${notification.title} - ${notification.body}');
    
    // Not: Burada, uygulama açıkken bildirim göstermek için
    // navigatorKey.currentContext kullanarak showNotification metodunu çağırabilirsiniz
    // Örnek:
    // if (navigatorKey.currentContext != null) {
    //   NotificationService().showNotification(
    //     navigatorKey.currentContext!,
    //     notification.title ?? 'Hava Kalitesi Bildirimi',
    //     notification.body ?? 'Yeni bir bildiriminiz var',
    //     type: data['type'] ?? 'info',
    //   );
    // }
  }
}

// Bildirime tıklanarak uygulama açıldığında
void _handleMessageOpenedApp(RemoteMessage message) {
  print('Bildirime tıklanarak uygulama açıldı: ${message.messageId}');
  
  // Burada bildirime tıklanarak uygulama açıldığında yapılacak işlemler olabilir
  // Örneğin, belirli bir sayfaya yönlendirme yapabilirsiniz
} 