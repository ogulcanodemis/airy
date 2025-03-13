class UserLocationModel {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime timestamp;
  final bool isCurrentLocation;

  UserLocationModel({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.timestamp,
    this.isCurrentLocation = true,
  });

  // Firestore'dan veri almak için factory constructor
  factory UserLocationModel.fromMap(Map<String, dynamic> data, String id) {
    return UserLocationModel(
      id: id,
      userId: data['userId'] ?? '',
      latitude: data['latitude'] ?? 0.0,
      longitude: data['longitude'] ?? 0.0,
      address: data['address'] ?? '',
      timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
      isCurrentLocation: data['isCurrentLocation'] ?? false,
    );
  }

  // Firestore'a veri göndermek için Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': timestamp,
      'isCurrentLocation': isCurrentLocation,
    };
  }
} 