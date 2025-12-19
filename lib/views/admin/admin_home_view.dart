import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/notification_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../main/add_new_notif_page.dart'; 

class AdminHomeView extends StatelessWidget {
  const AdminHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final notifVM = Provider.of<NotificationViewModel>(context);
    final authVM = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Admin Yönetim Paneli"),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
        elevation: 2,
        // 🔥 OTURUMU KAPAT BUTONU (Sağ Üst Köşe)
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Oturumu Kapat",
            onPressed: () async {
              await authVM.signOut();
              // RootRouter sayesinde otomatik LoginView'a döner.
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 🚨 ACİL DURUM YAYINLAMA MODÜLÜ (Gereksinim 6)
          _buildEmergencyQuickPost(context),
          
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            color: Colors.grey.shade100,
            child: Text(
              "Sistemdeki Tüm Bildirimler (${notifVM.notifications.length})", 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54),
            ),
          ),
          
          Expanded(
            child: notifVM.notifications.isEmpty
                ? const Center(child: Text("Henüz bildirim yok."))
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 20),
                    itemCount: notifVM.notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifVM.notifications[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(notif.status),
                            child: Icon(
                              notif.type == "acil" ? Icons.warning : Icons.notifications, 
                              color: Colors.white, 
                              size: 18
                            ),
                          ),
                          title: Text(notif.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Tür: ${notif.type.toUpperCase()}"),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(notif.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              notif.status, 
                              style: TextStyle(color: _getStatusColor(notif.status), fontSize: 10, fontWeight: FontWeight.bold)
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("📝 Açıklama: ${notif.description}", style: const TextStyle(height: 1.4)),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text("Bildiren: ${notif.createdByName}", style: const TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                  const Divider(height: 30),
                                  const Text("DURUMU GÜNCELLE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey)),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _statusButton(context, notif.notifId!, "aktif", Colors.green, "AÇIK"),
                                      _statusButton(context, notif.notifId!, "inceleniyor", Colors.orange, "İNCELE"),
                                      _statusButton(context, notif.notifId!, "pasif", Colors.grey, "KAPAT"),
                                    ],
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Durum Değiştirme Butonları (Gereksinim 6)
  Widget _statusButton(BuildContext context, String id, String status, Color color, String label) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color, 
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16)
      ),
      onPressed: () {
        context.read<NotificationViewModel>().updateNotificationStatus(id, status);
      },
      child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  // Acil Durum Yayınlama Modülü (Gereksinim 6)
  Widget _buildEmergencyQuickPost(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border(bottom: BorderSide(color: Colors.red.shade100)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.campaign, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text("ACİL DURUM MODÜLÜ", style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
              ),
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => const AddNewNotificationPage())
                );
              },
              child: const Text("YENİ ACİL DUYURU YAYINLA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "aktif": return Colors.green;
      case "inceleniyor": return Colors.orange;
      default: return Colors.blueGrey;
    }
  }
}