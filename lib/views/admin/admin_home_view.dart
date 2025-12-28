import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../view_models/notification_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../models/notification_model.dart';
import '../main/add_new_notif_page.dart';

class AdminHomeView extends StatefulWidget {
  const AdminHomeView({super.key});

  @override
  State<AdminHomeView> createState() => _AdminHomeViewState();
}

class _AdminHomeViewState extends State<AdminHomeView> {
  String searchQuery = "";
  String? selectedStatus;
  String? selectedType;
  bool showOnlyFollowed = false;

  @override
  Widget build(BuildContext context) {
    final notifVM = context.watch<NotificationViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.currentUser;

    final filteredNotifications = notifVM.notifications.where((n) {
      if (showOnlyFollowed && user != null) {
        if (!n.followers.contains(user.uid)) return false;
      }

      final matchesSearch =
          n.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          n.description.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesStatus =
          selectedStatus == null || n.status == selectedStatus;

      final matchesType =
          selectedType == null || n.type == selectedType;

      return matchesSearch && matchesStatus && matchesType;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Admin Bildirimleri",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
        IconButton(
            icon: const Icon(Icons.campaign, color: Colors.red),
            tooltip: "Acil Duyuru Yayınla",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddNewNotificationPage(),
                ),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 10),

            /// 🔍 SEARCH + FILTER
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => searchQuery = v),
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
                      color: (selectedStatus != null ||
                              selectedType != null ||
                              showOnlyFollowed)
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

            /// 📋 LIST
            Expanded(
              child: filteredNotifications.isEmpty
                  ? const Center(
                      child: Text(
                        "Sonuç bulunamadı",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredNotifications.length,
                      itemBuilder: (context, index) {
                        final notif = filteredNotifications[index];
                        return GestureDetector(
                          onTap: () =>
                              _showAdminBottomSheet(context, notif),
                          child: _buildNotificationCard(
                            context,
                            notif,
                            user?.uid,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= FILTER =================

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      const Text(
                        "Filtrele",
                        style:
                            TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                  
                      FilterChip(
                        label: const Text("Sadece Takip Ettiklerim"),
                        selected: showOnlyFollowed,
                        onSelected: (val) {
                          setState(() => showOnlyFollowed = val);
                          setModalState(() {});
                        },
                      ),
                  
                      const SizedBox(height: 16),
                      const Text("Durum"),
                      Wrap(
                        spacing: 8,
                        children: ["aktif", "inceleniyor", "pasif"].map((s) {
                          return ChoiceChip(
                            label: Text(s),
                            selected: selectedStatus == s,
                            onSelected: (val) {
                              setState(() =>
                                  selectedStatus = val ? s : null);
                              setModalState(() {});
                            },
                          );
                        }).toList(),
                      ),
                  
                      const SizedBox(height: 16),
                      const Text("Tür"),
                      Wrap(
                        spacing: 8,
                        children: [
                          "Sağlık",
                          "Güvenlik",
                          "Teknik",
                          "Duyuru",
                          "Diğer"
                        ].map((t) {
                          return ChoiceChip(
                            label: Text(t),
                            selected: selectedType == t,
                            onSelected: (val) {
                              setState(() =>
                                  selectedType = val ? t : null);
                              setModalState(() {});
                            },
                          );
                        }).toList(),
                      ),
                  
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Uygula"),
                        ),
                      ),
                    ],
                  ),
              ),
            );
          },
        );
      },
    );
  }

  /// ================= CARD =================

  Widget _buildNotificationCard(
      BuildContext context, NotificationModel notif, String? userId) {
    final notifVM =
        Provider.of<NotificationViewModel>(context, listen: false);
    final isFollowing =
        userId != null && notif.followers.contains(userId);

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
            children: [
              Expanded(
                child: Text(
                  notif.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              IconButton(
                icon: Icon(
                  isFollowing
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  color:
                      isFollowing ? Colors.deepPurple : Colors.grey,
                ),
                onPressed: () {
                  if (userId != null) {
                    notifVM.toggleFollowNotification(
                        notif.notifId!, userId);
                  }
                },
              ),
            ],
          ),
          Text(
            notif.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _chip(notif.status, _statusColor(notif.status)),
              _chip(notif.type, Colors.blue),
            ],
          )
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child:
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  /// ================= ADMIN BOTTOM SHEET =================

  void _showAdminBottomSheet(
      BuildContext context, NotificationModel notif) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notif.title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text("👤 ${notif.createdByName}",
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                Text(notif.description),
                const Divider(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statusButton(
                        context, notif.notifId!, "aktif", Colors.green, "Açık"),
                    _statusButton(context, notif.notifId!, "inceleniyor",
                        Colors.orange, "İnceleniyor"),
                    _statusButton(
                        context, notif.notifId!, "pasif", Colors.grey, "Çözüldü"),
                  ],
                ),

                const Divider(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () =>
                          _showEditDescriptionDialog(context, notif),
                      icon: const Icon(Icons.edit, color: Colors.blue),
                    ),
                    IconButton(
                      onPressed: () => _showDeleteConfirmDialog(
                          context, notif.notifId!),
                      icon:
                          const Icon(Icons.delete_forever, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ================= ADMIN ACTIONS =================

  Widget _statusButton(BuildContext context, String id, String status,
      Color color, String label) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color),
      onPressed: () {
        context.read<NotificationViewModel>().updateNotificationStatus(id, status);
      },
      child: Text(label),
    );
  }

  void _showEditDescriptionDialog(
      BuildContext context, NotificationModel notif) {
    final controller = TextEditingController(text: notif.description);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Açıklamayı Düzenle"),
        content: TextField(controller: controller, maxLines: 4),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal")),
          ElevatedButton(
            onPressed: () {
              context
                  .read<NotificationViewModel>()
                  .updateNotificationDescription(
                      notif.notifId!, controller.text);
              Navigator.pop(context);
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Bildirimi Sil"),
        content:
            const Text("Bu bildirimi kalıcı olarak silmek istiyor musun?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Vazgeç")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<NotificationViewModel>().deleteNotification(id);
              Navigator.pop(context);
            },
            child: const Text("Sil"),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case "aktif":
        return Colors.green;
      case "inceleniyor":
        return Colors.orange;
      case "pasif":
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }
}
