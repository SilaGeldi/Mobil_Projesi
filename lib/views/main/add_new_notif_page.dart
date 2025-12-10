import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/notification_model.dart';
import '../../view_models/notification_view_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddNewNotificationPage extends StatefulWidget {
  const AddNewNotificationPage({super.key});

  @override
  State<AddNewNotificationPage> createState() =>
      _AddNewNotificationPageState();
}

class _AddNewNotificationPageState extends State<AddNewNotificationPage> {
  // Controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String selectedType = "duyuru";
  String selectedStatus = "aktif";

  GeoPoint? selectedLocation;
  bool isLoadingLocation = false;

  Future<void> getCurrentLocation() async {
    setState(() => isLoadingLocation = true);

    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Konum izni gerekli.")),
      );
      setState(() => isLoadingLocation = false);
      return;
    }

    Position pos = await Geolocator.getCurrentPosition();

    setState(() {
      selectedLocation = GeoPoint(pos.latitude, pos.longitude);
      isLoadingLocation = false;
    });
  }

  Future<void> saveNotification() async {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun.")),
      );
      return;
    }

    final notif = NotificationModel(
      notifId: null,
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      type: selectedType,
      status: selectedStatus,
      location: selectedLocation!,
      date: Timestamp.now(),
    );

    await Provider.of<NotificationViewModel>(context, listen: false)
        .addNotification(notif);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yeni Bildirim Ekle"),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Başlık
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Başlık",
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Açıklama
            TextField(
              controller: descriptionController,
              minLines: 4,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: "Açıklama",
                alignLabelWithHint: true,
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Tür Dropdown
            DropdownButtonFormField<String>(
              value: selectedType,
              items: const [
                DropdownMenuItem(value: "duyuru", child: Text("Duyuru")),
                DropdownMenuItem(value: "acil", child: Text("Acil")),
                DropdownMenuItem(
                    value: "guvenlik", child: Text("Güvenlik")),
                DropdownMenuItem(value: "bilgi", child: Text("Bilgi")),
              ],
              onChanged: (v) => setState(() => selectedType = v!),
              decoration: InputDecoration(
                labelText: "Tür",
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Durum Dropdown
            DropdownButtonFormField<String>(
              value: selectedStatus,
              items: const [
                DropdownMenuItem(value: "aktif", child: Text("Aktif")),
                DropdownMenuItem(value: "pasif", child: Text("Pasif")),
                DropdownMenuItem(value: "cozuldu", child: Text("Çözüldü")),
              ],
              onChanged: (v) => setState(() => selectedStatus = v!),
              decoration: InputDecoration(
                labelText: "Durum",
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Konum Alma Butonu
            ElevatedButton.icon(
              onPressed: isLoadingLocation ? null : getCurrentLocation,
              icon: const Icon(Icons.location_on),
              label: Text(
                isLoadingLocation
                    ? "Konum alınıyor..."
                    : "Cihaz Konumunu Al",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),

            const SizedBox(height: 8),

            // Konum gösterimi
            if (selectedLocation != null)
              Text(
                "Konum: ${selectedLocation!.latitude}, ${selectedLocation!.longitude}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

            const SizedBox(height: 30),

            // Kaydet Butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  "Kaydet",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
