import 'dart:async';
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  List<NotificationModel> _notifications = [];
  StreamSubscription<List<NotificationModel>>? _notificationSubscription;
  bool _isLoading = false;
  String _error = '';

  // Getters
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Kullanıcı bildirimlerini dinlemeye başlama
  void startListeningNotifications(String userId) {
    // Önceki aboneliği iptal et
    stopListeningNotifications();

    // Yeni abonelik oluştur
    _notificationSubscription = _firebaseService.getUserNotifications(userId).listen(
      (notifications) {
        _notifications = notifications;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Bildirimler alınırken hata oluştu: $e';
        notifyListeners();
      },
    );
  }

  // Bildirim dinlemeyi durdurma
  void stopListeningNotifications() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
  }

  // Bildirimi okundu olarak işaretleme
  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firebaseService.markNotificationAsRead(userId, notificationId);
      
      // Yerel listeyi güncelle
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].markAsRead();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Bildirim okundu olarak işaretlenirken hata oluştu: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Tüm bildirimleri okundu olarak işaretleme
  Future<void> markAllNotificationsAsRead(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final unreadNotifications = _notifications.where((n) => !n.isRead).toList();
      
      for (var notification in unreadNotifications) {
        await _firebaseService.markNotificationAsRead(userId, notification.id);
      }
      
      // Yerel listeyi güncelle
      _notifications = _notifications.map((n) => n.isRead ? n : n.markAsRead()).toList();
    } catch (e) {
      _error = 'Bildirimler okundu olarak işaretlenirken hata oluştu: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Bildirimi silme
  Future<void> deleteNotification(String userId, String notificationId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Firestore'dan sil
      await _firebaseService.deleteNotification(userId, notificationId);
      
      // Yerel listeden sil
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      _error = 'Bildirim silinirken hata oluştu: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Bildirim türüne göre ikon döndürme
  IconData getNotificationIcon(String type) {
    switch (type) {
      case 'danger':
        return Icons.warning;
      case 'warning':
        return Icons.info;
      case 'info':
        return Icons.notifications;
      default:
        return Icons.notifications;
    }
  }

  // Bildirim türüne göre renk döndürme
  Color getNotificationColor(String type) {
    switch (type) {
      case 'danger':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Hata mesajını temizleme
  void clearError() {
    _error = '';
    notifyListeners();
  }

  @override
  void dispose() {
    stopListeningNotifications();
    super.dispose();
  }
} 