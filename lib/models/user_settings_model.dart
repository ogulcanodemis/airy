class UserSettingsModel {
  final String id;
  final String userId;
  final bool notificationsEnabled;
  final bool backgroundLocationEnabled;
  final int notificationThreshold; // AQI eşik değeri
  final int locationUpdateInterval; // Dakika cinsinden
  final List<String> favoriteLocations;
  final String temperatureUnit; // 'celsius' veya 'fahrenheit'
  final String language; // 'tr', 'en', vb.
  final Map<String, bool> enabledApiSources; // Etkinleştirilmiş API kaynakları
  final String preferredApiSource; // Tercih edilen API kaynağı
  final bool mergeApiResults; // API sonuçlarını birleştirme

  UserSettingsModel({
    required this.id,
    required this.userId,
    this.notificationsEnabled = true,
    this.backgroundLocationEnabled = true,
    this.notificationThreshold = 100, // Varsayılan olarak AQI 100'ü geçince bildirim
    this.locationUpdateInterval = 15, // Varsayılan olarak 15 dakikada bir konum güncellemesi
    this.favoriteLocations = const [],
    this.temperatureUnit = 'celsius',
    this.language = 'tr',
    this.enabledApiSources = const {
      'WAQI': true,
      'OpenAQ': false,
      'Google': false,
    },
    this.preferredApiSource = 'WAQI', // Varsayılan olarak WAQI API'si
    this.mergeApiResults = false, // Varsayılan olarak birleştirme kapalı
  });

  // Firestore'dan veri almak için factory constructor
  factory UserSettingsModel.fromMap(Map<String, dynamic> data, String id) {
    return UserSettingsModel(
      id: id,
      userId: data['userId'] ?? '',
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      backgroundLocationEnabled: data['backgroundLocationEnabled'] ?? true,
      notificationThreshold: data['notificationThreshold'] ?? 100,
      locationUpdateInterval: data['locationUpdateInterval'] ?? 15,
      favoriteLocations: List<String>.from(data['favoriteLocations'] ?? []),
      temperatureUnit: data['temperatureUnit'] ?? 'celsius',
      language: data['language'] ?? 'tr',
      enabledApiSources: Map<String, bool>.from(data['enabledApiSources'] ?? {
        'WAQI': true,
        'OpenAQ': false,
        'Google': false,
      }),
      preferredApiSource: data['preferredApiSource'] ?? 'WAQI',
      mergeApiResults: data['mergeApiResults'] ?? false,
    );
  }

  // Firestore'a veri göndermek için Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'notificationsEnabled': notificationsEnabled,
      'backgroundLocationEnabled': backgroundLocationEnabled,
      'notificationThreshold': notificationThreshold,
      'locationUpdateInterval': locationUpdateInterval,
      'favoriteLocations': favoriteLocations,
      'temperatureUnit': temperatureUnit,
      'language': language,
      'enabledApiSources': enabledApiSources,
      'preferredApiSource': preferredApiSource,
      'mergeApiResults': mergeApiResults,
    };
  }

  // Ayarları güncellemek için kopyalama metodu
  UserSettingsModel copyWith({
    bool? notificationsEnabled,
    bool? backgroundLocationEnabled,
    int? notificationThreshold,
    int? locationUpdateInterval,
    List<String>? favoriteLocations,
    String? temperatureUnit,
    String? language,
    Map<String, bool>? enabledApiSources,
    String? preferredApiSource,
    bool? mergeApiResults,
  }) {
    return UserSettingsModel(
      id: this.id,
      userId: this.userId,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      backgroundLocationEnabled: backgroundLocationEnabled ?? this.backgroundLocationEnabled,
      notificationThreshold: notificationThreshold ?? this.notificationThreshold,
      locationUpdateInterval: locationUpdateInterval ?? this.locationUpdateInterval,
      favoriteLocations: favoriteLocations ?? this.favoriteLocations,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      language: language ?? this.language,
      enabledApiSources: enabledApiSources ?? this.enabledApiSources,
      preferredApiSource: preferredApiSource ?? this.preferredApiSource,
      mergeApiResults: mergeApiResults ?? this.mergeApiResults,
    );
  }

  // Yeni kullanıcı için varsayılan ayarlar oluşturma
  static UserSettingsModel createDefaultSettings(String userId) {
    return UserSettingsModel(
      id: 'settings_$userId',
      userId: userId,
      notificationsEnabled: true,
      backgroundLocationEnabled: true,
      notificationThreshold: 100,
      locationUpdateInterval: 15,
      favoriteLocations: [],
      temperatureUnit: 'celsius',
      language: 'tr',
      enabledApiSources: {
        'WAQI': true,
        'OpenAQ': false,
        'Google': false,
      },
      preferredApiSource: 'WAQI',
      mergeApiResults: false,
    );
  }
  
  // Belirli bir API kaynağının etkin olup olmadığını kontrol etme
  bool isApiSourceEnabled(String source) {
    return enabledApiSources[source] ?? false;
  }
  
  // Etkin API kaynaklarının listesini alma
  List<String> getEnabledApiSources() {
    return enabledApiSources.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }
} 