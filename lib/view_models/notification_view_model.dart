import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<NotificationModel> notifications = [];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  NotificationViewModel() {
    _listenNotifications(); // ✅ Real-time dinleme
  }

  /// ✅ Firestore'u canlı dinler (admin değiştirince user tarafı otomatik güncellenir)
  void _listenNotifications() {
    _sub?.cancel();
    _sub = _firestore
        .collection('notifications')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
      notifications = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
          .toList();

      notifyListeners();
    });
  }

  /// Eski fetch'i de bırakıyorum (istersen manuel çağırırsın)
  Future<void> fetchNotifications() async {
    final snapshot = await _firestore
        .collection('notifications')
        .orderBy('date', descending: true)
        .get();

    notifications = snapshot.docs
        .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
        .toList();

    notifyListeners();
  }

  Future<void> addNotification(NotificationModel notification) async {
    await _firestore.collection('notifications').add(notification.toMap());
    // ✅ snapshots zaten güncelleyecek; ekstra fetch zorunlu değil.
  }

  Future<void> toggleFollowNotification(String notificationId, String userId) async {
    final docRef = _firestore.collection('notifications').doc(notificationId);
    final doc = await docRef.get();

    if (!doc.exists) return;

    final List followers = (doc.data()?['followers'] ?? []) as List;

    if (followers.contains(userId)) {
      await docRef.update({'followers': FieldValue.arrayRemove([userId])});
    } else {
      await docRef.update({'followers': FieldValue.arrayUnion([userId])});
    }
    // ✅ snapshots zaten güncelleyecek
  }

  List<NotificationModel> getFollowedNotifications(String userId) {
    return notifications.where((n) => n.followers.contains(userId)).toList();
  }

  Future<void> updateNotificationStatus(String notificationId, String newStatus) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({'status': newStatus});
      // ✅ snapshots zaten güncelleyecek
    } catch (e) {
      debugPrint("Durum güncelleme hatası: $e");
    }
  }

  Future<void> updateNotificationDescription(String id, String newDesc) async {
    await _firestore.collection('notifications').doc(id).update({'description': newDesc});
    // ✅ snapshots zaten güncelleyecek
  }

  Future<void> deleteNotification(String id) async {
    await _firestore.collection('notifications').doc(id).delete();
    // ✅ snapshots zaten güncelleyecek
  }

  List<NotificationModel> getAdminFilteredNotifications(String adminUnit) {
    return notifications.where((n) => n.type == adminUnit.toLowerCase()).toList();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
