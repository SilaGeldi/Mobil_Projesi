import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  GoogleMapController? _controller;

  // Başlangıç konumu (kampüs vb.)
  static const LatLng _initial = LatLng(39.925533, 32.866287); // Ankara örnek

  // Demo veri (sen Firestore’dan çekeceksin; şimdilik ekran çalışsın diye)
  final _items = <_MapNotification>[
    _MapNotification(
      id: "1",
      title: "Kayıp Buluntu",
      type: "kayip",
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
      position: const LatLng(39.9262, 32.8649),
    ),
    _MapNotification(
      id: "2",
      title: "Güvenlik",
      type: "guvenlik",
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      position: const LatLng(39.9249, 32.8672),
    ),
    _MapNotification(
      id: "3",
      title: "Duyuru",
      type: "duyuru",
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      position: const LatLng(39.9259, 32.8685),
    ),
  ];

  Set<Marker> get _markers {
    return _items.map((n) {
      return Marker(
        markerId: MarkerId(n.id),
        position: n.position,
        icon: _iconByType(n.type),
        onTap: () => _showPinCard(n),
      );
    }).toSet();
  }

  BitmapDescriptor _iconByType(String type) {
    switch (type) {
      case "guvenlik":
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case "kayip":
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case "duyuru":
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return "${diff.inMinutes} dk önce";
    if (diff.inHours < 24) return "${diff.inHours} saat önce";
    return "${diff.inDays} gün önce";
  }

  void _zoomIn() => _controller?.animateCamera(CameraUpdate.zoomIn());
  void _zoomOut() => _controller?.animateCamera(CameraUpdate.zoomOut());

  void _showPinCard(_MapNotification n) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _TypeChip(type: n.type),
                  const Spacer(),
                  Text(DateFormat("dd.MM.yyyy").format(n.createdAt)),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  n.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _timeAgo(n.createdAt),
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Sende detay ekranı varsa buraya route koy
                    // Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationDetailView(id: n.id)));
                  },
                  child: const Text("Detayı Gör"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: _initial, zoom: 15),
            markers: _markers,
            zoomControlsEnabled: false, // kendi butonlarımız var
            myLocationButtonEnabled: false,
            onMapCreated: (c) => _controller = c,
          ),

          // Zoom butonları
          Positioned(
            right: 12,
            bottom: 120,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: "zoomIn",
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: "zoomOut",
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String type;
  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (type) {
      "guvenlik" => ("GÜVENLİK", Colors.red),
      "kayip" => ("KAYIP", Colors.orange),
      "duyuru" => ("DUYURU", Colors.blue),
      _ => ("DİĞER", Colors.purple),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _MapNotification {
  final String id;
  final String title;
  final String type; // guvenlik/kayip/duyuru
  final DateTime createdAt;
  final LatLng position;

  _MapNotification({
    required this.id,
    required this.title,
    required this.type,
    required this.createdAt,
    required this.position,
  });
}
