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

                  // 3. Takip Edilen Bildirimler (Gereksinim 7)
                  // 🔥 Consumer eklenerek sayının anlık güncellenmesi sağlandı
                  Consumer<NotificationViewModel>(
                    builder: (context, notificationVM, child) {
                      final followedCount = notificationVM.getFollowedNotifications(user.uid).length;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.bookmark_outline),
                        title: const Text("Takip Ettiğim Bildirimler"),
                        trailing: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.deepPurple,
                          child: Text(
                            followedCount.toString(),
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                        onTap: () {
                          _showFollowedNotifications(context, user.uid);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 30),

                  // 4. Çıkış Yap (Gereksinim 7)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await authViewModel.signOut();
                        // 🔥 Navigasyon geçmişi temizlenerek Login ekranına yönlendirilir
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

  void _showFollowedNotifications(BuildContext context, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<NotificationViewModel>(
          builder: (context, notificationVM, child) {
            final followedList = notificationVM.getFollowedNotifications(uid);

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
                                  return ListTile(
                                    leading: const Icon(Icons.info_outline, color: Colors.deepPurple),
                                    title: Text(item.title),
                                    subtitle: Text("Durum: ${item.status}"),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.bookmark_remove, color: Colors.red),
                                      onPressed: () {
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