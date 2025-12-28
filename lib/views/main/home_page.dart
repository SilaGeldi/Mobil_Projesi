import 'dart:convert'; // ✅ Map’i JSON’a çevirmek için
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../view_models/notification_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../models/notification_model.dart';
import 'add_new_notif_page.dart';
import 'notification_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String searchQuery = "";
  String? selectedStatus; // ✅ normalize edilmiş: "acik" / "inceleniyor" / "cozuldu"
  String? selectedType;   // ✅ normalize edilmiş: "kayip" / "teknikariza" / ...
  bool showOnlyFollowed = false;

  // ✅ Acil snack: her girişte bir kere gösterilecek
  bool _emergencySnackShown = false;

  // ✅ Takip edilen bildirimlerin en son görülen status’ları (telefon hafızasından okunacak)
  Map<String, String> _lastSeenFollowedStatus = {};

  // ✅ Aynı giriş sırasında aynı değişimi 2 kere göstermesin
  final Set<String> _shownStatusChangeKeysThisSession = {};

  // ✅ Kullanıcı değişti mi diye takip (logout/login olduğunda reset atacağız)
  String? _lastUserId;

  // ✅ Prefs yükleme tamam mı (yüklenmeden karşılaştırma yapmayalım)
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    // initState’te userId daha gelmemiş olabilir; userId build’de gelince yükleyeceğiz.
  }

  String capitalize(String name) {
    if (name.isEmpty) return name;
    return name.split(' ').map((str) {
      if (str.isEmpty) return str;
      return str[0].toUpperCase() + str.substring(1).toLowerCase();
    }).join(' ');
  }

  /// ✅ TEK NORMALİZASYON (Home + Map aynı)
  /// - boşluk/underscore siler
  /// - Türkçe karakterleri düzleştirir
  /// Örn: "Teknik Arıza" / "teknik_ariza" / "teknikAriza" => "teknikariza"
  ///      "Kayıp" => "kayip"
  String _norm(String t) {
    final lower = t.toLowerCase().trim();
    return lower
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c');
  }

  String _normStatus(String s) => _norm(s);

  void _showSnack(String text, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: color ?? Colors.black87,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// ✅ SharedPreferences KEY (user bazlı)
  String _prefsKeyForUser(String uid) => "followed_last_status_$uid";

  /// ✅ Telefona kaydedilmiş takip-status map’ini yükle
  Future<void> _loadLastSeenFollowedStatus(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKeyForUser(uid));

    if (raw == null || raw.isEmpty) {
      _lastSeenFollowedStatus = {};
    } else {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _lastSeenFollowedStatus = decoded.map((k, v) => MapEntry(k, v.toString()));
      } catch (_) {
        _lastSeenFollowedStatus = {};
      }
    }

    _prefsLoaded = true;
  }

  /// ✅ Güncel takip-status map’ini telefona kaydet
  Future<void> _saveLastSeenFollowedStatus(String uid, Map<String, String> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyForUser(uid), jsonEncode(map));
  }

  /// ✅ Görev: Takip edilen bildirimin durumu değişince (girişte) uyarı göster
  Future<void> _checkFollowedStatusChangesOnLogin({
    required List<NotificationModel> all,
    required String uid,
  }) async {
    // Prefs yüklenmeden kıyas yapma
    if (!_prefsLoaded) return;

    // Takip edilen bildirimleri bul
    final followed = all.where((n) => n.notifId != null && n.followers.contains(uid)).toList();

    // Şu anki status snapshot’ı (kaydedilecek)
    final Map<String, String> currentSnapshot = {};

    for (final n in followed) {
      final id = n.notifId!;
      final newSt = _normStatus(n.status);

      currentSnapshot[id] = newSt;

      final oldSt = _lastSeenFollowedStatus[id];

      // İlk kez görüyorsa: sadece kayda al (snack yok)
      if (oldSt == null) continue;

      // Değiştiyse: girişte snack göster
      if (oldSt != newSt) {
        final key = "$id:$oldSt->$newSt";

        // Aynı girişte 2 kere çıkmasın
        if (_shownStatusChangeKeysThisSession.contains(key)) continue;
        _shownStatusChangeKeysThisSession.add(key);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSnack(
            "🔔 Takip ettiğin bildirim güncellendi: \"${n.title}\" → Durum: ${n.status}",
            color: Colors.deepPurple,
          );
        });
      }
    }

    // ✅ Giriş sonrası “son görülen” olarak güncel snapshot’ı kaydet
    await _saveLastSeenFollowedStatus(uid, currentSnapshot);

    // RAM’deki map’i de güncelle (bir sonraki kıyas için)
    _lastSeenFollowedStatus = currentSnapshot;
  }

  /// ✅ Kullanıcı değişince (logout/login) state reset + prefs yükle
  Future<void> _handleUserChanged(String uid) async {
    _lastUserId = uid;

    // ✅ Her girişte acil snack yeniden gösterilebilir olsun
    _emergencySnackShown = false;

    // ✅ Bu girişte gösterilen “status-change” kayıtlarını temizle
    _shownStatusChangeKeysThisSession.clear();

    // ✅ Prefs yeniden yükle
    _prefsLoaded = false;
    _lastSeenFollowedStatus = {};
    await _loadLastSeenFollowedStatus(uid);
  }

  @override
  Widget build(BuildContext context) {
    final notifVM = context.watch<NotificationViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.currentUser;
    final myUid = user?.uid;
    final userName = capitalize(user?.name ?? "Kullanıcı");

    // ✅ Kullanıcı değiştiyse: reset + prefs yükle
    if (myUid != null && myUid != _lastUserId) {
      // build içinde async çağrı: post frame ile
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _handleUserChanged(myUid);
        // Prefs yüklendi; giriş kontrolü bir sonraki frame’de yapılacak
        setState(() {});
      });
    }

    // Filtreleme
    final filteredNotifications = notifVM.notifications.where((n) {
      final nType = _norm(n.type);

      // 1) Kullanıcı tercihleri
      if (user != null) {
        final isHealth = (nType == "saglik");
        final isTechnical = (nType == "teknikariza");

        if (isHealth && !(user.preferences['health'] ?? true)) return false;
        if (isTechnical && !(user.preferences['technical'] ?? true)) return false;
      }

      // 2) Takip edilenler filtresi
      if (showOnlyFollowed && user != null) {
        if (!n.followers.contains(user.uid)) return false;
      }

      // 3) Arama
      final q = searchQuery.toLowerCase();
      final matchesSearch =
          n.title.toLowerCase().contains(q) ||
              n.description.toLowerCase().contains(q);

      // 4) Durum / Tür
      final matchesStatus =
          selectedStatus == null || _normStatus(n.status) == selectedStatus!;
      final matchesType =
          selectedType == null || nType == selectedType!;

      return matchesSearch && matchesStatus && matchesType;
    }).toList();

    // ✅ ACİL duyurular ayrı
    final emergencyNotifs = filteredNotifications.where((n) => _norm(n.type) == "acil").toList();
    final normalNotifs = filteredNotifications.where((n) => _norm(n.type) != "acil").toList();

    // ✅ Görev-1: kullanıcı giriş yaptıktan sonra acil duyuru varsa HER GİRİŞTE 1 kere uyar
    if (myUid != null && emergencyNotifs.isNotEmpty && !_emergencySnackShown) {
      _emergencySnackShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnack("⚠️ ACİL duyurunuz var! Lütfen kontrol edin.", color: Colors.red.shade700);
      });
    }

    // ✅ Görev-SON: takip edilen bildirim status değişimini girişte kontrol et
    if (myUid != null && _prefsLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _checkFollowedStatusChangesOnLogin(all: notifVM.notifications, uid: myUid);
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Hoşgeldin,", style: TextStyle(fontSize: 14, color: Colors.grey)),
            Text(
              userName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => searchQuery = value),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: "Bildirimlerde ara...",
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _showFilterBottomSheet(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (selectedStatus != null || selectedType != null || showOnlyFollowed)
                          ? Colors.blueAccent
                          : Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.filter_list, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child: (emergencyNotifs.isEmpty && normalNotifs.isEmpty)
                  ? const Center(child: Text("Sonuç bulunamadı", style: TextStyle(color: Colors.grey)))
                  : ListView(
                children: [
                  // 🔴 ACİL DUYURULAR
                  if (emergencyNotifs.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "ACİL DUYURULAR",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    ...emergencyNotifs.map(
                          (notif) => GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => NotificationDetailPage(notification: notif)),
                        ),
                        child: _buildNotificationCard(context, notif, myUid, forceEmergencyStyle: true),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // 🟦 NORMAL LİSTE
                  ...normalNotifs.map(
                        (notif) => GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => NotificationDetailPage(notification: notif)),
                      ),
                      child: _buildNotificationCard(context, notif, myUid),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0D47A1),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddNewNotificationPage()),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Filtrele", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  const Text("Özel Filtre", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  FilterChip(
                    label: const Text("Sadece Takip Ettiklerim"),
                    selected: showOnlyFollowed,
                    onSelected: (val) => setState(() {
                      showOnlyFollowed = val;
                      setModalState(() {});
                    }),
                    selectedColor: Colors.blue.shade100,
                    checkmarkColor: Colors.blue,
                  ),

                  const SizedBox(height: 15),
                  const Text("Durum", style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: const [
                      {"label": "açık", "value": "acik"},
                      {"label": "inceleniyor", "value": "inceleniyor"},
                      {"label": "çözüldü", "value": "cozuldu"},
                    ].map((s) {
                      final v = s["value"]!;
                      return ChoiceChip(
                        label: Text(s["label"]!),
                        selected: selectedStatus == v,
                        onSelected: (val) => setState(() {
                          selectedStatus = val ? v : null;
                          setModalState(() {});
                        }),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 15),
                  const Text("Tür", style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: const [
                      {"label": "Acil Duyuru", "value": "acil"},
                      {"label": "Sağlık", "value": "saglik"},
                      {"label": "Kayıp", "value": "kayip"},
                      {"label": "Güvenlik", "value": "guvenlik"},
                      {"label": "Duyuru", "value": "duyuru"},
                      {"label": "Çevre", "value": "cevre"},
                      {"label": "Teknik Arıza", "value": "teknikariza"},
                      {"label": "Diğer", "value": "diger"},
                    ].map((t) {
                      final v = t["value"]!;
                      return ChoiceChip(
                        label: Text(t["label"]!),
                        selected: selectedType == v,
                        onSelected: (val) => setState(() {
                          selectedType = val ? v : null;
                          setModalState(() {});
                        }),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Uygula", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildNotificationCard(
      BuildContext context,
      NotificationModel notif,
      String? userId, {
        bool forceEmergencyStyle = false,
      }) {
    final notifVM = Provider.of<NotificationViewModel>(context, listen: false);
    final isFollowing = userId != null && notif.followers.contains(userId);

    final isEmergency = forceEmergencyStyle || _norm(notif.type) == "acil";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isEmergency ? Colors.red.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEmergency ? Colors.red.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isEmergency)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red.shade700, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    "ACİL DUYURU",
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  notif.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isEmergency ? Colors.red.shade900 : Colors.black,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  isFollowing ? Icons.bookmark : Icons.bookmark_border,
                  color: isFollowing ? Colors.deepPurple : Colors.grey,
                ),
                onPressed: () {
                  if (userId != null && notif.notifId != null) {
                    notifVM.toggleFollowNotification(notif.notifId!, userId);
                  }
                },
              ),
              const SizedBox(width: 8),
              Text(_formatDate(notif.date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 6),
          Text(notif.description, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _statusColor(notif.status), borderRadius: BorderRadius.circular(8)),
                child: Text(notif.status, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isEmergency ? Colors.red.shade700 : Colors.blue.shade400,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  notif.type,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (_normStatus(status)) {
      case "acik":
        return Colors.green;
      case "inceleniyor":
        return Colors.orange;
      case "cozuldu":
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatDate(Timestamp ts) {
    final d = ts.toDate();
    return "${d.day}.${d.month}.${d.year}";
  }
}
