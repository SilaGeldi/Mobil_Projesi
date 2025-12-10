import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/notification_view_model.dart';
import '../../models/notification_model.dart';
import 'add_new_notif_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifVM = Provider.of<NotificationViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Sol üst: kullanıcı adı
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Hoşgeldin,",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  "Sıla Geldi", // TODO: Firebase Auth'tan çekilecek
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Sağ üst: Ayarlar butonu
            IconButton(
              onPressed: () {
                print("Ayarlar butonuna basıldı");
              },
              icon: const Icon(Icons.settings, size: 28, color: Colors.black),
            ),
          ],
        ),
      ),

      // İçerik
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // 🔍 Arama Barı + Filtre Butonu
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

            // 📢 Bildirim Listesi
            Expanded(
              child: notifVM.notifications.isEmpty
                  ? const Center(
                child: Text(
                  "Hiç bildirim bulunmuyor...",
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

      // Sağ alttaki Yeni Bildirim + Buton
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddNewNotificationPage(),
              ));
        },
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, size: 30),
      ),

      // 🔽 Alt Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // orta buton = home
        onTap: (index) {
          if (index == 0) {
            print("Harita sayfasına gidiliyor...");
          } else if (index == 2) {
            print("Profil sayfasına gidiliyor...");
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: "Harita",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Anasayfa",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profil",
          ),
        ],
      ),
    );
  }

  // 🔔 Bildirim Kartı Tasarımı
  Widget _buildNotificationCard(NotificationModel notif) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // sol icon
          Icon(
            Icons.notifications,
            size: 32,
            color: Colors.black87,
          ),
          const SizedBox(width: 12),

          // sağ içerik alanı
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  notif.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // tip
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        notif.type,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    // tarih
                    Text(
                      _formatDate(notif.date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // 📅 Tarih Formatlama
  String _formatDate(Timestamp ts) {
    final date = ts.toDate();
    return "${date.day}.${date.month}.${date.year}";
  }
}
