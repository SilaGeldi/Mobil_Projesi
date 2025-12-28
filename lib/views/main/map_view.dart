import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/notification_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/notification_view_model.dart';
import '../main/notification_detail_page.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final Completer<GoogleMapController> _controller = Completer();

  static const LatLng campusLocation = LatLng(39.9009, 41.2640);

  bool onlyFollowing = false;
  final Set<String> selectedStatuses = {};
  final Set<String> selectedTypes = {};

  NotificationModel? _selected;

  /// ✅ HomePage ile aynı normalizasyon
  String _norm(String s) {
    return s
        .toLowerCase()
        .trim()
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .replaceAll("ı", "i")
        .replaceAll("ğ", "g")
        .replaceAll("ü", "u")
        .replaceAll("ş", "s")
        .replaceAll("ö", "o")
        .replaceAll("ç", "c");
  }

  double _hueForType(String typeRaw) {
    final type = _norm(typeRaw);

    switch (type) {
      case "kayip":
        return BitmapDescriptor.hueOrange;
      case "saglik":
        return BitmapDescriptor.hueGreen;
      case "teknikariza":
        return BitmapDescriptor.hueViolet;
      case "guvenlik":
        return BitmapDescriptor.hueRed; // ✅ kırmızı
      case "cevre":
        return BitmapDescriptor.hueCyan;
      case "duyuru":
        return BitmapDescriptor.hueBlue;
      case "diger":
        return BitmapDescriptor.hueRose;
      case "acil":
        return BitmapDescriptor.hueRed;
      default:
        return BitmapDescriptor.hueAzure;
    }
  }

  List<NotificationModel> _applyFilters({
    required List<NotificationModel> all,
    required String? myUid,
  }) {
    return all.where((n) {
      // location boşsa basma
      // (modelde null değil ama garanti olsun)
      final loc = n.location;
      if (loc.latitude == 0.0 && loc.longitude == 0.0) return false;

      if (onlyFollowing) {
        if (myUid == null) return false;
        if (!n.followers.contains(myUid)) return false;
      }

      if (selectedStatuses.isNotEmpty) {
        final st = _norm(n.status);
        if (!selectedStatuses.contains(st)) return false;
      }

      if (selectedTypes.isNotEmpty) {
        final tp = _norm(n.type);
        if (!selectedTypes.contains(tp)) return false;
      }

      return true;
    }).toList();
  }

  Set<Marker> _buildMarkers(List<NotificationModel> items) {
    return items.map((n) {
      final pos = LatLng(n.location.latitude, n.location.longitude);

      return Marker(
        markerId: MarkerId(n.notifId ?? "${n.title}_${n.date.seconds}"),
        position: pos,
        icon: BitmapDescriptor.defaultMarkerWithHue(_hueForType(n.type)),
        onTap: () => setState(() => _selected = n),
        infoWindow: InfoWindow(title: n.title),
      );
    }).toSet();
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            Widget chip(String text, bool selected, VoidCallback onTap) {
              return ChoiceChip(
                label: Text(text),
                selected: selected,
                onSelected: (_) => onTap(),
              );
            }

            void toggleSet(Set<String> set, String key) {
              setModal(() {
                if (set.contains(key)) {
                  set.remove(key);
                } else {
                  set.add(key);
                }
              });
              setState(() {});
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Filtrele", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  const Text("Özel Filtre"),
                  const SizedBox(height: 8),
                  chip("Sadece Takip Ettiklerim", onlyFollowing, () {
                    setModal(() => onlyFollowing = !onlyFollowing);
                    setState(() {});
                  }),

                  const SizedBox(height: 16),
                  const Text("Durum"),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      chip("açık", selectedStatuses.contains("acik"), () => toggleSet(selectedStatuses, "acik")),
                      chip("inceleniyor", selectedStatuses.contains("inceleniyor"), () => toggleSet(selectedStatuses, "inceleniyor")),
                      chip("çözüldü", selectedStatuses.contains("cozuldu"), () => toggleSet(selectedStatuses, "cozuldu")),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Text("Tür"),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      chip("Acil", selectedTypes.contains("acil"), () => toggleSet(selectedTypes, "acil")),
                      chip("Sağlık", selectedTypes.contains("saglik"), () => toggleSet(selectedTypes, "saglik")),
                      chip("Kayıp", selectedTypes.contains("kayip"), () => toggleSet(selectedTypes, "kayip")),
                      chip("Güvenlik", selectedTypes.contains("guvenlik"), () => toggleSet(selectedTypes, "guvenlik")),
                      chip("Duyuru", selectedTypes.contains("duyuru"), () => toggleSet(selectedTypes, "duyuru")),
                      chip("Çevre", selectedTypes.contains("cevre"), () => toggleSet(selectedTypes, "cevre")),
                      chip("Teknik Arıza", selectedTypes.contains("teknikariza"), () => toggleSet(selectedTypes, "teknikariza")),
                      chip("Diğer", selectedTypes.contains("diger"), () => toggleSet(selectedTypes, "diger")),
                    ],
                  ),

                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Uygula"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return "${diff.inMinutes} dakika önce";
    if (diff.inHours < 24) return "${diff.inHours} saat önce";
    return "${diff.inDays} gün önce";
  }

  @override
  Widget build(BuildContext context) {
    final notifVM = context.watch<NotificationViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final myUid = authVM.currentUser?.uid;

    final filtered = _applyFilters(all: notifVM.notifications, myUid: myUid);
    final markers = _buildMarkers(filtered);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Harita"),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: campusLocation,
              zoom: 14.5,
            ),
            markers: markers,
            zoomControlsEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (c) async {
              _controller.complete(c);
              await c.moveCamera(CameraUpdate.newLatLngZoom(campusLocation, 14.5));
            },
            onTap: (_) => setState(() => _selected = null),
          ),

          if (_selected != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Material(
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
                              Text(_selected!.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text("Tür: ${_selected!.type} • ${_timeAgo(_selected!.date.toDate())}"),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final n = _selected!;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NotificationDetailPage(notification: n),
                              ),
                            );
                          },
                          child: const Text("Detayı Gör"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
