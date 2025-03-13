import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/user_location_model.dart';
import '../models/notification_model.dart';
import '../models/user_settings_model.dart';
import '../models/air_quality_model.dart';
import 'dart:math' as math;

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcı kimlik doğrulama işlemleri
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      // reCAPTCHA doğrulamasını devre dışı bırak
      await _auth.setSettings(appVerificationDisabledForTesting: true);
      
      // Normal email/password girişi
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Son giriş zamanını güncelle
      await _firestore.collection('users').doc(result.user!.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      
      return result.user;
    } catch (e) {
      throw Exception('Giriş yapılırken hata oluştu: $e');
    }
  }

  Future<User?> registerWithEmailAndPassword(String email, String password, String displayName) async {
    try {
      // reCAPTCHA doğrulamasını devre dışı bırak
      await _auth.setSettings(appVerificationDisabledForTesting: true);
      
      // Normal email/password kaydı
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Kullanıcı profili oluştur
      await _firestore.collection('users').doc(result.user!.uid).set({
        'email': email,
        'displayName': displayName,
        'isAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      
      // Kullanıcı ayarlarını oluştur
      await _firestore.collection('users').doc(result.user!.uid).collection('settings').doc('user_settings').set(
        UserSettingsModel.createDefaultSettings(result.user!.uid).toMap()
      );
      
      return result.user;
    } catch (e) {
      throw Exception('Kayıt olurken hata oluştu: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Kullanıcı profil işlemleri
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      
      return null;
    } catch (e) {
      throw Exception('Kullanıcı profili alınırken hata oluştu: $e');
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
    } catch (e) {
      throw Exception('Kullanıcı profili güncellenirken hata oluştu: $e');
    }
  }

  // Kullanıcı konum işlemleri
  Future<void> saveUserLocation(UserLocationModel location) async {
    try {
      // Mevcut konumu kaydet
      await _firestore
          .collection('users')
          .doc(location.userId)
          .collection('locations')
          .doc(location.id)
          .set(location.toMap());
      
      // Önceki "isCurrentLocation" true olan konumları false yap
      final QuerySnapshot previousLocations = await _firestore
          .collection('users')
          .doc(location.userId)
          .collection('locations')
          .where('isCurrentLocation', isEqualTo: true)
          .where(FieldPath.documentId, isNotEqualTo: location.id)
          .get();
      
      for (var doc in previousLocations.docs) {
        await doc.reference.update({'isCurrentLocation': false});
      }
    } catch (e) {
      throw Exception('Kullanıcı konumu kaydedilirken hata oluştu: $e');
    }
  }

  Future<UserLocationModel?> getCurrentUserLocation(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('locations')
          .where('isCurrentLocation', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return UserLocationModel.fromMap(
          snapshot.docs.first.data() as Map<String, dynamic>,
          snapshot.docs.first.id,
        );
      }
      
      return null;
    } catch (e) {
      throw Exception('Kullanıcı konumu alınırken hata oluştu: $e');
    }
  }

  // Hava kalitesi veri işlemleri
  Future<void> saveAirQualityData(AirQualityModel airQuality) async {
    try {
      // Kullanıcının admin olup olmadığını kontrol et
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('Hava kalitesi verisi kaydedilemedi: Kullanıcı oturum açmamış');
        return;
      }
      
      // Kullanıcı profilini al
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      
      // Eğer kullanıcı admin değilse, verileri kaydetme
      if (!userDoc.exists || !(userDoc.data()?['isAdmin'] ?? false)) {
        print('Hava kalitesi verisi kaydedilemedi: Kullanıcı admin değil');
        return;
      }
      
      // Admin kullanıcı ise verileri kaydet
      await _firestore.collection('airQualityData').doc(airQuality.id).set(airQuality.toMap());
      print('Hava kalitesi verisi başarıyla kaydedildi');
    } catch (e) {
      print('Hava kalitesi verisi kaydedilirken hata oluştu: $e');
    }
  }

  Future<AirQualityModel?> getLatestAirQualityData(double latitude, double longitude, {double radius = 10.0}) async {
    try {
      // Belirli bir yarıçap içindeki en son hava kalitesi verilerini al
      // Not: Firestore'da gerçek coğrafi sorgular için GeoFirestore gibi ek kütüphaneler kullanılabilir
      final QuerySnapshot snapshot = await _firestore
          .collection('airQualityData')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      
      if (snapshot.docs.isEmpty) {
        return null;
      }
      
      // Manuel olarak mesafeyi hesapla ve en yakın istasyonu bul
      AirQualityModel? closest;
      double minDistance = double.infinity;
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final double stationLat = data['latitude'] ?? 0.0;
        final double stationLng = data['longitude'] ?? 0.0;
        
        // Basit mesafe hesaplama (daha doğru hesaplama için Haversine formülü kullanılabilir)
        final double distance = _calculateDistance(
          latitude, longitude, stationLat, stationLng);
        
        if (distance <= radius && distance < minDistance) {
          minDistance = distance;
          closest = AirQualityModel.fromMap(data, doc.id);
        }
      }
      
      return closest;
    } catch (e) {
      throw Exception('Hava kalitesi verisi alınırken hata oluştu: $e');
    }
  }

  // Bildirim işlemleri
  Future<void> saveNotification(NotificationModel notification) async {
    try {
      await _firestore
          .collection('users')
          .doc(notification.userId)
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());
    } catch (e) {
      throw Exception('Bildirim kaydedilirken hata oluştu: $e');
    }
  }

  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Bildirim okundu olarak işaretlenirken hata oluştu: $e');
    }
  }

  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Bildirim silinirken hata oluştu: $e');
    }
  }

  // Kullanıcı ayarları işlemleri
  Future<UserSettingsModel?> getUserSettings(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('user_settings')
          .get();
      
      if (doc.exists) {
        return UserSettingsModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      
      // Ayarlar yoksa varsayılan ayarları oluştur
      final defaultSettings = UserSettingsModel.createDefaultSettings(userId);
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('user_settings')
          .set(defaultSettings.toMap());
      
      return defaultSettings;
    } catch (e) {
      throw Exception('Kullanıcı ayarları alınırken hata oluştu: $e');
    }
  }
  
  // Kullanıcı ayarlarını kaydetme
  Future<void> saveUserSettings(UserSettingsModel settings) async {
    try {
      await _firestore
          .collection('users')
          .doc(settings.userId)
          .collection('settings')
          .doc('user_settings')
          .set(settings.toMap());
    } catch (e) {
      throw Exception('Kullanıcı ayarları kaydedilirken hata oluştu: $e');
    }
  }

  Future<void> updateUserSettings(UserSettingsModel settings) async {
    try {
      await _firestore
          .collection('users')
          .doc(settings.userId)
          .collection('settings')
          .doc('user_settings')
          .update(settings.toMap());
    } catch (e) {
      throw Exception('Kullanıcı ayarları güncellenirken hata oluştu: $e');
    }
  }

  // Yardımcı metotlar
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Basit Öklid mesafesi (gerçek uygulamada Haversine formülü kullanılmalıdır)
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 - 
        0.5 * math.cos((lat2 - lat1) * p) - 
        0.5 * math.cos((lon2 - lon1) * p) * math.cos((lat1) * p) * math.cos((lat2) * p);
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }
} 