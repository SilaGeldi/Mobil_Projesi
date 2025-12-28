// Bu sayfa bir bildirimin detaylarını gösterir.
// Aşağıdaki importlar: temel UI, state yönetimi ve Firestore tipi için gerekli.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Uygulama içi modeller ve view model'ler
import '../../models/notification_model.dart';
import '../../view_models/notification_view_model.dart';
import '../../view_models/auth_view_model.dart';

// Harita görünümüne gidebilmek için MapView import ediliyor.
// Eğer proje yapında map_view farklı konumdaysa bu yolu düzelt.
import '../main/map_view.dart';

class NotificationDetailPage extends StatelessWidget {
  // Detayı gösterilecek bildirim nesnesi dışarıdan alınır (required).
  final NotificationModel notification;

  const NotificationDetailPage({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    // ViewModel'leri alıyoruz. Burada bildirim listesi ve kullanıcı bilgilerine ihtiyacımız var.
    final notifVM = Provider.of<NotificationViewModel>(context);
    final authVM = Provider.of<AuthViewModel>(context);
    // Giriş yapmış kullanıcının uid'si (varsa)
    final userId = authVM.currentUser?.uid;

    // ViewModel'deki güncel bildirim listesinde aynı id'ye sahip öğeyi arıyoruz.
    // Böylece takip edenler listesi gibi anlık güncellemeler yansır.
    final currentNotif = notifVM.notifications.firstWhere(
      (n) => n.notifId == notification.notifId,
      orElse: () => notification,
    );

    // Bu kullanıcı bu bildirimi takip ediyor mu? (bookmark gibi)
    final isFollowing = userId != null && currentNotif.followers.contains(userId);

    // Scaffold: sayfanın temel iskeleti (AppBar + body)
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // Başlık ve stil: siyah text, beyaz arka plan, gölgesiz
        title: const Text("Bildirim Detayı", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // Takip et / takibi bırak butonu: ikona göre renk ve ikon değişir.
          IconButton(
            icon: Icon(
              isFollowing ? Icons.bookmark : Icons.bookmark_border,
              color: isFollowing ? Colors.deepPurple : Colors.grey,
            ),
            onPressed: () {
              // Kullanıcı girişliyse toggle işlemini view model'e bildir
              if (userId != null && currentNotif.notifId != null) {
                notifVM.toggleFollowNotification(currentNotif.notifId!, userId);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      // İçerik: başlık, açıklama, detay kartı ve haritada göster butonu
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üstte tip etiketi ve tarih gösterimi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tür etiket kutusu (ör. ACIL, DUYURU)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    // Türü büyük harfle göster
                    currentNotif.type.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),

                // Sağda bildirimin tam tarihi
                Text(
                  _formatFullDate(currentNotif.date),
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Bildirim başlığı (büyük ve kalın)
            Text(
              currentNotif.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const Divider(height: 40, thickness: 1),

            // Açıklama başlığı ve içeriği
            const Text(
              "Açıklama",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 10),
            // Açıklamanın kendisi: paragraf olarak gösterilir
            Text(
              currentNotif.description,
              style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
            ),

            const SizedBox(height: 30),

            // Bilgi kartı: içinde durum, oluşturan ve konum bilgileri yer alır
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // Durum satırı: açık / inceleniyor / çözüldü
                  _buildDetailRow(
                    Icons.info_outline,
                    "Durum",
                    currentNotif.status,
                    _statusColor(currentNotif.status),
                  ),
                  const Divider(height: 24),

                  // Oluşturan kişi adı
                  _buildDetailRow(
                    Icons.person_outline,
                    "Oluşturan",
                    currentNotif.createdByName,
                    Colors.black87,
                  ),
                  const Divider(height: 24),

                  // Konum satırı: enlem, boylam formatında kısaltılmış
                  _buildDetailRow(
                    Icons.location_on_outlined,
                    "Konum",
                    "${currentNotif.location.latitude.toStringAsFixed(4)}, ${currentNotif.location.longitude.toStringAsFixed(4)}",
                    Colors.blue,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Haritada Görüntüle butonu: butona basınca MapView'e gider ve o bildirime odaklanır
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigator ile yeni sayfaya git, MapView'e focusNotification gönder
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapView(
                        focusNotification: currentNotif,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.map, color: Colors.white),
                label: const Text(
                  "HARİTADA GÖRÜNTÜLE",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
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

  // Yardımcı: detay satırı oluşturur (ikon + başlık + değer)
  Widget _buildDetailRow(IconData icon, String title, String value, Color valueColor) {
    return Row(
      children: [
        // Sol tarafta ikon
        Icon(icon, color: Colors.grey, size: 24),
        const SizedBox(width: 16),
        // Sağında başlık küçük, değer ise kalın ve renkli
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(
              value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: valueColor),
            ),
          ],
        ),
      ],
    );
  }

  // Durum metnine göre renk döndürür. Küçük harfe çevirerek karşılaştırma yapar.
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

  // Timestamp'i okunabilir tam tarih-saat formatına çevirir: GG.AA.YYYY SS:DD
  String _formatFullDate(Timestamp ts) {
    final d = ts.toDate();
    return "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} "
        "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
  }
}
