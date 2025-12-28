// Bu dosya uygulamanın ana bildirim listesini gösteren sayfasıdır.
// Aşağıdaki importlar, bu dosyada kullanılan kütüphaneleri ve
// uygulama içi modelleri / view modelleri getirir.
// Her bir importun ne işe yaradığını alt satırlarda açıklıyorum.
import 'dart:convert'; // JSON encode/decode işlemleri için kullanılır. Map'i string'e çevirip kaydetmek veya tersini yapmak için.
import 'package:flutter/material.dart'; // Flutter'ın temel UI bileşenleri, widget'lar, temalar vs. için gereklidir.
import 'package:provider/provider.dart'; // State management için Provider kullanılıyor; view model'leri dinlemek için.
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore'un Timestamp tipi kullanılıyor; veritabanı ile iletişim için.
import 'package:shared_preferences/shared_preferences.dart'; // Cihazda küçük ayar/önbellek tutmak için kullanılır.

// Uygulama içi view model ve model importları
import '../../view_models/notification_view_model.dart'; // Bildirim verilerini yöneten view model
import '../../view_models/auth_view_model.dart'; // Kullanıcı kimlik doğrulama bilgilerini yöneten view model
import '../../models/notification_model.dart'; // Bildirim verisi için kullanılan model sınıfı
import 'add_new_notif_page.dart'; // Yeni bildirim ekleme sayfası
import 'notification_detail_page.dart'; // Bildirim detaylarını gösteren sayfa

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Arama çubuğuna girilen metni tutar. Boş ise tüm sonuçlar gösterilir.
  String searchQuery = "";

  // Seçili durum filtresi: örn "acik", "inceleniyor", "cozuldu" gibi normalize edilmiş değerler tutulur.
  String? selectedStatus;

  // Seçili tür filtresi: örn "kayip", "teknikariza" vb. normalize edilmiş değerler tutulur.
  String? selectedType;

  // Sadece takip ettiklerimi göster filtresi: true ise yalnızca takip edilen bildirimler görünür.
  bool showOnlyFollowed = false;

  // Acil duyuru uyarısını her kullanıcı girişi için yalnızca bir kere göstermek için kullanılan bayrak.
  // Eğer true ise o giriş için acil duyuru gösterimi yapılmış demektir.
  bool _emergencySnackShown = false;

  // Takip edilen bildirimlerin son görülen durumlarını saklamak için hafızadaki map.
  // Anahtar: bildirim id'si, değer: son görülen normalize edilmiş durum string'i.
  Map<String, String> _lastSeenFollowedStatus = {};

  // Aynı oturumda birden fazla kez aynı durum değişikliğinin bildirimini göstermemek için kullanılan set.
  // Değer olarak "<id>:<eski>-><yeni>" biçiminde anahtarlar tutulur.
  final Set<String> _shownStatusChangeKeysThisSession = {};

  // Son bilinen kullanıcı id'si; kullanıcı değişirse ilgili reset işlemleri yapılır.
  String? _lastUserId;

  // SharedPreferences'tan veriler yüklenip yüklenmediğini gösterir. Yüklenmeden kıyaslama yapılmaz.
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    // initState içinde hemen user bilgisi gelmeyebilir; kullanıcı bilgisi build sırasında gelir.
    // Bu yüzden kullanıcıya bağlı bazı yüklemeleri build içinde, user geldiğinde yapıyoruz.
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
    // SharedPreferences örneğini alıyoruz; bu telefon hafızasındaki küçük anahtar-değer deposudur.
    final prefs = await SharedPreferences.getInstance();

    // Kullanıcıya özel anahtardan daha önce kaydedilmiş map string'ini alıyoruz.
    final raw = prefs.getString(_prefsKeyForUser(uid));

    // Eğer hiç kaydedilmemişse boş bir map ile başlıyoruz.
    if (raw == null || raw.isEmpty) {
      _lastSeenFollowedStatus = {};
    } else {
      // Eğer kaydedilmiş bir veri varsa, JSON string'ini Map'e çeviriyoruz.
      // Hata ihtimaline karşı try-catch ile sarmalıyoruz; bozuk veri varsa sıfırlıyoruz.
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        // dynamic değerleri string'e çevirip Map<String,String> olarak saklıyoruz.
        _lastSeenFollowedStatus = decoded.map((k, v) => MapEntry(k, v.toString()));
      } catch (_) {
        _lastSeenFollowedStatus = {};
      }
    }

    // Prefs yükleme tamamlandı olarak işaretle.
    _prefsLoaded = true;
  }

  /// ✅ Güncel takip-status map’ini telefona kaydet
  Future<void> _saveLastSeenFollowedStatus(String uid, Map<String, String> map) async {
    // Verilen map'i JSON string'e çevirip SharedPreferences'a kaydeder.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyForUser(uid), jsonEncode(map));
  }

  /// ✅ Görev: Takip edilen bildirimin durumu değişince (girişte) uyarı göster
  Future<void> _checkFollowedStatusChangesOnLogin({
    required List<NotificationModel> all,
    required String uid,
  }) async {
    // SharedPreferences henüz yüklenmemişse herhangi bir kıyaslama yapmayız.
    if (!_prefsLoaded) return;

    // Tüm bildirimler arasından, bu kullanıcının takip ettiği bildirimleri seçiyoruz.
    final followed = all.where((n) => n.notifId != null && n.followers.contains(uid)).toList();

    // Bu giriş anındaki güncel durumların anlık görüntüsünü tutacağız.
    final Map<String, String> currentSnapshot = {};

    // Her takip edilen bildirim için önceki görülen durum ile şimdiki durumu karşılaştır.
    for (final n in followed) {
      final id = n.notifId!; // notifId null olmadığı için güvenle kullandık.
      final newSt = _normStatus(n.status); // Mevcut durumu normalize et.

      // Bu anlık görüntüye kaydet.
      currentSnapshot[id] = newSt;

      // Hafızadaki (telefonda saklı) önceki durumu al.
      final oldSt = _lastSeenFollowedStatus[id];

      // Eğer daha önce hiç görmediysek, ilk kez görüldüğü için bildirim gösterme, sadece kaydet.
      if (oldSt == null) continue;

      // Eğer durum değişmişse kullanıcıyı uyaracağız.
      if (oldSt != newSt) {
        // Aynı değişiklik için birden fazla uyarı göstermemek adına benzersiz bir anahtar oluştur.
        final key = "$id:$oldSt->$newSt";

        // Bu oturumda zaten gösterildiyse atla.
        if (_shownStatusChangeKeysThisSession.contains(key)) continue;
        _shownStatusChangeKeysThisSession.add(key);

        // Kullanıcı arayüzü güncellemesi yapmak için sonraki frame'e bir callback ekliyoruz.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSnack(
            // Kullanıcıya gösterilecek kısa metin. UI metinlerinde emoji kullanılabilir.
            "Takip ettiğin bildirim güncellendi: \"${n.title}\" → Durum: ${n.status}",
            color: Colors.deepPurple,
          );
        });
      }
    }

    // Giriş kontrolü tamamlandığında yeni snapshot'u telefona kaydet.
    await _saveLastSeenFollowedStatus(uid, currentSnapshot);

    // Bellekteki (RAM) map'i de güncelle ki sonraki kıyas doğru olsun.
    _lastSeenFollowedStatus = currentSnapshot;
  }

  /// ✅ Kullanıcı değişince (logout/login) state reset + prefs yükle
  Future<void> _handleUserChanged(String uid) async {
    // Kullanıcı değiştiği için önce son bilinen kullanıcı id'sini güncelle.
    _lastUserId = uid;

    // Yeni girişte acil duyuru uyarısını tekrar gösterebilmek için sıfırla.
    _emergencySnackShown = false;

    // Bu oturumda gösterilmiş durum değişikliği uyarılarını temizle.
    _shownStatusChangeKeysThisSession.clear();

    // SharedPreferences'tan gelen veriler yeniden yüklenecek; önce işaretleri temizle.
    _prefsLoaded = false;
    _lastSeenFollowedStatus = {};

    // Telefonda saklı olan en son görülen durumları yükle.
    await _loadLastSeenFollowedStatus(uid);
  }

  @override
  Widget build(BuildContext context) {
    final notifVM = context.watch<NotificationViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.currentUser;
    final myUid = user?.uid;
    final userName = capitalize(user?.name ?? "Kullanıcı");
    // Eğer build sırasında kullanıcı değiştiyse (ör. login olduysa), ilgili resetleri yap.
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
        // Kullanıcı giriş yaptıktan sonra eğer acil duyuru varsa, bunu bir kere göstermek için snack ekliyoruz.
        // (UI metninde emoji kullanılabilir; yorum satırlarında emoji yok.)
        _showSnack("ACIL duyurunuz var! Lütfen kontrol edin.", color: Colors.red.shade700);
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
            // Üstte küçük bir hoşgeldin yazısı gösterilir.
            const Text("Hoşgeldin,", style: TextStyle(fontSize: 14, color: Colors.grey)),
            // Alt satırda kullanıcının adı büyük ve kalın şekilde gösterilir.
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
                    // Arama çubuğuna yazıldıkça searchQuery güncellenir ve setState ile UI yenilenir.
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

            // Liste alanı genişleyerek geri kalan alanı kaplar.
            Expanded(
              child: (emergencyNotifs.isEmpty && normalNotifs.isEmpty)
                  // Eğer filtre sonucu boşsa kullanıcıya bilgi göster.
                  ? const Center(child: Text("Sonuç bulunamadı", style: TextStyle(color: Colors.grey)))
                  // Aksi halde result listesi gösterilir.
                  : ListView(
                      children: [
                        // ACIL duyuruları ayrı bir başlıkla öne çıkarılır.
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
                          // Her acil bildirim için kart oluştur ve detay sayfasına yönlendir.
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

                        // Normal bildirimler listesi
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
                  // Başlık
                  const Text("Filtrele", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // Özel filtre: sadece takip edilenleri göster
                  const Text("Özel Filtre", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  FilterChip(
                    label: const Text("Sadece Takip Ettiklerim"),
                    // Eğer kullanıcı takip ettiklerini görmek isterse showOnlyFollowed true olur.
                    selected: showOnlyFollowed,
                    onSelected: (val) => setState(() {
                      showOnlyFollowed = val; // Ana state'i güncelle
                      setModalState(() {}); // Modal içindeki state'i de güncelle
                    }),
                    selectedColor: Colors.blue.shade100,
                    checkmarkColor: Colors.blue,
                  ),

                  const SizedBox(height: 15),
                  // Durum filtresi: açık / inceleniyor / çözüldü
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
                          // Seçili durum değişirse selectedStatus güncellenir veya temizlenir.
                          selectedStatus = val ? v : null;
                          setModalState(() {});
                        }),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 15),
                  // Tür filtresi: duyuru, acil, teknik arıza vb.
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
                          // Tür seçimi yapıldığında selectedType güncellenir veya temizlenir.
                          selectedType = val ? v : null;
                          setModalState(() {});
                        }),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),
                  // Uygula butonu modalı kapatır ve filtreler main state'te zaten güncellenmiştir.
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
          // Eğer bildirim acil ise başlık kısmında özel gösterim yap.
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
                    // Takip etme / takibi bırakma işlemi view model üzerinden tetiklenir.
                    notifVM.toggleFollowNotification(notif.notifId!, userId);
                  }
                },
              ),
              const SizedBox(width: 8),
              Text(_formatDate(notif.date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 6),
          // Bildirim açıklamasının kısa bir ön izlemesi.
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
