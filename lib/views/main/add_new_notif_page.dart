import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../view_models/notification_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../models/notification_model.dart';

class AddNewNotificationPage extends StatefulWidget {
  const AddNewNotificationPage({super.key});

  @override
  State<AddNewNotificationPage> createState() =>
      _AddNewNotificationPageState();
}

class _AddNewNotificationPageState extends State<AddNewNotificationPage> {
  final titleController = TextEditingController();
  final descController = TextEditingController();

  String selectedType = "duyuru";
  final String defaultStatus = "inceleniyor";

  // 📍 KONUM
  GeoPoint? selectedLocation;
  bool loadingLocation = false;
  bool locationFromDevice = false;

  // 🏫 Kampüs başlangıç konumu
// 🏫 Atatürk Üniversitesi Kampüs Konumu
  static const LatLng campusLocation =
  LatLng(39.9009, 41.2640);

  late LatLng mapCenter = campusLocation;

  // 📱 Cihaz konumu al
  Future<void> useDeviceLocation() async {
    setState(() => loadingLocation = true);

    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => loadingLocation = false);
      return;
    }

    final pos = await Geolocator.getCurrentPosition();

    setState(() {
      mapCenter = LatLng(pos.latitude, pos.longitude);
      selectedLocation = GeoPoint(pos.latitude, pos.longitude);
      locationFromDevice = true;
      loadingLocation = false;
    });
  }

  Future<void> saveNotification() async {
    if (titleController.text.isEmpty ||
        descController.text.isEmpty ||
        selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tüm alanları doldurun")),
      );
      return;
    }

    final user = context.read<AuthViewModel>().currentUser!;

    final notif = NotificationModel(
      title: titleController.text.trim(),
      description: descController.text.trim(),
      type: selectedType,
      status: defaultStatus,
      location: selectedLocation!,
      date: Timestamp.now(),
      createdBy: user.uid,
      createdByName: user.name,
      followers: [],
    );

    await context
        .read<NotificationViewModel>()
        .addNotification(notif);

    Navigator.pop(context);
  }

  // 🔲 Ortak Form Kartı
  Widget formCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Bildirim")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🧾 BAŞLIK
            formCard(
              child: TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Bildirim Başlığı",
                  border: InputBorder.none,
                ),
              ),
            ),

            // 📝 AÇIKLAMA
            formCard(
              child: TextField(
                controller: descController,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: "Açıklama",
                  border: InputBorder.none,
                ),
              ),
            ),

            // 🏷️ TÜR
            formCard(
              child: DropdownButtonFormField(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: "Bildirim Türü",
                  border: InputBorder.none,
                ),
                items: const [
                  DropdownMenuItem(
                      value: "duyuru", child: Text("Duyuru")),
                  DropdownMenuItem(
                      value: "acil", child: Text("Acil")),
                  DropdownMenuItem(
                      value: "saglik", child: Text("Sağlık")),
                  DropdownMenuItem(
                      value: "kayip", child: Text("Kayıp")),
                  DropdownMenuItem(
                      value: "guvenlik",
                      child: Text("Güvenlik")),
                  DropdownMenuItem(
                      value: "diger",
                      child: Text("Diğer")),
                ],
                onChanged: (v) =>
                    setState(() => selectedType = v!),
              ),
            ),

            // 📍 KONUM
            formCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed:
                    loadingLocation ? null : useDeviceLocation,
                    icon: const Icon(Icons.my_location),
                    label: Text(
                      loadingLocation
                          ? "Konum alınıyor..."
                          : locationFromDevice
                          ? "Cihaz konumu alındı ✓"
                          : "Cihaz konumunu kullan",
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 🗺️ HARİTA
                  SizedBox(
                    height: 220,
                    child: GoogleMap(
                      initialCameraPosition:
                      CameraPosition(
                        target: mapCenter,
                        zoom: 16,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      onCameraMove: (pos) {
                        mapCenter = pos.target;
                      },
                      onCameraIdle: () {
                        setState(() {
                          selectedLocation = GeoPoint(
                            mapCenter.latitude,
                            mapCenter.longitude,
                          );
                        });
                      },
                      markers: {
                        Marker(
                          markerId:
                          const MarkerId("selected"),
                          position: mapCenter,
                        ),
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 💾 KAYDET
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveNotification,
                child: const Text(
                  "Bildirim Oluştur",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
