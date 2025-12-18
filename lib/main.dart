import 'package:akilli_kampus_proje/views/main/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

// ViewModels
import 'view_models/auth_view_model.dart';
import 'view_models/notification_view_model.dart';

// Views
import 'views/auth/login_view.dart';
import 'views/main/home_page.dart';

// 🔥 TEST MODU — sadece sen kullanacaksın
const bool testMode = false;
const Widget testScreen = HomePage(); // Burayı istediğin sayfa yapabilirsin

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
      ],

      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: testMode
            ? testScreen       // 🔥 TEST MODU → Senin sayfan açılır
            : const RootRouter(), // 🔥 NORMAL MOD → Login & yönlendirme
      ),
    );
  }
}

/// ---------------------------------------------------------------
///            🔥 NORMAL MOD İÇİN ROUTE YÖNETİCİSİ
/// ---------------------------------------------------------------
// main.dart içindeki RootRouter kısmını böyle güncelle:
class RootRouter extends StatelessWidget {
  const RootRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) {
        if (authViewModel.currentUser != null) {
          return authViewModel.currentUser!.role == "admin"
              ? const MainScreen()
              : const MainScreen(); // 🔥 HomePage yerine MainScreen döndürüyoruz
        }
        return const LoginView();
      },
    );
  }
}

/// ---------------------------------------------------------------
///                       ÖRNEK SAYFALAR
/// ---------------------------------------------------------------
class AdminHomeView extends StatelessWidget {
  const AdminHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthViewModel'e erişiyoruz
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Paneli"),
        actions: [
          // 🚪 Sağ üst köşeye çıkış butonu
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authViewModel.signOut();
              // Consumer sayesinde RootRouter otomatik olarak LoginView'a dönecektir.
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              "Admin Girişi Başarılı",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            // 🛑 Alternatif olarak ekranın ortasına büyük bir buton da ekleyebilirsin
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await authViewModel.signOut();
              },
              icon: const Icon(Icons.exit_to_app, color: Colors.white),
              label: const Text("Oturumu Kapat", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}


