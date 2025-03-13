class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.isAdmin = false,
    required this.createdAt,
    required this.lastLoginAt,
  });

  // Firestore'dan veri almak için factory constructor
  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      lastLoginAt: data['lastLoginAt']?.toDate() ?? DateTime.now(),
    );
  }

  // Firestore'a veri göndermek için Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'isAdmin': isAdmin,
      'createdAt': createdAt,
      'lastLoginAt': lastLoginAt,
    };
  }

  // Kullanıcı bilgilerini güncellemek için kopyalama metodu
  UserModel copyWith({
    String? displayName,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: this.uid,
      email: this.email,
      displayName: displayName ?? this.displayName,
      isAdmin: this.isAdmin,
      createdAt: this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
} 