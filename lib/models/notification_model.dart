import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  String? notifId;                // Firestore document ID
  String title;
  String description;
  String type;
  String status;
  GeoPoint location;
  Timestamp date;

  NotificationModel({
    this.notifId,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.location,
    required this.date,
  });

  // Firestore -> Model
  factory NotificationModel.fromMap(
      Map<String, dynamic> map, String documentId) {
    return NotificationModel(
      notifId: documentId,                       // ID buraya atanıyor
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? '',
      status: map['status'] ?? '',
      location: map['location'] ?? const GeoPoint(0.0, 0.0),
      date: map['date'] ?? Timestamp.now(),
    );
  }

  // Model -> Firestore
  Map<String, dynamic> toMap() {
    return {
      "title": title,
      "description": description,
      "type": type,
      "status": status,
      "location": location,
      "date": date,
    };
  }
}
