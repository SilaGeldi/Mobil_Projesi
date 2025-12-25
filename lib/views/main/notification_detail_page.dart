import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notification_model.dart';
import '../../view_models/notification_view_model.dart';
import '../../view_models/auth_view_model.dart';

class NotificationDetailPage extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailPage({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    // 🔥 ViewModel'i dinliyoruz (listen: true varsayılandır)
    final notifVM = Provider.of<NotificationViewModel>(context);
    final authVM = Provider.of<AuthViewModel>(context);
    final userId = authVM.currentUser?.uid;

    // 🔥 BURASI ÖNEMLİ: Güncel listeden bu bildirimi buluyoruz ki takip durumu anlık güncellensin
    final currentNotif = notifVM.notifications.firstWhere(
          (n) => n.notifId == notification.notifId,
      orElse: () => notification,
    );

    final isFollowing = userId != null && currentNotif.followers.contains(userId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Bildirim Detayı", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // ⭐ TAKİP ET BUTONU (HomePage ile aynı mantığa çekildi)
          IconButton(
            icon: Icon(
              isFollowing ? Icons.bookmark : Icons.bookmark_border,
              color: isFollowing ? Colors.deepPurple : Colors.grey,
            ),
            onPressed: () {
              if (userId != null && currentNotif.notifId != null) {
                // ViewModel üzerinden işlem yapıyoruz
                notifVM.toggleFollowNotification(currentNotif.notifId!, userId);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Bilgi Etiketleri
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currentNotif.type.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Text(
                  _formatFullDate(currentNotif.date),
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Başlık
            Text(
              currentNotif.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const Divider(height: 40, thickness: 1),

            // Açıklama Bölümü
            const Text(
              "Açıklama",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey),
            ),
            const SizedBox(height: 10),
            Text(
              currentNotif.description,
              style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
            ),

            const SizedBox(height: 30),

            // Bilgi Kartları Grubu
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                      Icons.info_outline,
                      "Durum",
                      currentNotif.status,
                      _statusColor(currentNotif.status)
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                      Icons.person_outline,
                      "Oluşturan",
                      currentNotif.createdByName,
                      Colors.black87
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                      Icons.location_on_outlined,
                      "Konum",
                      "${currentNotif.location.latitude.toStringAsFixed(4)}, ${currentNotif.location.longitude.toStringAsFixed(4)}",
                      Colors.blue
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Harita Butonu
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  debugPrint("Haritada gösteriliyor: ${currentNotif.location.latitude}");
                },
                icon: const Icon(Icons.map, color: Colors.white),
                label: const Text("HARİTADA GÖRÜNTÜLE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Detay Satırı Widget'ı
  Widget _buildDetailRow(IconData icon, String title, String value, Color valueColor) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 24),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: valueColor)),
          ],
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "açık": return Colors.green;
      case "inceleniyor": return Colors.orange;
      case "çözüldü": return Colors.grey;
      default: return Colors.blueGrey;
    }
  }

  String _formatFullDate(Timestamp ts) {
    final d = ts.toDate();
    return "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
  }
}