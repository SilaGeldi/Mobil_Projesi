import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  String? notifId;                // Firestore document ID
  String title;
  String description;
  String type;
  String status;
  GeoPoint location;
  Timestamp date;
  String createdBy;
  String createdByName;

  NotificationModel({
    this.notifId,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.location,
    required this.date,
    required this.createdBy,
    required this.createdByName,
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
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',

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
      "createdBy": createdBy,
      "createdByName": createdByName,

    };
  }
}
