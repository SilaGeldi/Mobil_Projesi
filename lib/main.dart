// lib/main.dart (Temel Yapı)

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'view_models/auth_view_model.dart';
import 'views/auth/login_view.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase'i başlat
  runApp(
    ChangeNotifierProvider( // AuthViewModel'i tüm uygulamaya sağlar
      create: (context) => AuthViewModel(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Uygulama her açıldığında Auth durumunu kontrol eden bir tüketici (Consumer)
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        // Eğer kullanıcı zaten giriş yapmışsa (veya giriş başarılıysa)
        if (authViewModel.currentUser != null) {
          // Kullanıcı modelindeki role bakarak yönlendirme yaparız
          return MaterialApp(
            title: 'Akıllı Kampüs',
            home: authViewModel.currentUser!.role == 'admin'
                ?  AdminHomeView() // Admin sayfasına yönlendir
                :  HomeView(), // Normal kullanıcı sayfasına yönlendir
          );
        }

        // Eğer giriş yapılmamışsa, Login ekranını göster
        return const MaterialApp(
          title: 'Akıllı Kampüs',
          home: LoginView(),
        );
      },
    );
  }
}


// ... (mevcut kodlar) ...

// Örnek boş sayfalar (Daha sonra detaylandırılacak)
class AdminHomeView extends StatelessWidget {
  const AdminHomeView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Paneli')),
      body: const Center(child: Text('Admin Girişi Başarılı')),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kullanıcı Ana Sayfası')),
      body: const Center(child: Text('Kullanıcı Girişi Başarılı')),
    );
  }
}