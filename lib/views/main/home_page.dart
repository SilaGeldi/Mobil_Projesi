import 'package:akilli_kampus_proje/views/main/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../view_models/notification_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../models/notification_model.dart';
import 'add_new_notif_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifVM = Provider.of<NotificationViewModel>(context);
    final authVM = Provider.of<AuthViewModel>(context);
    final userName = authVM.currentUser?.name ?? "Kullanıcı";

    return Scaffold(
      backgroundColor: Colors.white,

      // 🔝 APP BAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Hoşgeldin,",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.black),
              onPressed: () {
                debugPrint("Ayarlar tıklandı");
              },
            )
          ],
        ),
      ),

      // 📦 BODY
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // 🔍 ARAMA + FİLTRE
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: "Bildirimlerde ara...",
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.filter_list, color: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 📢 BİLDİRİM LİSTESİ
            Expanded(
              child: notifVM.notifications.isEmpty
                  ? const Center(
                child: Text(
                  "Henüz bildirim yok",
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: notifVM.notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifVM.notifications[index];
                  return _buildNotificationCard(notif);
                },
              ),
            ),
          ],
        ),
      ),

      // ➕ YENİ BİLDİRİM
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddNewNotificationPage(),
            ),
          );
        },
      ),

      // 🔽 ALT BAR
bottomNavigationBar: BottomNavigationBar(
  currentIndex: 1, // Ana Sayfa seçili
  onTap: (index) {
    if (index == 0) {
      debugPrint("Harita");
      // İleride buraya MapPage() gelecek
    } 
    if (index == 2) {
      // 🚀 PROFİL SAYFASINA GİDİŞ
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    }
  },
  items: const [
    BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: "Harita"),
    BottomNavigationBarItem(icon: Icon(Icons.home), label: "Ana Sayfa"),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
  ],
),
    );
  }

  // 🔔 BİLDİRİM KARTI
  Widget _buildNotificationCard(NotificationModel notif) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ÜST SATIR: BAŞLIK + TARİH
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  notif.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Text(
                _formatDate(notif.date),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // AÇIKLAMA
          Text(
            notif.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 10),

          // ALT SATIR: DURUM + TÜR
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // DURUM
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(notif.status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  notif.status,
                  style:
                  const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),

              // TÜR
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  notif.type,
                  style:
                  const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case "aktif":
        return Colors.green;
      case "pasif":
        return Colors.grey;
      case "inceleniyor":
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }


  String _formatDate(Timestamp ts) {
    final d = ts.toDate();
    return "${d.day}.${d.month}.${d.year}";
  }
}
