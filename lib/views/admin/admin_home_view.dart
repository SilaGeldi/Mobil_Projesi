import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../view_models/auth_view_model.dart';
import '../../view_models/notification_view_model.dart';
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
    final userId = authVM.currentUser?.uid;

    final notifications = notifVM.notifications.where((n) {
      final matchesSearch =
          n.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          n.description.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesStatus =
          selectedStatus == null ||
          n.status.toLowerCase() == selectedStatus;

      final matchesType =
          selectedType == null ||
          n.type.toLowerCase() == selectedType;

      final matchesFollowed =
          !showOnlyFollowed ||
          (userId != null && n.followers.contains(userId));

      return matchesSearch &&
          matchesStatus &&
          matchesType &&
          matchesFollowed;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Duyurular"),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AddNewNotificationPage(isEmergency: true),
                ),
              );
            },
            icon: const Icon(Icons.warning, color: Colors.red),
            label: const Text(
              "Acil Duyuru Yayınla",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const AddNewNotificationPage(isEmergency: false),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Ara...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (v) =>
                        setState(() => searchQuery = v),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.filter_list,
                    color: (selectedStatus != null ||
                            selectedType != null ||
                            showOnlyFollowed)
                        ? Colors.deepPurple
                        : Colors.grey,
                  ),
                  onPressed: () =>
                      _showFilterBottomSheet(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: notifications.isEmpty
                ? const Center(child: Text("Kayıt bulunamadı"))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: notifications.length,
                    itemBuilder: (_, i) => _notificationCard(
                      context,
                      notifications[i],
                      userId,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _notificationCard(
    BuildContext context,
    NotificationModel notif,
    String? userId,
  ) {
    final notifVM = context.read<NotificationViewModel>();
    final isFollowing =
        userId != null && notif.followers.contains(userId);

    return GestureDetector(
      onTap: () => _openAdminBottomSheet(notif),
      child: Container(
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFollowing
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: isFollowing
                        ? Colors.deepPurple
                        : Colors.grey,
                  ),
                  onPressed: () {
                    if (userId != null) {
                      notifVM.toggleFollowNotification(
                        notif.notifId!,
                        userId,
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
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
                _chip(notif.type, Colors.red.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openAdminBottomSheet(NotificationModel notif) {
    final descController =
        TextEditingController(text: notif.description);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notif.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
             Text(
  "👤 ${notif.createdByName.isEmpty ? 'BOŞ GELİYOR' : notif.createdByName}",
  style: const TextStyle(color: Colors.red),
),

              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Açıklama",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ["Açık", "İnceleniyor", "Çözüldü"]
                    .map(
                      (s) => ChoiceChip(
                        label: Text(s),
                        selected:
                            notif.status.toLowerCase() ==
                                s.toLowerCase(),
                        onSelected: (_) {
                          context
                              .read<NotificationViewModel>()
                              .updateNotificationStatus(
                                notif.notifId!,
                                s.toLowerCase(),
                              );
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("Kaydet"),
                      onPressed: () {
                        context
                            .read<NotificationViewModel>()
                            .updateNotificationDescription(
                              notif.notifId!,
                              descController.text,
                            );
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete,
                          color: Colors.red),
                      label: const Text("Sil"),
                      onPressed: () {
                        context
                            .read<NotificationViewModel>()
                            .deleteNotification(
                              notif.notifId!,
                            );
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Filtrele",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                FilterChip(
                  label: const Text("Sadece Takip Ettiklerim"),
                  selected: showOnlyFollowed,
                  onSelected: (val) {
                    setState(() => showOnlyFollowed = val);
                    setModalState(() {});
                  },
                ),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 8,
                  children: const [
                    {"label": "Açık", "value": "açık"},
                    {"label": "İnceleniyor", "value": "inceleniyor"},
                    {"label": "Çözüldü", "value": "çözüldü"},
                  ].map((s) {
                    return ChoiceChip(
                      label: Text(s["label"]!),
                      selected: selectedStatus == s["value"],
                      onSelected: (val) {
                        setState(() {
                          selectedStatus =
                              val ? s["value"] : null;
                        });
                        setModalState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: const [
                    {"label": "Acil", "value": "acil"},
                    {"label": "Genel", "value": "genel"},
                    {"label": "Bilgi", "value": "bilgi"},
                  ].map((t) {
                    return ChoiceChip(
                      label: Text(t["label"]!),
                      selected: selectedType == t["value"],
                      onSelected: (val) {
                        setState(() {
                          selectedType =
                              val ? t["value"] : null;
                        });
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
          );
        });
      },
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
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
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
