import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<NotificationModel> notifications = [];

  // Firestore dinleme
  void listenNotifications() {
    _service.getNotifications().listen((data) {
      notifications = data;
      notifyListeners();
    });
  }

  // Bildirim ekleme
  Future<void> addNotification(NotificationModel model) async {
    await _service.addNotification(model);
  }

  // Tek bildirim alma
  Future<NotificationModel?> getNotification(String docId) async {
    return await _service.getNotification(docId);
  }

  // Güncelleme
  Future<void> updateNotification(String docId, Map<String, dynamic> data) async {
    await _service.updateNotification(docId, data);
  }

  // Silme
  Future<void> deleteNotification(String docId) async {
    await _service.deleteNotification(docId);
  }
}
