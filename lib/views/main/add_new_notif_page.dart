import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/notification_model.dart';
import '../../view_models/notification_view_model.dart';
import '../../view_models/auth_view_model.dart';

class AddNewNotificationPage extends StatefulWidget {
  final bool isEmergency;
  const AddNewNotificationPage({super.key, this.isEmergency = false});

  @override
  State<AddNewNotificationPage> createState() => _AddNewNotificationPageState();
}

class _AddNewNotificationPageState extends State<AddNewNotificationPage> {
  final titleController = TextEditingController();
  final descController = TextEditingController();

  String selectedType = "sağlık";
  String defaultStatus = "inceleniyor";

  // 📍 KONUM
  GeoPoint? selectedLocation;
  bool loadingLocation = false;
  bool locationFromDevice = false;

  // 🏫 Kampüs başlangıç konumu (Atatürk Üniversitesi)
  static const LatLng campusLocation = LatLng(39.9009, 41.2640);
  late LatLng mapCenter = campusLocation;

  @override
  void initState() {
    super.initState();
    if (widget.isEmergency) {
      selectedType = "acil";
      defaultStatus = "açık"; // acil yayınlanınca “açık” daha mantıklı
    }
  }

  // 📱 Cihaz konumu al
  Future<void> useDeviceLocation() async {
    setState(() => loadingLocation = true);

    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
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
    if (titleController.text.isEmpty || descController.text.isEmpty || selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tüm alanları doldurun")),
      );
      return;
    }

    final authVM = context.read<AuthViewModel>();
    final user = authVM.currentUser!;
    final isAdmin = (user.role == "admin");

    // Admin değilse acil seçemesin (garanti)
    if (!isAdmin && selectedType == "acil") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Acil duyuru sadece admin tarafından yayınlanabilir.")),
      );
      return;
    }

    // isEmergency sayfasıysa zorla acil
    final finalType = widget.isEmergency ? "acil" : selectedType;

    final notif = NotificationModel(
      title: titleController.text.trim(),
      description: descController.text.trim(),
      type: finalType,
      status: widget.isEmergency ? "açık" : defaultStatus,
      location: selectedLocation!,
      date: Timestamp.now(),
      createdBy: user.uid,
      createdByName: user.name,
      followers: [],
    );

    await context.read<NotificationViewModel>().addNotification(notif);

    Navigator.pop(context);
  }

  Widget formCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);
    final user = authVM.currentUser;
    final isAdmin = (user?.role == "admin");

    // Tip listesi: admin ise acil görür, user görmez
    final List<Map<String, String>> typeItems = [
      {"value": "sağlık", "label": "Sağlık"},
      {"value": "kayıp", "label": "Kayıp"},
      {"value": "güvenlik", "label": "Güvenlik"},
      {"value": "duyuru", "label": "Duyuru"},
      {"value": "çevre", "label": "Çevre"},
      {"value": "teknikariza", "label": "Teknik Arıza"},
      {"value": "diğer", "label": "Diğer"},
    ];

    if (isAdmin) {
      typeItems.insert(0, {"value": "acil", "label": "Acil Duyuru"});
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(widget.isEmergency ? "Yeni Acil Duyuru" : "Yeni Bildirim"),
        backgroundColor: widget.isEmergency ? Colors.red.shade700 : const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Başlık
            formCard(
              child: TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Bildirim Başlığı",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Açıklama
            formCard(
              child: TextField(
                controller: descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Açıklama",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tür (Acil sayfasında kilit)
            formCard(
              child: DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: "Bildirim Türü",
                  border: OutlineInputBorder(),
                ),
                items: typeItems
                    .map((m) => DropdownMenuItem<String>(
                  value: m["value"]!,
                  child: Text(m["label"]!),
                ))
                    .toList(),
                onChanged: widget.isEmergency
                    ? null
                    : (val) {
                  if (val == null) return;
                  setState(() => selectedType = val);
                },
              ),
            ),
            const SizedBox(height: 12),

            // Durum (Acilde otomatik açık)
            formCard(
              child: DropdownButtonFormField<String>(
                value: widget.isEmergency ? "açık" : defaultStatus,
                decoration: const InputDecoration(
                  labelText: "Durum",
                  border: OutlineInputBorder(),
                ),
                items: const ["açık", "inceleniyor", "çözüldü"]
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: widget.isEmergency
                    ? null
                    : (val) {
                  if (val == null) return;
                  setState(() => defaultStatus = val);
                },
              ),
            ),
            const SizedBox(height: 12),

            // 📍 KONUM + HARİTA
            formCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: loadingLocation ? null : useDeviceLocation,
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

                  SizedBox(
                    height: 220,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
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
                          markerId: const MarkerId("selected"),
                          position: mapCenter,
                        ),
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isEmergency ? Colors.red.shade700 : Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: saveNotification,
                child: Text(
                  widget.isEmergency ? "ACİL DUYURU YAYINLA" : "Bildirim Oluştur",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
