import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/air_quality_provider.dart';
import '../models/air_quality_model.dart';
import '../styles/app_styles.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/air_quality_gauge.dart';

class AirQualityDetailsScreen extends StatefulWidget {
  const AirQualityDetailsScreen({super.key});

  @override
  State<AirQualityDetailsScreen> createState() => _AirQualityDetailsScreenState();
}

class _AirQualityDetailsScreenState extends State<AirQualityDetailsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late ScrollController _scrollController;
  bool _showAppBarTitle = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    
    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          _showAppBarTitle = _scrollController.offset > 120;
        });
      });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final airQualityProvider = Provider.of<AirQualityProvider>(context);
    final airQuality = airQualityProvider.currentAirQuality;
    
    if (airQuality == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Hava Kalitesi Detayları'),
          backgroundColor: AppStyles.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Hava kalitesi verisi bulunamadı',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: AppStyles.primaryButtonStyle,
                child: const Text('Geri Dön'),
              ),
            ],
          ),
        ),
      );
    }
    
    final color = airQualityProvider.getAirQualityColor(airQuality.category);
    final gradient = AppStyles.airQualityGradient(airQuality.category);
    
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Özel App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: color,
            elevation: 0,
            title: AnimatedOpacity(
              opacity: _showAppBarTitle ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                airQuality.location,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient arka plan
                  Container(
                    decoration: BoxDecoration(gradient: gradient),
                  ),
                  
                  // Parçacık animasyonu
                  ParticleAnimation(
                    color: Colors.white,
                    particleCount: 30,
                    child: Container(),
                  ),
                  
                  // Konum ve zaman bilgisi
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.white),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  airQuality.location,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Güncelleme: ${_formatDateTime(airQuality.timestamp)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            'Veri Kaynağı: ${airQuality.source}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // İçerik
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AQI ve kategori
                  _buildSection(
                    title: 'Hava Kalitesi İndeksi (AQI)',
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Center(
                          child: BreathingAnimation(
                            minScale: 0.95,
                            maxScale: 1.05,
                            duration: const Duration(seconds: 4),
                            child: AirQualityGauge(
                              aqi: airQuality.aqi,
                              category: airQuality.category,
                              size: 220,
                              animate: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: gradient,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            airQuality.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          airQualityProvider.getAirQualityAdvice(airQuality.category),
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Konum detayları
                  _buildSection(
                    title: 'Konum Detayları',
                    icon: Icons.map,
                    iconColor: Colors.blue,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            icon: Icons.location_searching,
                            title: 'Enlem',
                            value: airQuality.latitude.toStringAsFixed(6),
                          ),
                          const Divider(),
                          _buildInfoRow(
                            icon: Icons.location_searching,
                            title: 'Boylam',
                            value: airQuality.longitude.toStringAsFixed(6),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Kirleticiler
                  _buildSection(
                    title: 'Kirleticiler',
                    icon: Icons.opacity,
                    iconColor: Colors.teal,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: _buildPollutantsTable(airQuality),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sağlık etkileri
                  _buildSection(
                    title: 'Sağlık Etkileri',
                    icon: Icons.favorite,
                    iconColor: Colors.red,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: _buildHealthEffects(airQuality.category),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Önlemler
                  _buildSection(
                    title: 'Alınabilecek Önlemler',
                    icon: Icons.shield,
                    iconColor: Colors.green,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: _buildPrecautions(airQuality.category),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Paylaş butonu
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Paylaşma fonksiyonu
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Hava kalitesi bilgisi paylaşılıyor...'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: AppStyles.primaryButtonStyle,
                      icon: const Icon(Icons.share),
                      label: const Text('Bu Bilgiyi Paylaş'),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Bölüm widget'ı
  Widget _buildSection({
    required String title,
    IconData? icon,
    Color? iconColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppStyles.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                if (icon != null)
                  Icon(icon, color: iconColor ?? Colors.grey, size: 24),
                if (icon != null)
                  const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // İçerik
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: child,
          ),
        ],
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
          const SizedBox(width: 8),
          Text(
            '$title:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // Kirleticiler tablosu
  Widget _buildPollutantsTable(AirQualityModel airQuality) {
    if (airQuality.pollutants.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Kirletici verisi bulunamadı',
            style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }
    
    return Column(
      children: [
        // Başlık satırı
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: const [
              Expanded(
                flex: 2,
                child: Text(
                  'Kirletici',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.left,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Değer',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Birim',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        
        // Kirletici satırları
        ...airQuality.pollutants.entries.map((entry) {
          final color = _getPollutantColor(entry.key, entry.value);
          
          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getPollutantName(entry.key),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    entry.value.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'µg/m³',
                    style: TextStyle(fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // Sağlık etkileri
  Widget _buildHealthEffects(String category) {
    String effects;
    IconData icon;
    Color color;
    
    switch (category) {
      case 'İyi':
        effects = 'Hava kalitesi tatmin edici ve hava kirliliği az riskli veya hiç risk oluşturmuyor.';
        icon = Icons.sentiment_very_satisfied;
        color = AppStyles.airQualityGood;
        break;
      case 'Orta':
        effects = 'Hava kalitesi kabul edilebilir; ancak bazı kirleticiler, hava kirliliğine karşı alışılmadık derecede hassas olan az sayıda insan için orta düzeyde sağlık endişesi oluşturabilir.';
        icon = Icons.sentiment_satisfied;
        color = AppStyles.airQualityModerate;
        break;
      case 'Hassas Gruplar İçin Sağlıksız':
        effects = 'Hassas gruplar (astım hastaları, yaşlılar, çocuklar, kalp ve akciğer hastaları) sağlık etkileri yaşayabilir. Genel nüfus etkilenme olasılığı daha düşüktür.';
        icon = Icons.sentiment_neutral;
        color = AppStyles.airQualitySensitive;
        break;
      case 'Sağlıksız':
        effects = 'Herkes sağlık etkileri yaşamaya başlayabilir. Hassas gruplar için daha ciddi sağlık etkileri görülebilir. Solunum ve kalp rahatsızlıkları, öksürük, göz ve boğaz tahrişi yaygın olabilir.';
        icon = Icons.sentiment_dissatisfied;
        color = AppStyles.airQualityUnhealthy;
        break;
      case 'Çok Sağlıksız':
        effects = 'Sağlık uyarısı: Herkes daha ciddi sağlık etkileri yaşayabilir. Kalp ve akciğer hastalıkları olanlar, yaşlılar ve çocuklar için önemli riskler oluşturur. Solunum güçlüğü, göğüs ağrısı ve astım atakları artabilir.';
        icon = Icons.sentiment_very_dissatisfied;
        color = AppStyles.airQualityVeryUnhealthy;
        break;
      case 'Tehlikeli':
        effects = 'Acil durum koşulları. Tüm nüfus etkilenebilir. Ciddi solunum ve kalp sorunları, erken ölüm riski. Uzun süreli maruz kalma, kronik hastalıkların gelişmesine veya mevcut hastalıkların kötüleşmesine neden olabilir.';
        icon = Icons.dangerous;
        color = AppStyles.airQualityHazardous;
        break;
      default:
        effects = 'Bilinmeyen hava kalitesi kategorisi.';
        icon = Icons.help_outline;
        color = Colors.grey;
    }
    
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          effects,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
      ],
    );
  }

  // Önlemler
  Widget _buildPrecautions(String category) {
    List<String> precautions;
    
    switch (category) {
      case 'İyi':
        precautions = [
          'Normal aktivitelerinize devam edebilirsiniz.',
          'Açık havada egzersiz yapmak için ideal bir gün.',
        ];
        break;
      case 'Orta':
        precautions = [
          'Hassas kişiler uzun süreli veya ağır dış mekan aktivitelerini azaltmayı düşünebilir.',
          'Pencerelerinizi açık tutabilirsiniz.',
        ];
        break;
      case 'Hassas Gruplar İçin Sağlıksız':
        precautions = [
          'Hassas gruplar (astım hastaları, yaşlılar, çocuklar) uzun süreli dış mekan aktivitelerini sınırlamalıdır.',
          'Herkes ağır dış mekan aktivitelerini azaltmalıdır.',
          'Mümkünse iç mekanlarda kalın ve pencerelerinizi kapalı tutun.',
        ];
        break;
      case 'Sağlıksız':
        precautions = [
          'Herkes dış mekan aktivitelerini sınırlamalıdır.',
          'Hassas gruplar tüm dış mekan aktivitelerinden kaçınmalıdır.',
          'İç mekanlarda kalın ve pencerelerinizi kapalı tutun.',
          'Hava temizleyici kullanmayı düşünün.',
          'Maske (N95 veya FFP2) kullanın.',
        ];
        break;
      case 'Çok Sağlıksız':
        precautions = [
          'Herkes tüm dış mekan aktivitelerini sınırlamalıdır.',
          'Mümkün olduğunca iç mekanlarda kalın.',
          'Pencerelerinizi ve kapılarınızı sıkıca kapalı tutun.',
          'Hava temizleyici kullanın.',
          'Dışarı çıkmanız gerekiyorsa, N95 veya FFP2 maske kullanın.',
          'Bol su için ve gözlerinizi sık sık yıkayın.',
        ];
        break;
      case 'Tehlikeli':
        precautions = [
          'Herkes dış mekan aktivitelerinden kaçınmalıdır.',
          'İç mekanlarda kalın ve fiziksel aktiviteyi azaltın.',
          'Tüm pencereler, kapılar ve hava girişlerini kapatın.',
          'Hava temizleyici kullanın ve filtrelerin temiz olduğundan emin olun.',
          'Dışarı çıkmanız mutlaka gerekiyorsa, N95 veya FFP2 maske kullanın.',
          'Acil tıbbi yardım gerektiren belirtiler için dikkatli olun (nefes darlığı, göğüs ağrısı).',
        ];
        break;
      default:
        precautions = ['Bilinmeyen hava kalitesi kategorisi için önlem bilgisi yok.'];
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: precautions.map((precaution) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: _getCategoryColor(category),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  precaution,
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Kirletici adı
  String _getPollutantName(String code) {
    switch (code.toLowerCase()) {
      case 'pm25':
        return 'PM2.5 (İnce Partikül Madde)';
      case 'pm10':
        return 'PM10 (Kaba Partikül Madde)';
      case 'o3':
        return 'O₃ (Ozon)';
      case 'no2':
        return 'NO₂ (Azot Dioksit)';
      case 'so2':
        return 'SO₂ (Kükürt Dioksit)';
      case 'co':
        return 'CO (Karbon Monoksit)';
      default:
        return code.toUpperCase();
    }
  }
  
  // Kirletici rengi
  Color _getPollutantColor(String code, double value) {
    // Basit bir renk skalası
    switch (code.toLowerCase()) {
      case 'pm25':
        if (value <= 12) return Colors.green;
        if (value <= 35.4) return Colors.yellow;
        if (value <= 55.4) return Colors.orange;
        if (value <= 150.4) return Colors.red;
        if (value <= 250.4) return Colors.purple;
        return Colors.brown;
      case 'pm10':
        if (value <= 54) return Colors.green;
        if (value <= 154) return Colors.yellow;
        if (value <= 254) return Colors.orange;
        if (value <= 354) return Colors.red;
        if (value <= 424) return Colors.purple;
        return Colors.brown;
      case 'o3':
        if (value <= 54) return Colors.green;
        if (value <= 124) return Colors.yellow;
        if (value <= 164) return Colors.orange;
        if (value <= 204) return Colors.red;
        if (value <= 404) return Colors.purple;
        return Colors.brown;
      case 'no2':
        if (value <= 53) return Colors.green;
        if (value <= 100) return Colors.yellow;
        if (value <= 360) return Colors.orange;
        if (value <= 649) return Colors.red;
        if (value <= 1249) return Colors.purple;
        return Colors.brown;
      case 'so2':
        if (value <= 35) return Colors.green;
        if (value <= 75) return Colors.yellow;
        if (value <= 185) return Colors.orange;
        if (value <= 304) return Colors.red;
        if (value <= 604) return Colors.purple;
        return Colors.brown;
      case 'co':
        if (value <= 4.4) return Colors.green;
        if (value <= 9.4) return Colors.yellow;
        if (value <= 12.4) return Colors.orange;
        if (value <= 15.4) return Colors.red;
        if (value <= 30.4) return Colors.purple;
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  // Kategori rengi
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'İyi':
        return AppStyles.airQualityGood;
      case 'Orta':
        return AppStyles.airQualityModerate;
      case 'Hassas Gruplar İçin Sağlıksız':
        return AppStyles.airQualitySensitive;
      case 'Sağlıksız':
        return AppStyles.airQualityUnhealthy;
      case 'Çok Sağlıksız':
        return AppStyles.airQualityVeryUnhealthy;
      case 'Tehlikeli':
        return AppStyles.airQualityHazardous;
      default:
        return Colors.grey;
    }
  }

  // Tarih formatı
  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$day/$month/$year $hour:$minute';
  }
} 