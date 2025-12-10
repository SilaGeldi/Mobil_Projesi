// lib/view_models/auth_view_model.dart (SON HALİ - YAPISAL OLARAK DÜZELTİLMİŞ)

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 🚨 CONSTRUCTOR: Uygulama başladığında mevcut oturumu kontrol eder.
  AuthViewModel() {
    _initializeUser();
  }

  // Mevcut Firebase oturumunu kontrol eden asenkron metod
  void _initializeUser() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      try {
        // Firestore'dan rol bilgisini çekerek UserModel'i oluştur.
        _currentUser = await _authService.getUserModelFromFirestore(user.uid); 
        notifyListeners(); // View'a kullanıcının hazır olduğunu bildir.
      } catch (e) {
        // Firestore'dan veri çekilemezse (belge eksikse) oturumu kapat.
        await _authService.signOut();
      }
    }
  }
  
  // ----------------------------------------------------
  // DİĞER METOTLAR BURADAN SONRA BAŞLAMALIDIR
  // ----------------------------------------------------

  // Hata mesajını temizleme
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Yüklenme durumunu harici olarak ayarlama metodu
  void setIsLoading(bool status) {
    _isLoading = status;
    notifyListeners();
  }

  // 1. Kayıt İşlemi (REGISTER USER)
  Future<bool> registerUser({
    required String email,
    required String password,
    required String name,
    required String unit,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Loading başladı

    try {
      _currentUser = await _authService.signUp(
        email: email,
        password: password,
        name: name,
        unit: unit,
      );
      
      // Kayıt başarılı olduysa (Başarılı Senaryo)
      if (_currentUser != null) {
  _isLoading = false;
  _errorMessage = null;
  notifyListeners();
  return true;
}
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
    }
    
    // Hata veya başarısız Auth sonucu (Hata Senaryosu)
    _isLoading = false;
    notifyListeners();
    return false;
  }
  
  // 2. Giriş İşlemi (LOGIN USER)
  Future<bool> loginUser({required String email, required String password}) async {
    print("🟡 [loginUser] başladı");
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Loading başladı

    try {
      _currentUser = await _authService.signIn(email: email, password: password);
       print("🟢 [loginUser] signIn sonucu: ${_currentUser?.email}");

      if (_currentUser != null) {
        print("🟢 [loginUser] notifyListeners çağrılıyor...");
        notifyListeners(); 
        return true; 
      }
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      return false; 
    } finally {
      _isLoading = false;
      notifyListeners(); // Consumer'ı uyandırır ve yönlendirmeyi tetikler.
    }

    return false;
  }
  
  // 3. Şifre Sıfırlama İşlemi (RESET PASSWORD)
  Future<void> resetPassword({required String email}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email: email);
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Firebase Hata Kodlarını Kullanıcıya Okunur Hale Getirme
  String _getErrorMessage(dynamic e) {
      if (e is FirebaseAuthException) {
          if (e.code == 'user-not-found') return 'Bu e-posta adresiyle kayıtlı kullanıcı bulunamadı.';
          if (e.code == 'wrong-password') return 'Hatalı şifre girdiniz.';
          if (e.code == 'email-already-in-use') return 'Bu e-posta zaten kullanımda.';
          return 'Bir hata oluştu: ${e.code}';
      }
      return 'Bilinmeyen bir hata oluştu.';
  }

Future<void> signOut() async {
  await _authService.signOut();
  _currentUser = null;
  notifyListeners(); // Consumer'ı uyandır ki LoginView'a dönsün
}
}