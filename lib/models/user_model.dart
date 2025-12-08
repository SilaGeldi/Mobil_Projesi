// lib/models/user_model.dart

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String unit;
  final String role; // 'user' veya 'admin'

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.unit,
    required this.role,
  });

  // Firestore'dan veri okumak için
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      unit: data['unit'] ?? '',
      role: data['role'] ?? 'user',
    );
  }

  // Firestore'a veri yazmak için
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'unit': unit,
      'role': role,
      'createdAt': DateTime.now().toUtc(),
    };
  }
}