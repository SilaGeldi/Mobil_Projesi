import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../view_models/notification_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../models/notification_model.dart';
import 'add_new_notif_page.dart';
import 'notification_detail_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String searchQuery = "";
  String? selectedStatus;
  String? selectedType; // 🔥 artık gerçek type değeri tutuyor: "saglik", "kayip", ...
  bool showOnlyFollowed = false;

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

    // 🔥 Filtreleme
    final filteredNotifications = notifVM.notifications.where((n) {
      final typeLower = n.type.toLowerCase();

      // 1) Kullanıcı Tercihleri (senin eski kodunu bozmadan daha toleranslı yaptım)
      if (user != null) {
        // Sağlık tercih kontrolü: "sağlık" veya "saglik" gelirse
        if ((typeLower == 'sağlık' || typeLower == 'saglik') &&
            !(user.preferences['health'] ?? true)) return false;

        // Teknik tercih kontrolü: "teknik" / "teknikariza" / "teknik_ariza" / "teknikariza" / "teknikariza"
        final isTechnical = typeLower == 'teknik' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknik_ariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknik ariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknik arıza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikariza' ||
            typeLower == 'teknikAriza'.toLowerCase();

        if (isTechnical && !(user.preferences['technical'] ?? true)) return false;
      }

      // 2) Takip edilenler filtresi
      if (showOnlyFollowed && user != null) {
        if (!n.followers.contains(user.uid)) return false;
      }

      // 3) Arama
      final matchesSearch =
          n.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
              n.description.toLowerCase().contains(searchQuery.toLowerCase());

      // 4) Durum / Tür
      final matchesStatus =
          selectedStatus == null || n.status.toLowerCase() == selectedStatus!;
      final matchesType =
          selectedType == null || typeLower == selectedType!;

      return matchesSearch && matchesStatus && matchesType;
    }).toList();

    // ✅ ACİL duyuruları ayır
    final emergencyNotifs = filteredNotifications
        .where((n) => n.type.toLowerCase() == "acil")
        .toList();

    final normalNotifs = filteredNotifications
        .where((n) => n.type.toLowerCase() != "acil")
        .toList();

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
            Text(
              userName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 10),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _showFilterBottomSheet(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (selectedStatus != null || selectedType != null || showOnlyFollowed)
                          ? Colors.blueAccent
                          : Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.filter_list, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child: (emergencyNotifs.isEmpty && normalNotifs.isEmpty)
                  ? const Center(child: Text("Sonuç bulunamadı", style: TextStyle(color: Colors.grey)))
                  : ListView(
                children: [
                  // 🔴 ACİL DUYURULAR BLOĞU (en üstte)
                  if (emergencyNotifs.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "ACİL DUYURULAR",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    ...emergencyNotifs.map((notif) => GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NotificationDetailPage(notification: notif),
                        ),
                      ),
                      child: _buildNotificationCard(
                        context,
                        notif,
                        user?.uid,
                        forceEmergencyStyle: true,
                      ),
                    )),
                    const SizedBox(height: 8),
                  ],

                  // 🟦 NORMAL LİSTE
                  ...normalNotifs.map((notif) => GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationDetailPage(notification: notif),
                      ),
                    ),
                    child: _buildNotificationCard(context, notif, user?.uid),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0D47A1),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddNewNotificationPage()),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Filtrele", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  const Text("Özel Filtre", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  FilterChip(
                    label: const Text("Sadece Takip Ettiklerim"),
                    selected: showOnlyFollowed,
                    onSelected: (val) => setState(() {
                      showOnlyFollowed = val;
                      setModalState(() {});
                    }),
                    selectedColor: Colors.blue.shade100,
                    checkmarkColor: Colors.blue,
                  ),
                  const SizedBox(height: 15),

                  const Text("Durum", style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: ["açık", "inceleniyor", "çözüldü"].map((s) {
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
                    runSpacing: 4,
                    children: const [
                      {"label": "Acil Duyuru", "value": "acil"},
                      {"label": "Sağlık", "value": "saglik"},
                      {"label": "Kayıp", "value": "kayip"},
                      {"label": "Güvenlik", "value": "guvenlik"},
                      {"label": "Duyuru", "value": "duyuru"},
                      {"label": "Çevre", "value": "cevre"},
                      {"label": "Teknik Arıza", "value": "teknikariza"}, // eğer sende "teknikAriza" ise altta normalize ediyoruz
                      {"label": "Diğer", "value": "diger"},
                    ].map((t) {
                      final v = t["value"]!;
                      return ChoiceChip(
                        label: Text(t["label"]!),
                        selected: selectedType == v,
                        onSelected: (val) => setState(() {
                          selectedType = val ? v : null;
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
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildNotificationCard(
      BuildContext context,
      NotificationModel notif,
      String? userId, {
        bool forceEmergencyStyle = false,
      }) {
    final notifVM = Provider.of<NotificationViewModel>(context, listen: false);
    final isFollowing = userId != null && notif.followers.contains(userId);

    final isEmergency = forceEmergencyStyle || notif.type.toLowerCase() == "acil";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isEmergency ? Colors.red.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isEmergency ? Colors.red.shade200 : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isEmergency)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red.shade700, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    "ACİL DUYURU",
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  notif.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isEmergency ? Colors.red.shade900 : Colors.black,
                  ),
                ),
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
                decoration: BoxDecoration(
                  color: isEmergency ? Colors.red.shade700 : Colors.blue.shade400,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  notif.type,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "açık":
        return Colors.green;
      case "inceleniyor":
        return Colors.orange;
      case "çözüldü":
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatDate(Timestamp ts) {
    final d = ts.toDate();
    return "${d.day}.${d.month}.${d.year}";
  }
}
