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
import 'views/main/add_new_notif_page.dart';

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
class RootRouter extends StatelessWidget {
  const RootRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) {
        // Kullanıcı giriş yaptıysa
        if (authViewModel.currentUser != null) {
          return authViewModel.currentUser!.role == "admin"
              ? const AdminHomeView()
              : const HomePage(); // 🔥 SENİN ANA SAYFAN
        }

        // Giriş yapılmamışsa
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
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Paneli")),
      body: const Center(child: Text("Admin Girişi Başarılı")),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kullanıcı Ana Sayfası")),
      body: const Center(child: Text("Kullanıcı Girişi Başarılı")),
    );
  }
}
