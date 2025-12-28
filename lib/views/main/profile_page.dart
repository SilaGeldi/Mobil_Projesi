// Profile ve ayarlar sayfası: kullanıcı bilgilerini, tercihlerini ve takip ettikleri bildirimleri gösterir.
// Aşağıda kullanılan importlar ve her birinin kısaca ne işe yaradığı yorum satırlarıyla belirtilmiştir.
import 'package:akilli_kampus_proje/view_models/notification_view_model.dart'; // Takip edilen bildirimlerin listesini sağlayan view model
import 'package:akilli_kampus_proje/views/auth/login_view.dart'; // Çıkış sonrası yönlendirilecek Login ekranı
import 'package:flutter/material.dart'; // Flutter UI bileşenleri
import 'package:provider/provider.dart'; // State management için Provider
import '../../view_models/auth_view_model.dart'; // Kullanıcı bilgileri ve güncelleme fonksiyonları

// Stateless widget: profil sayfası, kullanıcı bilgilerini okur ve ayarları değiştirir.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthViewModel üzerinden şu anki kullanıcı bilgisine erişiyoruz.
    // Bu nesne kullanıcı adı, email, role, unit ve preferences gibi alanları içerir.
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = authViewModel.currentUser;

    // Scaffold: sayfanın temel yapısı (AppBar ve body içerir)
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil ve Ayarlar"),
        centerTitle: true,
      ),
      // Eğer kullanıcı bilgisi yoksa yükleniyor göstergesi göster; varsa içerikleri göster
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1) Profil Bilgileri bölümü
                  // Merkezde avatar, isim, email ve rol gösterilir.
                  Center(
                    child: Column(
                      children: [
                        // Avatar: basit ikon kullanılmış, gerçek projede kullanıcı fotoğrafı konulabilir.
                        const CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.deepPurple,
                          child: Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        // Kullanıcı adı
                        Text(
                          user.name,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        // Kullanıcı e-posta
                        Text(
                          user.email,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 5),
                        // Rol etiketi: admin ise kırmızı, diğerleri için mavi ton
                        Chip(
                          label: Text(user.role.toUpperCase()),
                          backgroundColor: user.role == "admin" ? Colors.red[100] : Colors.blue[100],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Kurum Bilgileri: birim / bölüm bilgisi gösterilir
                  const Text("Kurum Bilgileri", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.business),
                    title: const Text("Birim / Bölüm"),
                    subtitle: Text(user.unit),
                  ),
                  const Divider(),

                  // 2) Bildirim Tercihleri
                  // Burada kullanıcının hangi tür bildirimleri almak istediği ayarlanır.
                  const Text("Bildirim Tercihleri", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  // Sağlık ve Güvenlik tercihi: switch ile yönetilir
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Sağlık ve Güvenlik"),
                    // Eğer map içerisinde değer yoksa varsayılan true kabul edilir
                    value: user.preferences['health'] ?? true,
                    onChanged: (val) {
                      // Değişiklik view model üzerinden kalıcı olarak kaydedilir
                      authViewModel.updateNotificationPreference('health', val);
                    },
                  ),

                  // Teknik arızalar tercihi
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Teknik Arızalar"),
                    value: user.preferences['technical'] ?? true,
                    onChanged: (val) {
                      authViewModel.updateNotificationPreference('technical', val);
                    },
                  ),
                  const Divider(),

                  // 3) Takip Edilen Bildirimler
                  // Burada kullanıcı tarafından takip edilen bildirimlerin sayısını gösteririz.
                  // Consumer kullanarak NotificationViewModel'deki değişiklikleri dinliyoruz,
                  // böylece takip listesi güncellendiğinde sayı anında değişir.
                  Consumer<NotificationViewModel>(
                    builder: (context, notificationVM, child) {
                      // view model üzerinden kullanıcının takip ettikleri alınır
                      final followedCount = notificationVM.getFollowedNotifications(user.uid).length;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.bookmark_outline),
                        title: const Text("Takip Ettiğim Bildirimler"),
                        // Sağ tarafta küçük bir daire içinde sayı gösterilir
                        trailing: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.deepPurple,
                          child: Text(
                            followedCount.toString(),
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                        onTap: () {
                          // Alt modal ile takip edilen bildirimler listesi gösterilir
                          _showFollowedNotifications(context, user.uid);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 30),

                  // 4) Çıkış Yap butonu
                  // PushAndRemoveUntil ile navigasyon yığını temizlenerek Login ekranına yönlendirilir
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await authViewModel.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const LoginView()),
                            (route) => false,
                          );
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text("Çıkış Yap"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Takip edilen bildirimleri gösteren alt modal
  void _showFollowedNotifications(BuildContext context, String uid) {
    // showModalBottomSheet ile ekranın altından kayan bir modal gösteriyoruz.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // İçerik NotificationViewModel'e bağlı olduğu için Consumer ile sarıyoruz
        return Consumer<NotificationViewModel>(
          builder: (context, notificationVM, child) {
            final followedList = notificationVM.getFollowedNotifications(uid);

            // DraggableScrollableSheet: kullanıcı modal'i yukarı çekip büyütebilir
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Küçük bir çubuğa benzer gösterge (modal başında)
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                      ),
                      const Text(
                        "Takip Ettiğim Bildirimler",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      // Eğer takip edilen yoksa bilgilendir; varsa listeyi göster
                      followedList.isEmpty
                          ? const Expanded(
                              child: Center(
                                child: Text("Henüz takip ettiğiniz bir bildirim yok."),
                              ),
                            )
                          : Expanded(
                              child: ListView.builder(
                                controller: scrollController,
                                itemCount: followedList.length,
                                itemBuilder: (context, index) {
                                  final item = followedList[index];
                                  // Her öğe için ListTile: başlık, durum ve takibi bırak butonu
                                  return ListTile(
                                    leading: const Icon(Icons.info_outline, color: Colors.deepPurple),
                                    title: Text(item.title),
                                    subtitle: Text("Durum: ${item.status}"),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.bookmark_remove, color: Colors.red),
                                      onPressed: () {
                                        // Takibi bırakma işlemi view model üzerinden yapılır
                                        notificationVM.toggleFollowNotification(item.notifId!, uid);
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}