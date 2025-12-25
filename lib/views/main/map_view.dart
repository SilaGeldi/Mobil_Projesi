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

  static const LatLng _fallbackCenter = LatLng(39.925533, 32.866287);

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

  LatLng _toLatLng(NotificationModel n) {
    // notification.location: GeoPoint varsayıyorum (senin detail sayfanda öyle kullanılmış)
    return LatLng(n.location.latitude, n.location.longitude);
  }

  String _timeAgo(Timestamp ts) {
    final dt = ts.toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "şimdi";
    if (diff.inMinutes < 60) return "${diff.inMinutes} dakika önce";
    if (diff.inHours < 24) return "${diff.inHours} saat önce";
    return "${diff.inDays} gün önce";
  }

  Set<Marker> _buildMarkers(List<NotificationModel> list) {
    return list.map((n) {
      final id = n.notifId ?? "${n.title}_${n.date.millisecondsSinceEpoch}";
      return Marker(
        markerId: MarkerId(id),
        position: _toLatLng(n),
        icon: BitmapDescriptor.defaultMarkerWithHue(_hueForType(n.type)),
        onTap: () => setState(() => _selected = n),
      );
    }).toSet();
  }

  LatLng _bestCenter(List<NotificationModel> list) {
    if (list.isEmpty) return _fallbackCenter;
    return _toLatLng(list.first);
  }

  @override
  Widget build(BuildContext context) {
    final notifVM = context.watch<NotificationViewModel>();
    final notifs = notifVM.notifications;

    return Scaffold(
      appBar: AppBar(title: const Text("Harita")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _bestCenter(notifs),
              zoom: 15,
            ),
            markers: _buildMarkers(notifs),
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            onMapCreated: (c) => _controller.complete(c),
            onTap: (_) => setState(() => _selected = null),
          ),

          // Pin bilgi kartı
          if (_selected != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _PinCard(
                  notif: _selected!,
                  timeAgoText: _timeAgo(_selected!.date),
                  onDetail: () {
                    final current = _selected;
                    if (current == null) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationDetailPage(notification: current),
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
  final NotificationModel notif;
  final String timeAgoText;
  final VoidCallback onDetail;

  const _PinCard({
    required this.notif,
    required this.timeAgoText,
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
                  Text(
                    notif.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text("Tür: ${notif.type} • $timeAgoText"),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onDetail,
              child: const Text("Detayı Gör"),
            ),
          ],
        ),
      ),
    );
  }
}
