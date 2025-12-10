import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Yeni bildirim ekleme
  Future<void> addNotification(NotificationModel notification) async {
    await _db.collection('notifications').add(notification.toMap());
  }

  // Tüm bildirimleri çekme (canlı dinleme)
  Stream<List<NotificationModel>> getNotifications() {
    return _db
        .collection('notifications')
        .orderBy("date", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // Tek bildirim alma
  Future<NotificationModel?> getNotification(String docId) async {
    var snap = await _db.collection('notifications').doc(docId).get();
    if (snap.exists) {
      return NotificationModel.fromMap(snap.data()!, snap.id);
    }
    return null;
  }

  // Bildirim güncelleme
  Future<void> updateNotification(String docId, Map<String, dynamic> data) async {
    await _db.collection('notifications').doc(docId).update(data);
  }

  // Bildirim silme
  Future<void> deleteNotification(String docId) async {
    await _db.collection('notifications').doc(docId).delete();
  }
}
