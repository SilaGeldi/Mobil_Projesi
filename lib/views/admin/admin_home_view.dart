import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../view_models/notification_view_model.dart';
import '../../models/notification_model.dart';
import '../main/add_new_notif_page.dart';
import '../main/notification_detail_page.dart'; // ✅ Detay sayfası import

class AdminHomeView extends StatefulWidget {
  const AdminHomeView({super.key});

  @override
  State<AdminHomeView> createState() => _AdminHomeViewState();
}

class _AdminHomeViewState extends State<AdminHomeView> {
  String selectedStatus = "Hepsi"; // "Hepsi", "aktif", "pasif", "inceleniyor"
  String selectedType = "Hepsi";   // "Hepsi", "acil", "duyuru", "guvenlik", "kayip", ...

  /// ✅ Home/Map ile uyumlu type normalizasyonu
  /// "Güvenlik" -> "guvenlik", "Teknik Arıza" -> "teknikariza" vb.
  String _normType(String t) {
    final lower = t.toLowerCase().trim();
    return lower
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c');
  }

  @override
  Widget build(BuildContext context) {
    final notifVM = Provider.of<NotificationViewModel>(context);

    // ✅ Filtrelenmiş bildirim listesi
    final filtered = notifVM.notifications.where((n) {
      final matchesStatus =
          selectedStatus == "Hepsi" || n.status == selectedStatus;

      // ✅ type karşılaştırması normalize edildi
      final matchesType =
          selectedType == "Hepsi" || _normType(n.type) == selectedType;

      return matchesStatus && matchesType;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        title: const Text("Admin Yönetim Paneli"),
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // ✅ ACİL DURUM MODÜLÜ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.campaign, color: Colors.red.shade700),
                    const SizedBox(width: 6),
                    Text(
                      "ACİL DURUM MODÜLÜ",
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const AddNewNotificationPage(isEmergency: true),
                        ),
                      );
                    },
                    child: const Text(
                      "YENİ ACİL DUYURU YAYINLA",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Filtre Barı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      labelText: "Filtre: Durum",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: const ["Hepsi", "aktif", "pasif", "inceleniyor"]
                        .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => selectedStatus = v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: InputDecoration(
                      labelText: "Filtre: Tür",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),

                    // ✅ Buradaki value’ları da normalize/tek standarda çektim
                    items: const [
                      "Hepsi",
                      "acil",
                      "duyuru",
                      "guvenlik",
                      "kayip",
                      "saglik",
                      "teknikariza",
                      "cevre",
                      "diger",
                    ].map((t) {
                      // Ekranda büyük yazsın diye:
                      final label = (t == "Hepsi") ? "HEPSİ" : t.toUpperCase();
                      return DropdownMenuItem(value: t, child: Text(label));
                    }).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => selectedType = v);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Liste
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text("Bildirim yok"))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final notif = filtered[index];
                return _AdminNotifTile(notif: notif);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminNotifTile extends StatelessWidget {
  final NotificationModel notif;
  const _AdminNotifTile({required this.notif});

  String _normType(String t) {
    final lower = t.toLowerCase().trim();
    return lower
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c');
  }

  @override
  Widget build(BuildContext context) {
    final isEmergency = (_normType(notif.type) == "acil");

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isEmergency ? Colors.red.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEmergency ? Colors.red.shade200 : Colors.grey.shade300,
        ),
      ),
      child: ListTile(
        // ✅ İŞTE EKSİK OLAN BU: tıklayınca detaya git
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NotificationDetailPage(notification: notif),
            ),
          );
        },

        leading: CircleAvatar(
          backgroundColor: isEmergency ? Colors.red.shade700 : Colors.orange,
          child: Icon(
            isEmergency ? Icons.warning_amber : Icons.notifications,
            color: Colors.white,
          ),
        ),
        title: Text(
          notif.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isEmergency ? Colors.red.shade900 : Colors.black,
          ),
        ),
        subtitle: Text("Tür: ${notif.type.toUpperCase()}"),
        trailing: const Icon(Icons.chevron_right), // ✅ Detaya gittiği belli olsun
      ),
    );
  }
}
