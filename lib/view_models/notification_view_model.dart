import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

// Bu ViewModel, uygulamadaki bildirimleri (notifications) yönetir.
// - Firestore koleksiyonunu dinler ve verileri `notifications` listesine yazar.
// - Kullanıcıların takip etme (follow) durumlarını değiştirme, bildirim ekleme,
//   silme ve güncelleme gibi işlemler burada toplanır.
// Not: Bu dosyaya sadece açıklayıcı yorumlar eklendi; kodun çalışmasına dokunulmadı.

class NotificationViewModel extends ChangeNotifier {
  // Firestore örneğine erişim. Bu değişken üzerinden DB işlemleri yapılır.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Uygulama içinde kullanılan bildirim listesi. Firestore'dan çekilen
  // veriler `NotificationModel` objelerine dönüştürülüp bu listede saklanır.
  List<NotificationModel> notifications = [];

  // Firestore realtime snapshot dinleyicisi için abonelik (subscription).
  // Uygulama kapatılırken veya ViewModel dispose edildiğinde iptal edilmelidir.
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  // Constructor: ViewModel yaratıldığında Firestore koleksiyonunu dinlemeye başlar.
  // Böylece admin panelinden veri değiştiğinde kullanıcı tarafı anında güncellenir.
  NotificationViewModel() {
    _listenNotifications(); // Real-time dinleme
  }

  /// Firestore'u canlı dinler (admin değiştirince user tarafı otomatik güncellenir)
  void _listenNotifications() {
    // Eğer daha önce bir abonelik varsa iptal et (çift dinlemeyi önlemek için).
    _sub?.cancel();

    // Firestore 'notifications' koleksiyonunu tarihe göre azalan sırada dinle.
    // snapshots() ile stream alıyoruz; listen ile her değişiklikte callback çalışır.
    _sub = _firestore
        .collection('notifications')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
      // Gelen snapshot içindeki dokümanları NotificationModel nesnelerine dönüştür.
      // doc.data() haritası ve doc.id birlikte kullanılarak model oluşturulur.
      notifications = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
          .toList();

      // Dinleyici bileşenleri bilgilendir: UI veya consumer'lar yeniden render olur.
      notifyListeners();
    });
  }

  Future<void> fetchNotifications() async {
    // Tek seferlik manuel veri çekme: Realtime dinlemeyi kullanmak istemediğimiz
    // durumlarda bu metodu çağırabiliriz (örn. refresh butonu).
    final snapshot = await _firestore
      .collection('notifications')
      .orderBy('date', descending: true)
      .get();

    // Aynı şekilde dönen dokümanları modele çevir ve listeyi güncelle.
    notifications = snapshot.docs
      .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
      .toList();

    // Dinleyicilere haber ver (UI güncellensin).
    notifyListeners();
  }

  Future<void> addNotification(NotificationModel notification) async {
    // Yeni bir bildirim ekle (admin tarafı için kullanılabilir).
    // toMap() modeldeki alanları Firestore'a uygun haritaya çevirir.
    await _firestore.collection('notifications').add(notification.toMap());
  }

  Future<void> toggleFollowNotification(String notificationId, String userId) async {
    // Kullanıcının bir bildirimi takip etme / takipten çıkarma işlemi.
    // Firestore'da her bildirim dokümanı içinde 'followers' adında bir dizi tutuluyor.
    final docRef = _firestore.collection('notifications').doc(notificationId);
    final doc = await docRef.get();

    // Doküman yoksa işlem yok (güvenlik).
    if (!doc.exists) return;

    // followers alanını oku; eğer yoksa boş liste al.
    final List followers = (doc.data()?['followers'] ?? []) as List;

    // Eğer kullanıcı zaten takip ediyorsa kaldır, değilse ekle.
    if (followers.contains(userId)) {
      await docRef.update({'followers': FieldValue.arrayRemove([userId])});
    } else {
      await docRef.update({'followers': FieldValue.arrayUnion([userId])});
    }
  }

  List<NotificationModel> getFollowedNotifications(String userId) {
    // Loaded notifications listesinden kullanıcının takip ettiklerini filtrele.
    // Bu, UI'da "Takip Ettiklerim" gibi bir liste göstermek için kullanılır.
    return notifications.where((n) => n.followers.contains(userId)).toList();
  }

  Future<void> updateNotificationStatus(String notificationId, String newStatus) async {
    // Bildirim durumunu güncelle (ör: 'open', 'closed', 'in-progress' gibi).
    try {
      await _firestore.collection('notifications').doc(notificationId).update({'status': newStatus});
    } catch (e) {
      // Hata durumunda debug logla. Production'ta kullanıcıya bilgi gösterilebilir.
      debugPrint("Durum güncelleme hatası: $e");
    }
  }

  Future<void> updateNotificationDescription(String id, String newDesc) async {
    // Bildirim açıklamasını güncelleme helper'ı.
    await _firestore.collection('notifications').doc(id).update({'description': newDesc});
   
  }

  Future<void> deleteNotification(String id) async {
    // Bildirimi sil (admin yetkisi gerektirebilir).
    await _firestore.collection('notifications').doc(id).delete();
  }

  List<NotificationModel> getAdminFilteredNotifications(String adminUnit) {
    // Admin arayüzünde birime göre filtreleme yaparken kullanılır.
    // Burada `type` alanı küçük harfe çevrilip adminUnit ile karşılaştırılır.
    return notifications.where((n) => n.type == adminUnit.toLowerCase()).toList();
  }

  @override
  void dispose() {
    // ViewModel dispose edilirken Firestore aboneliğini iptal et.
    // Aksi halde uygulama açıkken gereksiz ağ trafiği ve memory leak oluşabilir.
    _sub?.cancel();
    super.dispose();
  }
}
