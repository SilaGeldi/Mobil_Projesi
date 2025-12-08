// lib/view_models/auth_view_model.dart

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

  // Hata mesajını temizleme
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Kayıt İşlemi
  Future<bool> registerUser({
    required String email,
    required String password,
    required String name,
    required String unit,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentUser = await _authService.signUp(
        email: email,
        password: password,
        name: name,
        unit: unit,
      );
      _isLoading = false;
      if (_currentUser != null) {
        return true;
      }
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }
  
  // Giriş İşlemi
  Future<bool> loginUser({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentUser = await _authService.signIn(email: email, password: password);
      _isLoading = false;
      if (_currentUser != null) {
        return true;
      }
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
    }
    _isLoading = false;
    notifyListeners();
    return false;
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
}