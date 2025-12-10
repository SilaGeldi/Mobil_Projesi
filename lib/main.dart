import 'package:akilli_kampus_proje/view_models/notification_view_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'view_models/auth_view_model.dart';
import 'views/auth/login_view.dart';

// Senin sayfaların
import 'views/main/home_page.dart';
import 'views/main/add_new_notif_page.dart';

// TEST MODU — sadece sen kullanacaksın
const bool testMode = true;
const Widget testScreen = HomePage(); // Burayı değiştirebilirsin

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    // 🔥 TEST MODU ETKİNSE:
    if (testMode) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => NotificationViewModel()),
          ChangeNotifierProvider(create: (_) => AuthViewModel()), // istersen bunu da ekleyebilirsin
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: testScreen,
        ),
      );
    }

    // 🔥 NORMAL MOD (Login, Role Based Routing)
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: Consumer<AuthViewModel>(
        builder: (context, authViewModel, _) {
          if (authViewModel.currentUser != null) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: authViewModel.currentUser!.role == 'admin'
                  ? const AdminHomeView()
                  : const HomeView(),
            );
          }

          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: LoginView(),
          );
        },
      ),
    );
  }
}

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
