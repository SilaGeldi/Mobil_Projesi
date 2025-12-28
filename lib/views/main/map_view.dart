// Bu dosya, uygulama içindeki harita görünümünü sağlar.
// Harita üzerinde bildirimler işaretlenir ve filtre/odağı yönetir.
import 'dart:async'; // GoogleMapController tamamlanmasını beklemek için Completer kullanıyoruz.
import 'package:flutter/material.dart'; // Temel Flutter widget'ları
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Google Maps Flutter paketi (Marker, CameraUpdate, LatLng vb.)
import 'package:provider/provider.dart'; // ViewModel'leri okumak için Provider

// Uygulama içi modeller ve view model'ler
import '../../models/notification_model.dart'; // Bildirim verisi modeli
import '../../view_models/auth_view_model.dart'; // Kullanıcı bilgilerini sağlayan view model
import '../../view_models/notification_view_model.dart'; // Bildirim listesini sağlayan view model
import '../main/notification_detail_page.dart'; // Bildirim detay sayfasına yönlendirme için

class MapView extends StatefulWidget {
  // Bu widget dışarıdan isteğe bağlı bir `focusNotification` alabilir.
  // Eğer detay sayfasından gelindiyse ve bir bildirim verilmişse, harita
  // o bildirimin konumuna odaklanır.
  final NotificationModel? focusNotification;

  const MapView({super.key, this.focusNotification});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  // GoogleMapController asenkron olarak gelir; Completer ile onu saklayıp
  // future tamamlandığında kullanıyoruz.
  final Completer<GoogleMapController> _controller = Completer();

  // Haritanın varsayılan odak noktası (kampüs koordinatları).
  // Eğer özel bir bildirim yoksa veya bildirimin koordinatı 0,0 ise buraya döneriz.
  static const LatLng campusLocation = LatLng(39.9009, 41.2640);

  // Filtre seçenekleri: sadece takip ettiklerim, seçili durumlar ve türler.
  // `onlyFollowing`: true ise yalnızca kullanıcının takip ettiklerini göster.
  bool onlyFollowing = false;
  // selectedStatuses ve selectedTypes normalize edilmiş değerler içerir (örn "acik", "acil").
  final Set<String> selectedStatuses = {};
  final Set<String> selectedTypes = {};

  // Harita üzerinde kullanıcı bir marker'a tıklarsa, o bildirim burada saklanır
  // ve altında bir kart gösterilir. Null ise hiçbir kart gösterilmez.
  NotificationModel? _selected;

  /// ✅ HomePage ile aynı normalizasyon (Türkçe karakter / boşluk / _ / büyük-küçük derdi biter)
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
    // Bildirim türüne göre marker rengini belirliyoruz.
    // _norm ile gelen türü normalleştiriyoruz ve sabit hue değerleri döndürüyoruz.
    switch (type) {
      case "kayip":
        return BitmapDescriptor.hueOrange;
      case "saglik":
        return BitmapDescriptor.hueGreen;
      case "teknikariza":
        return BitmapDescriptor.hueViolet;
      case "guvenlik":
        return BitmapDescriptor.hueRed;
      case "cevre":
        return BitmapDescriptor.hueCyan;
      case "duyuru":
        return BitmapDescriptor.hueBlue;
      case "diger":
        return BitmapDescriptor.hueRose;
      case "acil":
        // Acil için kırmızı tonu kullanıyoruz (gösterişli olsun diye).
        return BitmapDescriptor.hueRed;
      default:
        // Bilinmeyen türler için nötr bir ton.
        return BitmapDescriptor.hueAzure;
    }
  }

  List<NotificationModel> _applyFilters({
    required List<NotificationModel> all,
    required String? myUid,
  }) {
    return all.where((n) {
      // 1) Boş konum kontrolü: (0,0) genelde eksik/varsayılan konumdur, bunları haritaya koyma.
      final loc = n.location;
      if (loc.latitude == 0.0 && loc.longitude == 0.0) return false;

      // 2) Sadece takip ettiklerim filtresi: açık ise kullanıcının takip listesinde yoksa el.
      if (onlyFollowing) {
        if (myUid == null) return false; // giriş yoksa hiçbir şey takip edemez
        if (!n.followers.contains(myUid)) return false;
      }

      // 3) Durum filtresi: kullanıcı bir veya daha fazla durum seçtiyse kontrol et.
      if (selectedStatuses.isNotEmpty) {
        final st = _norm(n.status);
        if (!selectedStatuses.contains(st)) return false;
      }

      // 4) Tür filtresi: seçili türler varsa kontrol et.
      if (selectedTypes.isNotEmpty) {
        final tp = _norm(n.type);
        if (!selectedTypes.contains(tp)) return false;
      }

      // Hiçbir filtre tarafından elenmediyse bu öğe gösterilir.
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
        // Marker'a tıklayınca alt kart için seçili bildirimi güncelle ve setState çağır.
        onTap: () => setState(() => _selected = n),
        // InfoWindow sadece başlık gösterir; detay için alttaki kart veya sayfaya gidilir.
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
                  // Modal başlığı
                  const Text("Filtrele", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // Sadece takip edilenler seçeneği
                  const Text("Özel Filtre"),
                  const SizedBox(height: 8),
                  chip("Sadece Takip Ettiklerim", onlyFollowing, () {
                    // Modal içindeki state'i güncelle ve ana state'i de setState ile yenile.
                    setModal(() => onlyFollowing = !onlyFollowing);
                    setState(() {});
                  }),

                  const SizedBox(height: 16),
                  // Durum seçimleri
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
                  // Tür seçimleri
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
                  // Uygula butonu: modalı kapatır, çünkü filtreler zaten setState ile uygulanmıştır.
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

  /// ✅ Detail’den gelince haritayı o noktaya odaklar
  Future<void> _focusToNotificationIfAny(GoogleMapController c, List<NotificationModel> currentList) async {
    final focus = widget.focusNotification;
    if (focus == null) return;
    // Eğer widget dışarıdan bir focusNotification aldıysa, güncel VM listesinden aynı id'yi
    // arayıp en güncel nesneyi almaya çalışırız. Eğer VM listesinde yoksa focus objesini kullan.
    final found = currentList.firstWhere(
      (x) => x.notifId != null && x.notifId == focus.notifId,
      orElse: () => focus,
    );

    final lat = found.location.latitude;
    final lng = found.location.longitude;

    // Eğer koordinatlar 0,0 ise gerçek bir konum yok demektir; o zaman kampüse odaklan.
    if (lat == 0.0 && lng == 0.0) {
      await c.animateCamera(CameraUpdate.newLatLngZoom(campusLocation, 14.5));
      return;
    }

    // Kamerayı ilgili bildirimin koordinatına yaklaştır.
    final target = LatLng(lat, lng);
    await c.animateCamera(CameraUpdate.newLatLngZoom(target, 17));

    // Kart görünümünü açmak için seçili bildirimi güncelle.
    if (mounted) {
      setState(() => _selected = found);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifVM = context.watch<NotificationViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final myUid = authVM.currentUser?.uid;

    final filtered = _applyFilters(all: notifVM.notifications, myUid: myUid);
    final markers = _buildMarkers(filtered);

    // Scaffold: sayfanın ana yapısı. AppBar + body içerir.
    return Scaffold(
      appBar: AppBar(
        title: const Text("Harita"),
        actions: [
          // Filtre modalını açan ikon
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: Stack(
        children: [
          // GoogleMap widget'ı
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: campusLocation,
              zoom: 14.5,
            ),
            markers: markers,
            // Kullanıcı arayüz tercihleri
            zoomControlsEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (c) async {
              // Controller geleceği için Completer'ı tamamla
              _controller.complete(c);

              // Harita başlangıçta kampüse gider
              await c.moveCamera(CameraUpdate.newLatLngZoom(campusLocation, 14.5));

              // Eğer detay sayfasından gelinip bir odak bildirimi verilmişse ona odaklan
              await _focusToNotificationIfAny(c, notifVM.notifications);
            },
            // Haritaya dokunulduğunda seçili bildirimi kapat
            onTap: (_) => setState(() => _selected = null),
          ),

          // Eğer bir marker seçildiyse aşağıda küçük bir kart göster (detaya gitme seçeneğiyle)
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
                              // Seçili bildirimin başlığı
                              Text(
                                _selected!.title,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              // Tür ve ne kadar süre önce yayınlandığı bilgisi
                              Text("Tür: ${_selected!.type} • ${_timeAgo(_selected!.date.toDate())}"),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Detay butonu: bildirim detay sayfasına gider
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
