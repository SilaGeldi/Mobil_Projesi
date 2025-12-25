import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final Completer<GoogleMapController> _controller = Completer();

  // Şimdilik sabit merkez: kampüs vb. (sonra dinamik yaparız)
  static const LatLng _initialCenter = LatLng(39.925533, 32.866287); // Ankara örnek

  // Demo pinler (sonra Firebase/Model’den çekeceğiz)
  final List<_MapNotif> _items = [
    _MapNotif(
      id: "1",
      title: "Kayıp Buluntu",
      type: "kayip",
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
      position: const LatLng(39.9259, 32.8669),
    ),
    _MapNotif(
      id: "2",
      title: "Güvenlik",
      type: "guvenlik",
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      position: const LatLng(39.9252, 32.8656),
    ),
  ];

  _MapNotif? _selected;

  BitmapDescriptor _iconForType(String type) {
    // Şimdilik default marker + renk farkı için hue kullanacağız (basit ve stabil)
    // İkon istersen sonraki adımda asset marker’a geçeriz.
    return BitmapDescriptor.defaultMarker;
  }

  double _hueForType(String type) {
    switch (type) {
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

  Set<Marker> get _markers => _items.map((e) {
    return Marker(
      markerId: MarkerId(e.id),
      position: e.position,
      icon: BitmapDescriptor.defaultMarkerWithHue(_hueForType(e.type)),
      infoWindow: InfoWindow(title: e.title),
      onTap: () => setState(() => _selected = e),
    );
  }).toSet();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Harita")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _initialCenter,
              zoom: 15,
            ),
            markers: _markers,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true, // yakınlaştır/uzaklaştır
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
                  item: _selected!,
                  onDetail: () {
                    // TODO: Detay ekranına yönlendireceğiz (Adım 4)
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
  final _MapNotif item;
  final VoidCallback onDetail;

  const _PinCard({required this.item, required this.onDetail});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return "${diff.inMinutes} dk önce";
    if (diff.inHours < 24) return "${diff.inHours} saat önce";
    return "${diff.inDays} gün önce";
  }

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
                  Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text("Tür: ${item.type} • ${_timeAgo(item.createdAt)}"),
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

class _MapNotif {
  final String id;
  final String title;
  final String type;
  final DateTime createdAt;
  final LatLng position;

  _MapNotif({
    required this.id,
    required this.title,
    required this.type,
    required this.createdAt,
    required this.position,
  });
}
