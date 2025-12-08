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
      rethrow; // Hata yönetimi (örneğin 'email-already-in-use')
    }
    return null;
  }

  // Kullanıcı Girişi (Login)
  Future<UserModel?> signIn({required String email, required String password}) async {
    try {
      // 1. Auth: Kullanıcının kimliğini doğrula
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        // 2. Firestore: Rol bilgisini çek
        DocumentSnapshot doc = await _firestore.collection(_userCollection).doc(user.uid).get();

        if (doc.exists) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>);
        }
      }
    } on FirebaseAuthException {
      rethrow; // Hata yönetimi (örneğin 'wrong-password')
    }
    return null;
  }
  
  // Çıkış Yap
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  // Şifre Sıfırlama (Simülasyon/Gerçek Uygulama)
  Future<void> resetPassword({required String email}) async {
    // Proje gereksinimi şifre sıfırlama bağlantısının gönderildiğini "simüle" etmektir.
    // Eğer gerçekten göndermek isterseniz:
    // await _auth.sendPasswordResetEmail(email: email);
    
    // Simülasyon için hata fırlatmayız, sadece başarılı sayarız.
    await Future.delayed(Duration(milliseconds: 500)); 
  }
}