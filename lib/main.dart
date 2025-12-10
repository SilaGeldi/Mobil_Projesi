// lib/main.dart (Temel Yapı)

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'view_models/auth_view_model.dart';
import 'views/auth/login_view.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    const MyApp(), // Provider’ı burada değil, MyApp içinde kullanacağız
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: Consumer<AuthViewModel>(
        builder: (context, authViewModel, _) {
           print("🔄 [main.dart] rebuild edildi - currentUser: ${authViewModel.currentUser?.email}");
          return MaterialApp(
            title: 'Akıllı Kampüs',
            home: authViewModel.currentUser != null
                ? (authViewModel.currentUser!.role == 'admin'
                    ? const AdminHomeView()
                    : const HomeView())
                : const LoginView(),
          );
        },
      ),
    );
  }
}

// ... (mevcut kodlar) ...

// Örnek boş sayfalar (Daha sonra detaylandırılacak)
class AdminHomeView extends StatelessWidget {
  const AdminHomeView({super.key});
  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false); 
    
    return Scaffold(
      appBar: AppBar(title: const Text('Kullanıcı Ana Sayfası')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Kullanıcı Girişi Başarılı'),
            const SizedBox(height: 20),
            
            // 🚨 Çıkış Yap Butonu
           ElevatedButton(
  onPressed: () async {
    await authViewModel.signOut();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
        (route) => false, // 🔹 Önceki tüm sayfaları siler
      );
    }
  },
  child: const Text('Çıkış Yap'),
),

          ],
        ),
      ),
    );
  }
}


// ...
class HomeView extends StatelessWidget {
  const HomeView({super.key});
  @override
  Widget build(BuildContext context) {
    // AuthViewModel'e erişim
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false); 

    return Scaffold(
      appBar: AppBar(title: const Text('Kullanıcı Ana Sayfası')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Kullanıcı Girişi Başarılı'),
            const SizedBox(height: 20),
            
            // 🚨 Çıkış Yap Butonu
            ElevatedButton(
  onPressed: () async {
    await authViewModel.signOut();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
        (route) => false, // 🔹 Önceki tüm sayfaları siler
      );
    }
  },
  child: const Text('Çıkış Yap'),
),

          ],
        ),
      ),
    );
  }
}
// ... (AdminHomeView'a da aynı butonu ekleyebilirsiniz)