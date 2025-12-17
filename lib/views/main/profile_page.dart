import 'package:akilli_kampus_proje/view_models/notification_view_model.dart';
import 'package:akilli_kampus_proje/views/auth/login_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/auth_view_model.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthViewModel'e erişiyoruz
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = authViewModel.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil ve Ayarlar"),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Profil Bilgileri Bölümü (Gereksinim 7)
                  Center(
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.deepPurple,
                          child: Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          user.name,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 5),
                        Chip(
                          label: Text(user.role.toUpperCase()),
                          backgroundColor: user.role == "admin" ? Colors.red[100] : Colors.blue[100],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  const Text("Kurum Bilgileri", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.business),
                    title: const Text("Birim / Bölüm"),
                    subtitle: Text(user.unit),
                  ),
                  const Divider(),

                  // 2. Bildirim Ayarları (Gereksinim 7)
                  const Text("Bildirim Tercihleri", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  // Sağlık ve Güvenlik Switch'i
SwitchListTile(
  contentPadding: EdgeInsets.zero,
  title: const Text("Sağlık ve Güvenlik"),
  // null safety için ünlem veya varsayılan değer kullanıyoruz
  value: user.preferences['health'] ?? true, 
  onChanged: (val) {
    authViewModel.updateNotificationPreference('health', val);
  },
),

// Teknik Arızalar Switch'i
SwitchListTile(
  contentPadding: EdgeInsets.zero,
  title: const Text("Teknik Arızalar"),
  value: user.preferences['technical'] ?? true,
  onChanged: (val) {
    authViewModel.updateNotificationPreference('technical', val);
  },
),
                  const Divider(),

                  // 3. Takip Edilen Bildirimler
                 // ProfilePage içindeki Takip Edilenler ListTile'ı için yönlendirme mantığı:

ListTile(
  contentPadding: EdgeInsets.zero,
  leading: const Icon(Icons.bookmark_outline),
  title: const Text("Takip Ettiğim Bildirimler"),
  // Takip edilen bildirim sayısını göstermek için:
  trailing: CircleAvatar(
    radius: 12,
    backgroundColor: Colors.deepPurple,
    child: Text(
      context.read<NotificationViewModel>().getFollowedNotifications(user!.uid).length.toString(),
      style: const TextStyle(fontSize: 12, color: Colors.white),
    ),
  ),
  onTap: () {
    // Burada yeni bir sayfaya yönlendirebiliriz veya 
    // bir ModalBottomSheet açıp listeyi gösterebiliriz.
    _showFollowedNotifications(context, user.uid);
  },
),
                  const SizedBox(height: 30),

                  // 4. Çıkış Yap (Gereksinim 7)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await authViewModel.signOut();
                         Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const LoginView()),
                      );
                        // SignOut sonrası AuthViewModel'deki notifyListeners() tetiklenir
                        // Eğer main.dart'ta StreamBuilder veya Consumer varsa otomatik Login'e atar.
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
  
  void _showFollowedNotifications(BuildContext context, String uid) {
    showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      // NotificationViewModel'i dinliyoruz
      return Consumer<NotificationViewModel>(
        builder: (context, notificationVM, child) {
          final followedList = notificationVM.getFollowedNotifications(uid);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Takip Ettiğim Bildirimler",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                followedList.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text("Henüz takip ettiğiniz bir bildirim yok."),
                      )
                    : Expanded(
                        child: ListView.builder(
                          itemCount: followedList.length,
                          itemBuilder: (context, index) {
                            final item = followedList[index];
                            return ListTile(
                              leading: const Icon(Icons.info_outline, color: Colors.deepPurple),
                              title: Text(item.title),
                              subtitle: Text("Durum: ${item.status}"),
                              trailing: IconButton(
                                icon: const Icon(Icons.bookmark_remove, color: Colors.red),
                                onPressed: () {
                                  // Takibi bırakma işlemi
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
  }
  
}

