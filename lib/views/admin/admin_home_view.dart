// Admin ana sayfası: yöneticinin duyuruları görüntüleyip yönetebildiği ekran.
// Bu dosya içinde temel yapı: arama, filtreleme, listeleme, yeni bildirim ekleme ve
// her bir bildirimin admin tarafından düzenlenebilmesi (durum/değişiklik/silme) yer alır.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ViewModel'ler: kullanıcı bilgisi ve bildirim listesini almak için
import '../../view_models/auth_view_model.dart';
import '../../view_models/notification_view_model.dart';
import '../../models/notification_model.dart';
import '../main/add_new_notif_page.dart';

// Stateful widget: arama, filtre seçimi gibi kullanıcı etkileşimleri state değiştirir
class AdminHomeView extends StatefulWidget {
  const AdminHomeView({super.key});

  @override
  State<AdminHomeView> createState() => _AdminHomeViewState();
}

class _AdminHomeViewState extends State<AdminHomeView> {
  // Arama çubuğuna girilen metin burada tutulur
  String searchQuery = "";

  // Filtreler: seçili durum ve seçili tür (null ise filtre uygulanmıyor)
  String? selectedStatus;
  String? selectedType;

  // Sadece takip edilenleri gösterme seçeneği
  bool showOnlyFollowed = false;

  @override
  Widget build(BuildContext context) {
    // ViewModel'leri context üzerinden dinliyoruz; değişiklik olursa build tetiklenir
    final notifVM = context.watch<NotificationViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final userId = authVM.currentUser?.uid; // Şu anki admin kullanıcı id'si

    // Bildirimlerin filtrelenmesi: arama, durum, tür ve takip kontrolü
    final notifications = notifVM.notifications.where((n) {
      // Arama kriteri: başlık veya açıklama içinde aranan metin var mı
      final matchesSearch =
          n.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
              n.description.toLowerCase().contains(searchQuery.toLowerCase());

      // Durum filtresi: selectedStatus boşsa tüm durumlar geçerli
      final matchesStatus =
          selectedStatus == null || n.status.toLowerCase() == selectedStatus;

      // Tür filtresi: selectedType boşsa tüm türler geçerli
      final matchesType =
          selectedType == null || n.type.toLowerCase() == selectedType;

      // Takip edilen filtresi: showOnlyFollowed false ise tüm öğeler geçerli,
      // true ise sadece kullanıcının follow listesinde olanlar kalır
      final matchesFollowed =
          !showOnlyFollowed || (userId != null && n.followers.contains(userId));

      // Tüm filtreler sağlanıyorsa göster
      return matchesSearch && matchesStatus && matchesType && matchesFollowed;
    }).toList();

    // Sayfa gövdesi
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Duyurular"),
        actions: [
          // Acil duyuru yayınlama butonu: farklı bir sayfaya yönlendirir
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddNewNotificationPage(isEmergency: true),
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

      // Yeni bildirim eklemek için FAB (floating action button)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddNewNotificationPage(isEmergency: false),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),

      // Ana alan: arama çubuğu, filtre butonu ve liste
      body: Column(
        children: [
          // Üstte arama ve filtre satırı
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Arama metni inputu
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Ara...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // Kullanıcı yazdıkça state güncellenir ve liste filtrelenir
                    onChanged: (v) => setState(() => searchQuery = v),
                  ),
                ),
                const SizedBox(width: 8),

                // Filtre açma butonu; ikon rengi seçili filtreye göre değişir
                IconButton(
                  icon: Icon(
                    Icons.filter_list,
                    color: (selectedStatus != null || selectedType != null || showOnlyFollowed)
                        ? Colors.deepPurple
                        : Colors.grey,
                  ),
                  onPressed: () => _showFilterBottomSheet(context),
                ),
              ],
            ),
          ),

          // Bildirim listesi: filtre sonucu boşsa bilgi göster, değilse listelenir
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

  // Tek bir bildirim kartını oluşturur. Kart tıklanınca admin düzenleme modalı açılır.
  Widget _notificationCard(BuildContext context, NotificationModel notif, String? userId) {
    final notifVM = context.read<NotificationViewModel>();
    // Kullanıcının bu bildirimi takip edip etmediğini kontrol et
    final isFollowing = userId != null && notif.followers.contains(userId);

    return GestureDetector(
      // Kart tıklanınca düzenleme modalı aç
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
                // Başlık
                Expanded(
                  child: Text(
                    notif.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),

                // Takip et / takibi bırak butonu (sadece simge değişir)
                IconButton(
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
              ],
            ),

            const SizedBox(height: 6),

            // Açıklama: kısaltılmış gösterim
            Text(notif.description, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),

            // Alt satır: durum ve tür etiketleri
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

  // Admin için düzenleme modalı: açıklama düzenleme, durum değiştirme, kaydetme ve silme
  void _openAdminBottomSheet(NotificationModel notif) {
    // Varsayılan olarak mevcut açıklamayı controller'a koy
    final descController = TextEditingController(text: notif.description);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          // Klavye açıldığında modal içeriğinin görünmesi için alt padding ekliyoruz
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
              // Başlık
              Text(notif.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),

              // Oluşturan bilgisi: eğer boş geliyorsa uyarı metni gösterir
              Text(
                "👤 ${notif.createdByName.isEmpty ? 'BOŞ GELİYOR' : notif.createdByName}",
                style: const TextStyle(color: Colors.red),
              ),

              const SizedBox(height: 12),

              // Açıklama düzenleme alanı
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Açıklama", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              // Durum seçenekleri: seçim yapıldığında anında view model'e güncelleme gönderiliyor
              Wrap(
                spacing: 8,
                children: ["Açık", "İnceleniyor", "Çözüldü"].map((s) {
                  return ChoiceChip(
                    label: Text(s),
                    selected: notif.status.toLowerCase() == s.toLowerCase(),
                    onSelected: (_) {
                      context.read<NotificationViewModel>().updateNotificationStatus(notif.notifId!, s.toLowerCase());
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Kaydet ve Sil butonları yan yana
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("Kaydet"),
                      onPressed: () {
                        // Açıklamayı güncelle ve modalı kapat
                        context.read<NotificationViewModel>().updateNotificationDescription(notif.notifId!, descController.text);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text("Sil"),
                      onPressed: () {
                        // Bildirimi sil ve modalı kapat
                        context.read<NotificationViewModel>().deleteNotification(notif.notifId!);
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

  // Filtre modalı: durum, tür ve sadece takip ettiklerim seçeneğini gösterir
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

                // Sadece Takip Ettiklerim filtre seçeneği
                FilterChip(
                  label: const Text("Sadece Takip Ettiklerim"),
                  selected: showOnlyFollowed,
                  onSelected: (val) {
                    setState(() => showOnlyFollowed = val);
                    setModalState(() {});
                  },
                ),
                const SizedBox(height: 15),

                // Durum seçenekleri: burada map içindeki değerlerle karşılaştırma yapılır
                Wrap(
                  spacing: 8,
                  children: const [
                    {"label": "Açık", "value": "açık"},
                    {"label": "İnceleniyor", "value": "incelleniyor"},
                    {"label": "Çözüldü", "value": "çözüldü"},
                  ].map((s) {
                    return ChoiceChip(
                      label: Text(s["label"]!),
                      selected: selectedStatus == s["value"],
                      onSelected: (val) {
                        setState(() {
                          selectedStatus = val ? s["value"] : null;
                        });
                        setModalState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Tür seçenekleri: acil, sağlık, kayıp vb.
                Wrap(
                  spacing: 8,
                  children: const [
                    {"label": "Acil Duyuru", "value": "acil"},
                    {"label": "Sağlık", "value": "saglik"},
                    {"label": "Kayıp", "value": "kayip"},
                    {"label": "Güvenlik", "value": "guvenlik"},
                    {"label": "Duyuru", "value": "duyuru"},
                    {"label": "Çevre", "value": "cevre"},
                    {"label": "Teknik Arıza", "value": "teknikariza"},
                    {"label": "Diğer", "value": "diger"},
                  ].map((t) {
                    return ChoiceChip(
                      label: Text(t["label"]!),
                      selected: selectedType == t["value"],
                      onSelected: (val) {
                        setState(() {
                          selectedType = val ? t["value"] : null;
                        });
                        setModalState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Uygula")),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // Küçük etiket (chip) widget'ı: metin ve renk alır, tasarım tutarlılığı sağlar
  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  // Duruma göre renk döndüren yardımcı fonksiyon
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