class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String type; // 'danger', 'warning', 'info'
  final Map<String, dynamic>? data; // Ek veriler

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    required this.type,
    this.data,
  });

  // Firestore'dan veri almak için factory constructor
  factory NotificationModel.fromMap(Map<String, dynamic> data, String id) {
    return NotificationModel(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      type: data['type'] ?? 'info',
      data: data['data'],
    );
  }

  // Firestore'a veri göndermek için Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'timestamp': timestamp,
      'isRead': isRead,
      'type': type,
      'data': data,
    };
  }

  // Bildirim okundu olarak işaretleme
  NotificationModel markAsRead() {
    return NotificationModel(
      id: this.id,
      userId: this.userId,
      title: this.title,
      body: this.body,
      timestamp: this.timestamp,
      isRead: true,
      type: this.type,
      data: this.data,
    );
  }

  // Tehlikeli hava kalitesi bildirimi oluşturma
  static NotificationModel createDangerousAirQualityNotification({
    required String userId,
    required String location,
    required double aqi,
    required String category,
  }) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: 'Tehlikeli Hava Kalitesi Uyarısı',
      body: '$location bölgesinde hava kalitesi $category seviyesinde (AQI: ${aqi.toStringAsFixed(0)}). Lütfen gerekli önlemleri alın.',
      timestamp: DateTime.now(),
      isRead: false,
      type: 'danger',
      data: {
        'location': location,
        'aqi': aqi,
        'category': category,
      },
    );
  }
} 