class AirQualityModel {
  final String id;
  final double latitude;
  final double longitude;
  final String location;
  final DateTime timestamp;
  final double aqi; // Hava Kalitesi İndeksi
  final Map<String, double> pollutants; // PM2.5, PM10, O3, NO2, SO2, CO
  final String category; // İyi, Orta, Kötü, Çok Kötü, Tehlikeli
  final String source; // Veri kaynağı (OpenAQ, WAQI, Google)
  final Map<String, dynamic>? additionalData; // Ek veriler (sağlık tavsiyeleri vb.)

  AirQualityModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.location,
    required this.timestamp,
    required this.aqi,
    required this.pollutants,
    required this.category,
    required this.source,
    this.additionalData,
  });

  // Firestore'dan veri almak için factory constructor
  factory AirQualityModel.fromMap(Map<String, dynamic> data, String id) {
    return AirQualityModel(
      id: id,
      latitude: data['latitude'] ?? 0.0,
      longitude: data['longitude'] ?? 0.0,
      location: data['location'] ?? '',
      timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
      aqi: data['aqi'] ?? 0.0,
      pollutants: Map<String, double>.from(data['pollutants'] ?? {}),
      category: data['category'] ?? 'Bilinmiyor',
      source: data['source'] ?? 'OpenAQ',
      additionalData: data['additionalData'],
    );
  }

  // OpenAQ API'den gelen verileri işlemek için factory constructor
  factory AirQualityModel.fromOpenAQ(Map<String, dynamic> data) {
    print('AirQualityModel.fromOpenAQ çağrıldı: $data');
    
    // OpenAQ API'den gelen verileri işleme
    final Map<String, double> pollutants = {};
    final List<dynamic> parameters = data['parameters'] ?? [];
    
    print('Parameters: $parameters');
    
    for (var param in parameters) {
      final String paramName = param['parameter'] ?? '';
      final dynamic rawValue = param['value'];
      double value = 0.0;
      
      // Değeri double'a dönüştür
      if (rawValue != null) {
        if (rawValue is double) {
          value = rawValue;
        } else if (rawValue is int) {
          value = rawValue.toDouble();
        } else {
          try {
            value = double.parse(rawValue.toString());
          } catch (e) {
            print('Değer dönüştürme hatası: $e, değer: $rawValue');
            value = 0.0;
          }
        }
      }
      
      pollutants[paramName] = value;
      print('Pollutant eklendi: $paramName = $value');
    }
    
    // AQI hesaplama (basit bir örnek)
    double aqi = 0.0;
    
    // Eğer veri içinde doğrudan AQI değeri varsa onu kullan
    if (data.containsKey('aqi') && data['aqi'] != null) {
      final dynamic rawAqi = data['aqi'];
      print('Ham AQI değeri: $rawAqi (${rawAqi.runtimeType})');
      
      if (rawAqi is double) {
        aqi = rawAqi;
      } else if (rawAqi is int) {
        aqi = rawAqi.toDouble();
      } else {
        try {
          aqi = double.parse(rawAqi.toString());
        } catch (e) {
          print('AQI dönüştürme hatası: $e, değer: $rawAqi');
          // Dönüştürme başarısız olursa, pollutant değerlerinden hesapla
          if (pollutants.containsKey('pm25')) {
            aqi = pollutants['pm25']! * 4.0; // Basit bir hesaplama
            print('AQI PM2.5\'ten hesaplandı: ${pollutants['pm25']} * 4.0 = $aqi');
          } else if (pollutants.containsKey('pm10')) {
            aqi = pollutants['pm10']! * 2.0; // Basit bir hesaplama
            print('AQI PM10\'dan hesaplandı: ${pollutants['pm10']} * 2.0 = $aqi');
          }
        }
      }
    } else {
      print('AQI değeri bulunamadı, pollutant değerlerinden hesaplanıyor...');
      // AQI değeri yoksa pollutant değerlerinden hesapla
      if (pollutants.containsKey('pm25')) {
        aqi = pollutants['pm25']! * 4.0; // Basit bir hesaplama
        print('AQI PM2.5\'ten hesaplandı: ${pollutants['pm25']} * 4.0 = $aqi');
      } else if (pollutants.containsKey('pm10')) {
        aqi = pollutants['pm10']! * 2.0; // Basit bir hesaplama
        print('AQI PM10\'dan hesaplandı: ${pollutants['pm10']} * 2.0 = $aqi');
      }
    }
    
    // AQI kategorisi belirleme
    String category = 'Bilinmiyor';
    if (aqi <= 50) {
      category = 'İyi';
    } else if (aqi <= 100) {
      category = 'Orta';
    } else if (aqi <= 150) {
      category = 'Hassas Gruplar İçin Sağlıksız';
    } else if (aqi <= 200) {
      category = 'Sağlıksız';
    } else if (aqi <= 300) {
      category = 'Çok Sağlıksız';
    } else {
      category = 'Tehlikeli';
    }
    
    print('Hesaplanan AQI: $aqi, Kategori: $category');
    
    return AirQualityModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      latitude: data['coordinates']?['latitude'] ?? 0.0,
      longitude: data['coordinates']?['longitude'] ?? 0.0,
      location: data['location'] ?? '',
      timestamp: DateTime.now(),
      aqi: aqi,
      pollutants: pollutants,
      category: category,
      source: 'OpenAQ',
      additionalData: null,
    );
  }

  // Firestore'a veri göndermek için Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
      'timestamp': timestamp,
      'aqi': aqi,
      'pollutants': pollutants,
      'category': category,
      'source': source,
      'additionalData': additionalData,
    };
  }
  
  // Tehlikeli seviyede olup olmadığını kontrol etme
  bool isDangerous() {
    return aqi > 150; // AQI 150'den büyükse tehlikeli kabul ediyoruz
  }
  
  // Belirli bir kirleticinin değerini alma
  double getPollutantValue(String pollutantCode) {
    return pollutants[pollutantCode.toLowerCase()] ?? 0.0;
  }
  
  // Sağlık tavsiyelerini alma
  List<String> getHealthRecommendations() {
    if (additionalData != null && 
        additionalData!.containsKey('healthRecommendations') && 
        additionalData!['healthRecommendations'] is List) {
      return List<String>.from(additionalData!['healthRecommendations']);
    }
    return [];
  }
  
  // Kaynağa göre karşılaştırma
  static AirQualityModel? getBestSource(List<AirQualityModel?> models) {
    // Null olmayan modelleri filtrele
    final validModels = models.where((m) => m != null).cast<AirQualityModel>().toList();
    
    if (validModels.isEmpty) return null;
    if (validModels.length == 1) return validModels.first;
    
    // Öncelik sırası: Google > WAQI > OpenAQ
    for (final source in ['Google', 'WAQI', 'OpenAQ']) {
      final sourceModel = validModels.firstWhere(
        (m) => m.source == source,
        orElse: () => validModels.first,
      );
      if (sourceModel != null) return sourceModel;
    }
    
    return validModels.first;
  }
  
  // Farklı kaynaklardan gelen verileri birleştirme
  static AirQualityModel mergeFromSources(Map<String, AirQualityModel?> sourceModels) {
    // Null olmayan modelleri filtrele
    final validModels = sourceModels.values.where((m) => m != null).cast<AirQualityModel>().toList();
    
    if (validModels.isEmpty) {
      throw Exception('Birleştirilecek geçerli model bulunamadı');
    }
    
    // Birincil model olarak Google'ı kullan, yoksa WAQI, yoksa OpenAQ
    AirQualityModel primaryModel;
    if (sourceModels['Google'] != null) {
      primaryModel = sourceModels['Google']!;
    } else if (sourceModels['WAQI'] != null) {
      primaryModel = sourceModels['WAQI']!;
    } else {
      primaryModel = validModels.first;
    }
    
    // Tüm kirleticileri birleştir
    final Map<String, double> mergedPollutants = {};
    for (final model in validModels) {
      mergedPollutants.addAll(model.pollutants);
    }
    
    // Ek verileri birleştir
    final Map<String, dynamic> mergedAdditionalData = {};
    for (final model in validModels) {
      if (model.additionalData != null) {
        mergedAdditionalData.addAll(model.additionalData!);
      }
    }
    
    // Kaynak bilgisini birleştir
    final List<String> sources = validModels.map((m) => m.source).toList();
    final String mergedSource = sources.join(', ');
    
    return AirQualityModel(
      id: primaryModel.id,
      latitude: primaryModel.latitude,
      longitude: primaryModel.longitude,
      location: primaryModel.location,
      timestamp: primaryModel.timestamp,
      aqi: primaryModel.aqi,
      pollutants: mergedPollutants,
      category: primaryModel.category,
      source: mergedSource,
      additionalData: mergedAdditionalData.isEmpty ? null : mergedAdditionalData,
    );
  }
} 