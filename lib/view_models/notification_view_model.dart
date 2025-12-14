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
}
