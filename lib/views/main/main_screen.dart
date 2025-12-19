import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/auth_view_model.dart';
import '../admin/admin_home_view.dart';
import 'home_page.dart';
import 'profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1; // Başlangıçta Ana Sayfa seçili

  @override
  Widget build(BuildContext context) {
    // 1. AuthViewModel'e BuildContext içinden güvenli erişim
    final authVM = Provider.of<AuthViewModel>(context);
    final bool isAdmin = authVM.currentUser?.role == "admin";

    // 2. Sayfa listesini build içinde tanımlıyoruz ki isAdmin her değişimde güncellensin
    final List<Widget> _pages = [
      const Center(child: Text("Harita Sayfası Hazırlanıyor")), // İndex 0
      isAdmin ? const AdminHomeView() : const HomePage(),      // İndex 1 (Dinamik)
      const ProfilePage(),                                    // İndex 2
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: isAdmin ? Colors.red.shade800 : Colors.deepPurple,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined), 
            label: "Harita"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home), 
            label: "Ana Sayfa"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person), 
            label: "Profil"
          ),
        ],
      ),
    );
  }
}