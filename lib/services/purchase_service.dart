import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/user_settings_model.dart';

class PurchaseService {
  // Singleton pattern
  static final PurchaseService _instance = PurchaseService._internal();
  
  factory PurchaseService() {
    return _instance;
  }
  
  PurchaseService._internal();

  // Ürün ID'leri
  static const String _removeAdsProductId = 'airy_remove_ads';
  
  // Ürün listesi
  final Set<String> _productIds = {_removeAdsProductId};
  
  // In-App Purchase instance
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  
  // Stream abonelikleri
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // Ürün detayları
  List<ProductDetails> _products = [];
  
  // Yükleme durumu
  bool _isLoading = false;
  
  // Getters
  bool get isLoading => _isLoading;
  List<ProductDetails> get products => _products;
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;
  
  // Satın alma servisini başlatma
  Future<void> initialize() async {
    final bool available = await _inAppPurchase.isAvailable();
    _isAvailable = available;
    if (!available) {
      print('Satın alma servisi kullanılamıyor');
      return;
    }
    
    // Önceki satın almaları geri yükleme
    await _inAppPurchase.restorePurchases();
    
    // Satın alma stream'ini dinleme
    _subscription = _inAppPurchase.purchaseStream.listen(
      _listenToPurchaseUpdated,
      onDone: () {
        _subscription?.cancel();
      },
      onError: (error) {
        print('Satın alma hatası: $error');
      },
    );
    
    // Ürünleri yükleme
    await loadProducts();
  }
  
  // Ürünleri yükleme
  Future<void> loadProducts() async {
    _isLoading = true;
    
    final ProductDetailsResponse response = 
        await _inAppPurchase.queryProductDetails(_productIds);
    
    if (response.notFoundIDs.isNotEmpty) {
      print('Bulunamayan ürün ID\'leri: ${response.notFoundIDs}');
    }
    
    _products = response.productDetails;
    _isLoading = false;
    
    print('Yüklenen ürünler: ${_products.length}');
    _products.forEach((product) {
      print('Ürün: ${product.id}, Fiyat: ${product.price}');
    });
  }
  
  // Reklamları kaldırma ürününü alma
  ProductDetails? getRemoveAdsProduct() {
    try {
      return _products.firstWhere((product) => product.id == _removeAdsProductId);
    } catch (e) {
      print('Reklamları kaldırma ürünü bulunamadı');
      return null;
    }
  }
  
  // Satın alma işlemini başlatma
  Future<bool> purchaseRemoveAds() async {
    final ProductDetails? product = getRemoveAdsProduct();
    
    if (product == null) {
      print('Satın alınacak ürün bulunamadı');
      return false;
    }
    
    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: null,
      );
      
      return await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      print('Satın alma işlemi başlatılırken hata oluştu: $e');
      return false;
    }
  }
  
  // Satın alma güncellemelerini dinleme
  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        print('Satın alma işlemi beklemede');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        print('Satın alma hatası: ${purchaseDetails.error}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased || 
                 purchaseDetails.status == PurchaseStatus.restored) {
        print('Satın alma başarılı: ${purchaseDetails.productID}');
        
        // Satın alma doğrulama
        if (purchaseDetails.productID == _removeAdsProductId) {
          // Kullanıcıyı premium yap
          await _verifyAndUpdatePremiumStatus(purchaseDetails);
        }
      }
      
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    });
  }
  
  // Satın almayı doğrulama ve premium durumunu güncelleme
  Future<void> _verifyAndUpdatePremiumStatus(PurchaseDetails purchaseDetails) async {
    // Gerçek bir uygulamada, burada sunucu tarafında doğrulama yapılmalıdır
    // Şimdilik sadece yerel olarak premium durumunu güncelliyoruz
    
    // Kullanıcı ayarlarını güncelleme
    await updateUserPremiumStatus(true);
  }
  
  // Kullanıcı premium durumunu güncelleme
  Future<void> updateUserPremiumStatus(bool isPremium, {BuildContext? context, String? userId}) async {
    if (context != null) {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      
      if (settingsProvider.settings != null) {
        final updatedSettings = settingsProvider.settings!.copyWith(
          isPremium: isPremium,
        );
        
        await settingsProvider.updateUserSettings(updatedSettings);
      }
    } else if (userId != null) {
      // Kullanıcı ID'si ile güncelleme (context olmadan)
      // Bu kısım uygulamanızın yapısına göre değişebilir
    }
  }
  
  // Servisi dispose etme
  void dispose() {
    _subscription?.cancel();
  }
} 