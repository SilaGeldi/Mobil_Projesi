import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../view_models/notification_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../models/notification_model.dart';
import 'add_new_notif_page.dart';
import 'notification_detail_page.dart'; // Detay sayfasını import edin
import 'profile_page.dart'; // Profil sayfasını import edin

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String searchQuery = "";
  String? selectedStatus;
  String? selectedType;

  // Kullanıcı adının baş harflerini büyütme fonksiyonu
  String capitalize(String name) {
    if (name.isEmpty) return name;
    return name.split(' ').map((str) {
      if (str.isEmpty) return str;
      return str[0].toUpperCase() + str.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final notifVM = Provider.of<NotificationViewModel>(context);
    final authVM = Provider.of<AuthViewModel>(context);
    final user = authVM.currentUser;
    final userName = capitalize(user?.name ?? "Kullanıcı");

    // 🔥 FİLTRELEME, ARAMA VE TERCİH MANTIĞI BİRLEŞTİRİLDİ
    final filteredNotifications = notifVM.notifications.where((n) {
      // 1. Arkadaşının eklediği kategori tercih kontrolü
      if (user != null) {
        // Not: user.preferences yapısı modelinizde tanımlı olmalıdır
        if (n.type == 'sağlık' && !(user.preferences['health'] ?? true)) return false;
        if (n.type == 'teknik' && !(user.preferences['technical'] ?? true)) return false;
      }

      // 2. Arama Sorgusu Kontrolü
      final matchesSearch = n.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          n.description.toLowerCase().contains(searchQuery.toLowerCase());

      // 3. Durum ve Tür Filtresi Kontrolü
      final matchesStatus = selectedStatus == null || n.status == selectedStatus;
      final matchesType = selectedType == null || n.type == selectedType;

      return matchesSearch && matchesStatus && matchesType;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Hoşgeldin,", style: TextStyle(fontSize: 14, color: Colors.grey)),
            Text(userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // 🔍 ARAMA + FİLTRE BUTONU
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => searchQuery = value),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: "Bildirimlerde ara...",
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _showFilterBottomSheet(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.filter_list, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 📢 LİSTELEME
            Expanded(
              child: filteredNotifications.isEmpty
                  ? const Center(child: Text("Sonuç bulunamadı", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                itemCount: filteredNotifications.length,
                itemBuilder: (context, index) {
                  final notif = filteredNotifications[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NotificationDetailPage(notification: notif)),
                    ),
                    child: _buildNotificationCard(context, notif, user?.uid),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddNewNotificationPage())),
      ),
      /*bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: "Harita"),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Ana Sayfa"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ), */
    );
  }

  // 🛠 FİLTRELEME BOTTOM SHEET
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Filtrele", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                const Text("Durum", style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: ["aktif", "pasif", "inceleniyor"].map((s) {
                    return ChoiceChip(
                      label: Text(s),
                      selected: selectedStatus == s,
                      onSelected: (val) => setState(() {
                        selectedStatus = val ? s : null;
                        setModalState(() {});
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 15),
                const Text("Tür", style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: ["sağlık", "kayıp", "güvenlik", "duyuru", "diğer"].map((t) {
                    return ChoiceChip(
                      label: Text(t),
                      selected: selectedType == t,
                      onSelected: (val) => setState(() {
                        selectedType = val ? t : null;
                        setModalState(() {});
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Uygula", style: TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          );
        });
      },
    );
  }

  // 🔔 BİLDİRİM KARTI (ARKADAŞININ TAKİP MANTIĞI KORUNDU)
  Widget _buildNotificationCard(BuildContext context, NotificationModel notif, String? userId) {
    final notifVM = Provider.of<NotificationViewModel>(context, listen: false);

    // Arkadaşının takip mantığı: followers listesinde userId var mı?
    final isFollowing = userId != null && notif.followers.contains(userId);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(notif.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  isFollowing ? Icons.bookmark : Icons.bookmark_border,
                  color: isFollowing ? Colors.deepPurple : Colors.grey,
                ),
                onPressed: () {
                  if (userId != null) {
                    notifVM.toggleFollowNotification(notif.notifId!, userId);
                  }
                },
              ),
              const SizedBox(width: 8),
              Text(_formatDate(notif.date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 6),
          Text(notif.description, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _statusColor(notif.status), borderRadius: BorderRadius.circular(8)),
                child: Text(notif.status, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                child: Text(notif.type, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "aktif": return Colors.green;
      case "pasif": return Colors.grey;
      case "inceleniyor": return Colors.orange;
      default: return Colors.blueGrey;
    }
  }

  String _formatDate(Timestamp ts) {
    final d = ts.toDate();
    return "${d.day}.${d.month}.${d.year}";
  }
}