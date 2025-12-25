import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/notification_model.dart';
import '../../view_models/notification_view_model.dart';
import 'notification_detail_page.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final Completer<GoogleMapController> _controller = Completer();

  static const LatLng _initialCenter = LatLng(39.925533, 32.866287);

  NotificationModel? _selected;

  double _hueForType(String type) {
    switch (type.toLowerCase()) {
      case "guvenlik":
        return BitmapDescriptor.hueRed;
      case "duyuru":
        return BitmapDescriptor.hueAzure;
      case "kayip":
        return BitmapDescriptor.hueOrange;
      default:
        return BitmapDescriptor.hueViolet;
    }
  }

  LatLng _toLatLng(dynamic location) {
    // Sende location GeoPoint ise:
    if (location is GeoPoint) {
      return LatLng(location.latitude, location.longitude);
    }
    // Sende location zaten LatLng ise:
    if (location is LatLng) return location;

    // Eğer farklı bir yapıysa burayı notification_model.dart’a göre düzenleyeceğiz.
    return _initialCenter;
  }

  Set<Marker> _buildMarkers(List<NotificationModel> list) {
    return list.map((n) {
      final pos = _toLatLng(n.location); // <- alan adı sende farklı olabilir
      final id = n.notifId ?? "";        // <- alan adı sende farklı olabilir
      return Marker(
        markerId: MarkerId(id),
        position: pos,
        icon: BitmapDescriptor.defaultMarkerWithHue(_hueForType(n.type)),
        infoWindow: InfoWindow(title: n.title),
        onTap: () => setState(() => _selected = n),
      );
    }).toSet();
  }

  String _timeAgo(Timestamp ts) {
    final dt = ts.toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return "${diff.inMinutes} dk önce";
    if (diff.inHours < 24) return "${diff.inHours} saat önce";
    return "${diff.inDays} gün önce";
  }

  @override
  Widget build(BuildContext context) {
    final notifVM = context.watch<NotificationViewModel>();
    final list = notifVM.notifications; // zaten HomePage’de kullandığın liste

    return Scaffold(
      appBar: AppBar(title: const Text("Harita")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _initialCenter,
              zoom: 15,
            ),
            markers: _buildMarkers(list),
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            onMapCreated: (c) => _controller.complete(c),
            onTap: (_) => setState(() => _selected = null),
          ),

          if (_selected != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _PinCard(
                  title: _selected!.title,
                  subtitle: "Tür: ${_selected!.type} • ${_timeAgo(_selected!.date)}", // date alanı
                  onDetail: () {
                    final selected = _selected;
                    if (selected == null) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationDetailPage(notification: selected),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PinCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onDetail;

  const _PinCard({
    required this.title,
    required this.subtitle,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(subtitle),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onDetail,
              child: const Text("Detayı Gör"),
            )
          ],
        ),
      ),
    );
  }
}
