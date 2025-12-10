// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userCollection = 'users'; // Firestore Koleksiyon Adı

  // Kullanıcı Kaydı (Register)
  Future<UserModel?> signUp({required String email, required String password, required String name, required String unit}) async {
    try {
      // 1. Auth: Firebase'de hesabı oluştur
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        // 2. Firestore: Varsayılan rol ile kullanıcı belgesini oluştur
        UserModel newUser = UserModel(
          uid: user.uid,
          email: email,
          name: name,
          unit: unit,
          role: 'user', // Yeni kayıtların varsayılan rolü 'user'
        );
        await _firestore.collection(_userCollection).doc(user.uid).set(newUser.toMap());
        return newUser;
      }
    } on FirebaseAuthException {
      rethrow;
    }
    return null;
  }

// Kullanıcı Girişi (Login) - GÜNCELLENDİ
  Future<UserModel?> signIn({required String email, required String password}) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection(_userCollection).doc(user.uid).get();

        // 🔹 Eğer belge henüz oluşmamışsa, kısa bir süre bekleyip tekrar dene
        if (!doc.exists) {
          await Future.delayed(const Duration(milliseconds: 700));
          doc = await _firestore.collection(_userCollection).doc(user.uid).get();
        }

        if (doc.exists) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>);
        } else {
          throw Exception('Kullanıcı rol bilgisi Firestoreda bulunamadı.');
        }
      }
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
    return null;
  }

// Çıkış Yap
  Future<void> signOut() async {
    await _auth.signOut();
  }

// Şifre Sıfırlama (Simülasyon/Gerçek Uygulama)
  Future<void> resetPassword({required String email}) async {
// Simülasyon için hata fırlatmayız, sadece başarılı sayarız.
    await Future.delayed(const Duration(milliseconds: 500));
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

// UID'den UserModel'i çeker (Sign-in ile aynı mantık)
  Future<UserModel?> getUserModelFromFirestore(String uid) async {
    DocumentSnapshot doc = await _firestore.collection(_userCollection).doc(uid).get();

    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    } else {
      // Firestore belgesi eksikse, hata fırlatılır.
      throw Exception('Kullanıcı rol bilgisi Firestoreda bulunamadı (Oturum kontrolü).');
    }
  }
}