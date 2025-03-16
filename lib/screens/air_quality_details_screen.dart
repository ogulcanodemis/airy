import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/air_quality_provider.dart';
import '../models/air_quality_model.dart';
import '../styles/app_styles.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/air_quality_gauge.dart';

class AirQualityDetailsScreen extends StatefulWidget {
  final AirQualityModel? airQuality;

  const AirQualityDetailsScreen({
    Key? key,
    this.airQuality,
  }) : super(key: key);

  @override
  State<AirQualityDetailsScreen> createState() => _AirQualityDetailsScreenState();
}

class _AirQualityDetailsScreenState extends State<AirQualityDetailsScreen> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  bool _showAppBarTitle = false;
  AirQualityModel? airQuality;
  late AirQualityProvider airQualityProvider;

  @override
  void initState() {
    super.initState();
    airQuality = widget.airQuality;
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    airQualityProvider = Provider.of<AirQualityProvider>(context);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 140 && !_showAppBarTitle) {
      setState(() {
        _showAppBarTitle = true;
      });
    } else if (_scrollController.offset <= 140 && _showAppBarTitle) {
      setState(() {
        _showAppBarTitle = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // Beyaz arka plan
      body: AnimatedBackground(
        color1: const Color(0xFF82E0F9), // Açık mavi
        color2: const Color(0xFFF9CC3E), // Sarı
        bubbleCount: 8,
        child: SafeArea(
          child: Column(
            children: [
              // Üst kısım - Başlık, geri butonu ve paylaş butonu
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Geri butonu
                    Container(
                      decoration: BoxDecoration(
                        color: AppStyles.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppStyles.primaryColor,
                          size: 26,
                        ),
                        tooltip: 'Geri',
                        padding: const EdgeInsets.all(10.0),
                        constraints: const BoxConstraints(
                          minWidth: 46,
                          minHeight: 46,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    
                    // Başlık
                    const Text(
                      'Hava Kalitesi Detayları',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppStyles.primaryColor,
                      ),
                    ),
                    
                    // Paylaş butonu
                    Container(
                      decoration: BoxDecoration(
                        color: AppStyles.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.share,
                          color: AppStyles.primaryColor,
                          size: 26,
                        ),
                        tooltip: 'Paylaş',
                        padding: const EdgeInsets.all(10.0),
                        constraints: const BoxConstraints(
                          minWidth: 46,
                          minHeight: 46,
                        ),
                        onPressed: () => _shareAirQualityData(context),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Ana içerik
              Expanded(
                child: airQualityProvider.hasAirQualityData
                    ? _buildContent(context, airQualityProvider.currentAirQuality!)
                    : const Center(
                        child: Text(
                          'Hava kalitesi verisi bulunamadı',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Bölüm widget'ı
  Widget _buildSection({
    required String title,
    IconData? icon,
    Color? iconColor,
    required Widget child,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if (icon != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (iconColor ?? Colors.grey).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor ?? Colors.grey, size: 24),
                  ),
                if (icon != null)
                  const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
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
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }
  
  // Bilgi satırı
  Widget _buildInfoRow({
    required String label,
    required String value,
    IconData? icon,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (icon != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.blue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor ?? Colors.blue, size: 20),
            ),
          if (icon != null)
            const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
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
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(12),
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
              border: Border.all(color: const Color(0xFFEEEEEE)),
              borderRadius: BorderRadius.circular(12),
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
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
        ),
        const SizedBox(height: 16),
        Text(
          effects,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
      ],
    );
  }

  // Öneriler
  Widget _buildRecommendations(String category) {
    List<String> recommendations;
    Color color = _getCategoryColor(category);
    
    switch (category) {
      case 'İyi':
        recommendations = [
          'Normal aktivitelerinize devam edebilirsiniz.',
          'Açık havada egzersiz yapmak için ideal bir gün.',
        ];
        break;
      case 'Orta':
        recommendations = [
          'Hassas kişiler uzun süreli veya ağır dış mekan aktivitelerini azaltmayı düşünebilir.',
          'Pencerelerinizi açık tutabilirsiniz.',
        ];
        break;
      case 'Hassas Gruplar İçin Sağlıksız':
        recommendations = [
          'Hassas gruplar (astım hastaları, yaşlılar, çocuklar) uzun süreli dış mekan aktivitelerini sınırlamalıdır.',
          'Herkes ağır dış mekan aktivitelerini azaltmalıdır.',
          'Mümkünse iç mekanlarda kalın ve pencerelerinizi kapalı tutun.',
        ];
        break;
      case 'Sağlıksız':
        recommendations = [
          'Herkes dış mekan aktivitelerini sınırlamalıdır.',
          'Hassas gruplar tüm dış mekan aktivitelerinden kaçınmalıdır.',
          'İç mekanlarda kalın ve pencerelerinizi kapalı tutun.',
          'Hava temizleyici kullanmayı düşünün.',
          'Maske (N95 veya FFP2) kullanın.',
        ];
        break;
      case 'Çok Sağlıksız':
        recommendations = [
          'Herkes tüm dış mekan aktivitelerini sınırlamalıdır.',
          'Mümkün olduğunca iç mekanlarda kalın.',
          'Pencerelerinizi ve kapılarınızı sıkıca kapalı tutun.',
          'Hava temizleyici kullanın.',
          'Dışarı çıkmanız gerekiyorsa, N95 veya FFP2 maske kullanın.',
          'Bol su için ve gözlerinizi sık sık yıkayın.',
        ];
        break;
      case 'Tehlikeli':
        recommendations = [
          'Herkes dış mekan aktivitelerinden kaçınmalıdır.',
          'İç mekanlarda kalın ve fiziksel aktiviteyi azaltın.',
          'Tüm pencereler, kapılar ve hava girişlerini kapatın.',
          'Hava temizleyici kullanın ve filtrelerin temiz olduğundan emin olun.',
          'Dışarı çıkmanız mutlaka gerekiyorsa, N95 veya FFP2 maske kullanın.',
          'Acil tıbbi yardım gerektiren belirtiler için dikkatli olun (nefes darlığı, göğüs ağrısı).',
        ];
        break;
      default:
        recommendations = ['Bilinmeyen hava kalitesi kategorisi için önlem bilgisi yok.'];
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: recommendations.map((recommendation) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  recommendation,
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

  Widget _buildContent(BuildContext context, AirQualityModel airQuality) {
    final color = airQualityProvider.getAirQualityColor(airQuality.category);
    final gradient = AppStyles.airQualityGradient(airQuality.category);
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hava kalitesi göstergesi
          Center(
            child: Column(
              children: [
                AirQualityGauge(
                  aqi: airQuality.aqi,
                  category: airQuality.category,
                  size: 220,
                  animate: true,
                ),
                const SizedBox(height: 16),
                Text(
                  airQuality.location,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppStyles.textPrimaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Son Güncelleme: ${_formatDateTime(airQuality.timestamp)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppStyles.textSecondaryColor,
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
                      shadows: [
                        Shadow(
                          blurRadius: 4.0,
                          color: Colors.black45,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  airQualityProvider.getAirQualityAdvice(airQuality.category),
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppStyles.textPrimaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Kirleticiler bölümü
          _buildSection(
            title: 'Kirleticiler',
            icon: Icons.science,
            iconColor: const Color(0xFF82E0F9),
            child: _buildPollutantsTable(airQuality),
          ),
          
          const SizedBox(height: 16),
          
          // Sağlık etkileri bölümü
          _buildSection(
            title: 'Sağlık Etkileri',
            icon: Icons.health_and_safety,
            iconColor: const Color(0xFFF9CC3E),
            child: _buildHealthEffects(airQuality.category),
          ),
          
          const SizedBox(height: 16),
          
          // Öneriler bölümü
          _buildSection(
            title: 'Öneriler',
            icon: Icons.tips_and_updates,
            iconColor: Colors.green,
            child: _buildRecommendations(airQuality.category),
          ),
          
          const SizedBox(height: 16),
          
          // Kaynak bilgisi
          _buildSection(
            title: 'Veri Kaynağı',
            icon: Icons.info,
            iconColor: Colors.purple,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  label: 'Kaynak',
                  value: airQuality.source,
                  icon: Icons.cloud,
                  iconColor: const Color(0xFF82E0F9),
                ),
                _buildInfoRow(
                  label: 'Ölçüm Zamanı',
                  value: _formatDateTime(airQuality.timestamp),
                  icon: Icons.access_time,
                  iconColor: Colors.green,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _shareAirQualityData(BuildContext context) {
    // Mevcut hava kalitesi verisini al
    final airQuality = airQualityProvider.currentAirQuality;
    
    if (airQuality == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paylaşılacak hava kalitesi verisi bulunamadı'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    // Paylaşılacak metni oluştur
    final shareText = '''
📊 Hava Kalitesi Bilgisi 📊

📍 Konum: ${airQuality.location}
🔢 AQI: ${airQuality.aqi.toStringAsFixed(0)}
📋 Kategori: ${airQuality.category}
⏱️ Son Güncelleme: ${_formatDateTime(airQuality.timestamp)}

${airQualityProvider.getAirQualityAdvice(airQuality.category)}

${_getPollutantsText(airQuality)}

Airy uygulaması ile paylaşıldı.
''';
    
    // Paylaşma işlemini başlat
    Share.share(
      shareText,
      subject: '${airQuality.location} Hava Kalitesi Bilgisi',
    ).then((_) {
      // Paylaşma işlemi tamamlandığında
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hava kalitesi bilgisi paylaşıldı'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }).catchError((error) {
      // Hata durumunda
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paylaşma işlemi başarısız: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }
  
  // Kirleticileri metin formatında döndürür
  String _getPollutantsText(AirQualityModel airQuality) {
    if (airQuality.pollutants.isEmpty) {
      return '';
    }
    
    final buffer = StringBuffer('🧪 Kirleticiler:\n');
    
    airQuality.pollutants.forEach((key, value) {
      buffer.write('${_getPollutantName(key)}: ${value.toStringAsFixed(1)} µg/m³\n');
    });
    
    return buffer.toString();
  }
} 