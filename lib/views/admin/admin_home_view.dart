import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/notification_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../main/add_new_notif_page.dart';
import '../../models/notification_model.dart';

class AdminHomeView extends StatefulWidget {
  const AdminHomeView({super.key});

  @override
  State<AdminHomeView> createState() => _AdminHomeViewState();
}

class _AdminHomeViewState extends State<AdminHomeView> {
  
  String _selectedFilter = "Hepsi"; 

  @override
  Widget build(BuildContext context) {
    final notifVM = Provider.of<NotificationViewModel>(context);
    final authVM = Provider.of<AuthViewModel>(context);
    final user = authVM.currentUser;

    List<NotificationModel> displayList = notifVM.notifications;

    if (_selectedFilter == "Açık") {
      displayList = displayList.where((n) => n.status == "aktif").toList();
    } else if (_selectedFilter == "Birimim") {
      displayList = displayList.where((n) => 
        n.type.toLowerCase() == user?.unit.toLowerCase()).toList();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Admin Yönetim Paneli"),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: const [], // Çıkış butonu kaldırıldı
      ),
      body: Column(
        children: [
          _buildEmergencyQuickPost(context),
          
          // Filtre İkonu Satırı
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            color: Colors.grey.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Filtre: $_selectedFilter",
                  style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.tune, color: Colors.red),
                  onSelected: (String value) {
                    setState(() {
                      _selectedFilter = value;
                    });
                  },
                  itemBuilder: (BuildContext context) => <String>['Hepsi', 'Açık', 'Birimim']
                      .map((String choice) => PopupMenuItem<String>(
                            value: choice,
                            child: Text(choice),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            color: Colors.grey.shade100,
            child: Text(
              "Bildirimler (${displayList.length})", 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54),
            ),
          ),
          
          Expanded(
            child: displayList.isEmpty
                ? const Center(child: Text("Eşleşen bildirim bulunamadı."))
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 20),
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      final notif = displayList[index];
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
                          trailing: const Icon(Icons.keyboard_arrow_down),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("DURUM:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                      Text(notif.status.toUpperCase(), style: TextStyle(color: _getStatusColor(notif.status), fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text("📝 Açıklama: ${notif.description}", style: const TextStyle(height: 1.4)),
                                  const SizedBox(height: 12),
                                  Text("👤 Bildiren: ${notif.createdByName}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  const Divider(height: 30),
                                  
                                  const Text("YÖNETİM İŞLEMLERİ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey)),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () => _showEditDescriptionDialog(context, notif),
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        tooltip: "Açıklamayı Düzenle",
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        onPressed: () => _showDeleteConfirmDialog(context, notif.notifId!),
                                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                                        tooltip: "Bildirimi Sonlandır",
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 30),
                                  
                                  const Text("DURUMU DEĞİŞTİR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey)),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _statusButton(context, notif.notifId!, "aktif", Colors.green, "Açık"),
                                      _statusButton(context, notif.notifId!, "inceleniyor", Colors.orange, "İnceleniyor"),
                                      _statusButton(context, notif.notifId!, "pasif", Colors.grey, "Çözüldü"),
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

  void _showEditDescriptionDialog(BuildContext context, NotificationModel notif) {
    final controller = TextEditingController(text: notif.description);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Açıklamayı Düzenle"),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Yeni açıklama girin..."),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () {
              context.read<NotificationViewModel>().updateNotificationDescription(notif.notifId!, controller.text);
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
      builder: (context) => AlertDialog(
        title: const Text("Bildirimi Sil"),
        content: const Text("Bu bildirimi sistemden tamamen kaldırmak istediğinize emin misiniz? Bu işlem geri alınamaz."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<NotificationViewModel>().deleteNotification(id);
              Navigator.pop(context);
            },
            child: const Text("Evet, Sil", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

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