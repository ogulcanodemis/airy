import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = false;
  String _error = '';

  // Getters
  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _firebaseUser != null;
  String get error => _error;

  // Constructor
  AuthProvider() {
    _init();
  }

  // Başlangıç durumunu ayarlama
  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    _firebaseUser = _firebaseService.getCurrentUser();
    
    if (_firebaseUser != null) {
      await _fetchUserModel();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Kullanıcı modelini getirme
  Future<void> _fetchUserModel() async {
    if (_firebaseUser == null) return;

    try {
      _userModel = await _firebaseService.getUserProfile(_firebaseUser!.uid);
    } catch (e) {
      _error = 'Kullanıcı profili alınamadı: $e';
    }
  }

  // Giriş yapma
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _firebaseUser = await _firebaseService.signInWithEmailAndPassword(email, password);
      
      if (_firebaseUser != null) {
        await _fetchUserModel();
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      _error = 'Giriş yapılamadı';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      
      // Hata mesajını daha kullanıcı dostu hale getir
      if (e.toString().contains('user-not-found')) {
        _error = 'Bu e-posta adresi ile kayıtlı bir kullanıcı bulunamadı';
      } else if (e.toString().contains('wrong-password')) {
        _error = 'Hatalı şifre girdiniz';
      } else if (e.toString().contains('invalid-email')) {
        _error = 'Geçersiz e-posta adresi';
      } else if (e.toString().contains('network')) {
        _error = 'İnternet bağlantınızı kontrol edin';
      } else {
        _error = 'Giriş yapılırken hata oluştu: $e';
      }
      
      notifyListeners();
      return false;
    }
  }

  // Kayıt olma
  Future<bool> register(String email, String password, String displayName) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _firebaseUser = await _firebaseService.registerWithEmailAndPassword(
        email,
        password,
        displayName,
      );
      
      if (_firebaseUser != null) {
        await _fetchUserModel();
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      _error = 'Kayıt olunamadı';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      
      // Hata mesajını daha kullanıcı dostu hale getir
      if (e.toString().contains('email-already-in-use')) {
        _error = 'Bu e-posta adresi zaten kullanılıyor';
      } else if (e.toString().contains('weak-password')) {
        _error = 'Şifre çok zayıf, daha güçlü bir şifre seçin';
      } else if (e.toString().contains('invalid-email')) {
        _error = 'Geçersiz e-posta adresi';
      } else if (e.toString().contains('network')) {
        _error = 'İnternet bağlantınızı kontrol edin';
      } else {
        _error = 'Kayıt olunurken hata oluştu: $e';
      }
      
      notifyListeners();
      return false;
    }
  }

  // Çıkış yapma
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firebaseService.signOut();
      _firebaseUser = null;
      _userModel = null;
    } catch (e) {
      _error = 'Çıkış yapılırken hata oluştu: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Kullanıcı profilini güncelleme
  Future<bool> updateProfile(String displayName) async {
    if (_userModel == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = _userModel!.copyWith(
        displayName: displayName,
        lastLoginAt: DateTime.now(),
      );
      
      await _firebaseService.updateUserProfile(updatedUser);
      _userModel = updatedUser;
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Profil güncellenirken hata oluştu: $e';
      notifyListeners();
      return false;
    }
  }

  // Hata mesajını temizleme
  void clearError() {
    _error = '';
    notifyListeners();
  }
} 