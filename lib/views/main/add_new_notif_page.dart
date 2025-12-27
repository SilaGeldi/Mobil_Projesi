import 'package:flutter/foundation.dart'; // 🔥 Harita hareketi için gerekli
import 'package:flutter/gestures.dart';    // 🔥 Harita hareketi için gerekli
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
  State<AddNewNotificationPage> createState() => _AddNewNotificationPageState();
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

  // 🏫 Atatürk Üniversitesi Kampüs Konumu
  static const LatLng campusLocation = LatLng(39.9009, 41.2640);
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

  // 💾 BİLDİRİM KAYDET VE ONAY MESAJI
  Future<void> saveNotification() async {
    if (titleController.text.isEmpty ||
        descController.text.isEmpty ||
        selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tüm alanları doldurun")),
      );
      return;
    }

    try {
      final authVM = context.read<AuthViewModel>();
      final user = authVM.currentUser!;

      final isAdmin = (user.role == "admin");

      // ✅ Admin değilse acil seçilmesini engelle (garanti)
      if (!isAdmin && selectedType == "acil") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Acil duyuru sadece admin tarafından yayınlanabilir.")),
        );
        setState(() => selectedType = "duyuru");
        return;
      }

      final notif = NotificationModel(
        title: titleController.text.trim(),
        description: descController.text.trim(),
        type: selectedType, // ✅ admin acil seçerse "acil" kaydolur
        status: defaultStatus,
        location: selectedLocation!,
        date: Timestamp.now(),
        createdBy: user.uid,
        createdByName: user.name,
        followers: [],
      );

      await context.read<NotificationViewModel>().addNotification(notif);

      // ✅ BAŞARI MESAJI (SnackBar)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text("Bildiriminiz başarıyla eklendi!"),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context); // İşlem başarılıysa geri dön
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bir hata oluştu: $e"), backgroundColor: Colors.red),
        );
      }
    }
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
    final authVM = context.watch<AuthViewModel>();
    final isAdmin = (authVM.currentUser?.role == "admin");

    // ✅ Dropdown item listesi: admin ise acil ekle
    final List<DropdownMenuItem<String>> typeItems = [
      if (isAdmin)
        const DropdownMenuItem(value: "acil", child: Text("Acil Duyuru")),
      const DropdownMenuItem(value: "duyuru", child: Text("Duyuru")),
      const DropdownMenuItem(value: "saglik", child: Text("Sağlık")),
      const DropdownMenuItem(value: "kayip", child: Text("Kayıp")),
      const DropdownMenuItem(value: "guvenlik", child: Text("Güvenlik")),
      const DropdownMenuItem(value: "cevre", child: Text("Çevre")),
      const DropdownMenuItem(value: "teknikAriza", child: Text("Teknik Arıza")),
      const DropdownMenuItem(value: "diger", child: Text("Diğer")),
    ];

    // ✅ Admin değilken yanlışlıkla selectedType acil kalmışsa düzelt
    if (!isAdmin && selectedType == "acil") {
      selectedType = "duyuru";
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Yeni Bildirim", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🧾 BAŞLIK
            formCard(
              child: TextField(
                controller: titleController,
                keyboardType: TextInputType.multiline,
                enableSuggestions: true,
                autocorrect: true,
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
                keyboardType: TextInputType.multiline,
                enableSuggestions: true,
                autocorrect: true,
                decoration: const InputDecoration(
                  labelText: "Açıklama",
                  border: InputBorder.none,
                ),
              ),
            ),

            // 🏷️ TÜR (admin ise acil görür)
            formCard(
              child: DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: "Bildirim Türü",
                  border: InputBorder.none,
                ),
                items: typeItems,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => selectedType = v);
                },
              ),
            ),

            // 📍 KONUM
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 🗺️ HARİTA
                  SizedBox(
                    height: 250,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GoogleMap(
                        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                          Factory<OneSequenceGestureRecognizer>(
                                () => EagerGestureRecognizer(),
                          ),
                        },
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
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      "* Haritayı kaydırarak konumu belirleyebilirsiniz.",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 💾 KAYDET BUTONU
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: saveNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Bildirim Oluştur",
                  style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}