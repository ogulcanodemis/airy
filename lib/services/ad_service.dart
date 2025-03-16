import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // Singleton pattern
  static final AdService _instance = AdService._internal();
  
  factory AdService() {
    return _instance;
  }
  
  AdService._internal();

  // Test banner ID'leri
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  
  // Gerçek banner ID'leri
  static const String _productionBannerAdUnitId = 'ca-app-pub-7415798111030820/4742364241';
  
  // Debug modda test ID'leri, release modda gerçek ID'leri kullan
  String get bannerAdUnitId {
    bool isRelease = const bool.fromEnvironment('dart.vm.product');
    return isRelease ? _productionBannerAdUnitId : _testBannerAdUnitId;
  }
  
  // AdMob'u başlat
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    print('AdMob başlatıldı');
    
    // Reklam durumunu takip et
    MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
        testDeviceIds: ['TEST_DEVICE_ID'], // Test cihazı ID'si
      ),
    );
  }
  
  // Banner reklam yükle
  BannerAd createBannerAd({
    required AdSize size,
    required Function(Ad) onAdLoaded,
    required Function(LoadAdError) onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onAdFailedToLoad(error);
          print('Banner reklam yüklenemedi: $error');
        },
        onAdOpened: (ad) => print('Banner reklam açıldı'),
        onAdClosed: (ad) => print('Banner reklam kapatıldı'),
        onAdImpression: (ad) => print('Banner reklam gösterildi'),
      ),
    );
  }
  
  // Reklam durumunu kontrol et (premium kullanıcılar için reklamları gizle)
  bool shouldShowAds(bool isPremium) {
    return !isPremium;
  }
}

// Banner reklam widget'ı
class BannerAdWidget extends StatefulWidget {
  final AdSize adSize;
  final bool isPremium;
  
  const BannerAdWidget({
    Key? key,
    this.adSize = AdSize.banner,
    this.isPremium = false,
  }) : super(key: key);

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  final AdService _adService = AdService();
  int _loadAttempts = 0;
  static const int _maxFailedLoadAttempts = 3;

  @override
  void initState() {
    super.initState();
    if (!widget.isPremium) {
      _loadBannerAd();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    _bannerAd = _adService.createBannerAd(
      size: widget.adSize,
      onAdLoaded: (ad) {
        setState(() {
          _isAdLoaded = true;
          _loadAttempts = 0; // Başarılı yüklemede deneme sayısını sıfırla
        });
        print('Banner reklam yüklendi');
      },
      onAdFailedToLoad: (error) {
        _loadAttempts++;
        _bannerAd = null;
        
        setState(() {
          _isAdLoaded = false;
        });
        
        print('Banner reklam yüklenemedi: $error, Deneme: $_loadAttempts');
        
        // Maksimum deneme sayısına ulaşılmadıysa tekrar dene
        if (_loadAttempts < _maxFailedLoadAttempts) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              _loadBannerAd();
            }
          });
        }
      },
    );
    
    _bannerAd?.load();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPremium) {
      return const SizedBox.shrink(); // Premium kullanıcılar için boş widget
    }
    
    if (_bannerAd == null || !_isAdLoaded) {
      return Container(
        width: widget.adSize.width.toDouble(),
        height: widget.adSize.height.toDouble(),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: _loadAttempts >= _maxFailedLoadAttempts
              ? const Text(
                  'Reklam yüklenemedi',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Reklam yükleniyor...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
        ),
      );
    }

    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: AdWidget(ad: _bannerAd!),
    );
  }
} 