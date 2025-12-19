import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<NotificationModel> notifications = [];

  NotificationViewModel() {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    final snapshot = await _firestore
        .collection('notifications')
        .orderBy('date', descending: true)
        .get();

    notifications = snapshot.docs
        .map((doc) =>
        NotificationModel.fromMap(doc.data(), doc.id))
        .toList();

    notifyListeners();
  }

  Future<void> addNotification(NotificationModel notification) async {
    await _firestore
        .collection('notifications')
        .add(notification.toMap());

    // 🔥 ekledikten sonra listeyi yenile
    await fetchNotifications();
  }
  Future<void> toggleFollowNotification(String notificationId, String userId) async {
    final docRef = _firestore.collection('notifications').doc(notificationId);
    final doc = await docRef.get();
    
    if (doc.exists) {
      List followers = doc.data()?['followers'] ?? [];
      
      if (followers.contains(userId)) {
        // Zaten takip ediyorsa listeden çıkar (Takibi Bırak)
        await docRef.update({
          'followers': FieldValue.arrayRemove([userId])
        });
      } else {
        // Takip etmiyorsa listeye ekle (Takip Et)
        await docRef.update({
          'followers': FieldValue.arrayUnion([userId])
        });
      }
      // Yerel listeyi güncellemek için tekrar çek
      await fetchNotifications();
    }
  }

  // 🔥 2. Sadece Takip Edilen Bildirimleri Getiren Getter
  // Profil sayfasında bu listeyi kullanacağız.
  List<NotificationModel> getFollowedNotifications(String userId) {
    return notifications.where((notif) {
      // NotificationModel içinde 'followers' listesi olduğunu varsayıyoruz
      // Eğer modelinizde yoksa, model dosyanıza da 'followers' eklemelisiniz.
      return notif.followers.contains(userId);
    }).toList();
  }

  // Belirli bir bildirimin durumunu (status) güncellemek için
Future<void> updateNotificationStatus(String notificationId, String newStatus) async {
  try {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'status': newStatus});

    // Yerel listedeki durumu da anında güncelle ki arayüz yenilensin
    final index = notifications.indexWhere((n) => n.notifId == notificationId);
    if (index != -1) {
      notifications[index].status = newStatus;
      notifyListeners();
    }
  } catch (e) {
    debugPrint("Durum güncelleme hatası: $e");
  }
}
}
