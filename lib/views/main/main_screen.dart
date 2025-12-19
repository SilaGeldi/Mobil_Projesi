import 'package:flutter/material.dart';
import 'home_page.dart';
import 'profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1; // Başlangıçta "Ana Sayfa" (orta sekme) seçili olsun

  
 final List<Widget> _pages = [
   const Center(child: Text("Harita Sayfası Hazırlanıyor")), // İndex 0
 const HomePage(),   
    const ProfilePage(), 
 ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack kullanımı sayfalar arası geçişte durumu (scroll vb.) korur
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: "Harita"),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Ana Sayfa"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}