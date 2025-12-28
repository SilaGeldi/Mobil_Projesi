// lib/views/auth/login_view.dart
import 'package:akilli_kampus_proje/views/main/main_screen.dart';
// lib/views/auth/login_view.dart
// Bu dosya uygulamanın giriş (login) ekranını içerir.
// Aşağıda kullanılan importlar ve sabitler açıklamalı şekilde verilmektedir.
import 'package:akilli_kampus_proje/views/main/main_screen.dart'; // Giriş sonrası yönlendirilecek ana ekran
import 'package:flutter/material.dart'; // Flutter temel bileşenleri
import 'package:provider/provider.dart'; // State management için Provider kullanıyoruz
import '../../view_models/auth_view_model.dart'; // Kimlik doğrulama işlemleri için view model
import 'register_view.dart'; // Kayıt sayfasına yönlendirme için

// Basit tema/sabit tanımları. Projede merkezi bir tema yoksa buradaki değerler kullanılır.
const Color kPrimaryColor = Color(0xFF1E88E5);
const Color kAccentColor = Color(0xFF4CAF50);
const Color kBackgroundColor = Color(0xFFF5F5F5);
const double kPadding = 30.0;
const double kBorderRadius = 12.0;

// Login ekranı stateful olarak tasarlandı çünkü kullanıcı giriş formu ve yüklenme durumu yönetiliyor.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // 1) Form alanlarını kontrol eden controller'lar.
  // Email ve şifre inputlarının değerlerini bu controller'lardan okuyup set edebiliriz.
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Form doğrulama için global key. FormState.validate() ile kuralları kontrol ederiz.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    // Controller'ları serbest bırakmak bellek sızıntısını önler.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 2) Giriş işlemini yapan yardımcı fonksiyon
  // Parametre olarak AuthViewModel alırız, böylece view model içindeki loginUser() çağrılır.
  void _handleLogin(AuthViewModel viewModel) async {
    // Önce form validasyonunu çalıştır: kurallara göre inputlar doğru mu?
    if (_formKey.currentState!.validate()) {
      // viewModel.loginUser(email, password) bool döndürürse başarılı/başarısız bilgisi alırız.
      bool success = await viewModel.loginUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (success && mounted) {
        // Başarılıysa kısa bir bilgi göster ve ana ekrana yönlendir.
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Giriş başarılı!')));

        // Rol bazlı yönlendirme örneği: burada aynı ekrana gidiyor ama istenirse admin farklı sayfaya yönlendirilebilir.
        final role = viewModel.currentUser?.role;
        if (role == 'admin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
        }
      } else if (viewModel.errorMessage != null && mounted) {
        // Eğer view model hata mesajı ayarladıysa kullanıcıya göster ve hatayı temizle
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: ${viewModel.errorMessage}')));
        viewModel.clearError();
      }
    }
  }

  // 3) Şifre sıfırlama işlemi (burada simülasyon/örnek gösterim maksatlı)
  // Gerçek dünyada resetPassword backend çağrısı yapılır; burada viewModel üzerinden benzer davranış gösteriliyor.
  void _handlePasswordReset(AuthViewModel viewModel) async {
    // Basit doğrulama: e-posta alanı dolu mu ve '@' içeriyor mu
    if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şifre sıfırlama için geçerli bir e-posta girin.')));
      return;
    }

    try {
      // Eğer view model yükleniyor durumu yönetiyorsa, onu açıyoruz
      viewModel.setIsLoading(true);

      // ViewModel üzerinden şifre sıfırlama çağrısı (simülasyon/async)
      await viewModel.resetPassword(email: _emailController.text.trim());

      // Başarı mesajını dialog ile gösteriyoruz; gerçek uygulamada kullanıcı mailini kontrol eder.
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Şifre Sıfırlama'),
              content: Text('Şifre sıfırlama bağlantısı ${_emailController.text} adresine başarıyla gönderilmiştir (Simülasyon).'),
              actions: <Widget>[
                TextButton(child: const Text('Tamam'), onPressed: () => Navigator.of(context).pop()),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Hata durumunda snack ile göster
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Şifre sıfırlama başarısız: ${e.toString()}')));
    } finally {
      // Yükleniyor durumunu kapat
      viewModel.setIsLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // AuthViewModel'i provider üzerinden alıyoruz; isLoading, loginUser vb. fonksiyonlar buradan gelir
    final authViewModel = Provider.of<AuthViewModel>(context);

    // Sayfa tasarımı: ortalanmış bir form kartı içinde inputlar ve butonlar
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(title: const Text('Giriş Yap'), backgroundColor: kPrimaryColor, elevation: 0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(kPadding),
          child: Container(
            padding: const EdgeInsets.all(kPadding),
            // Kart görünümü: beyaz arka plan, yuvarlak köşe ve gölge
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(kBorderRadius),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.15), spreadRadius: 5, blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Sayfa başlığı
                  const Text('Akıllı Kampüs Giriş', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kPrimaryColor), textAlign: TextAlign.center),
                  const SizedBox(height: 30),

                  // 1) E-posta alanı: validator ile basit e-posta kontrolü yapılır
                  _buildTextFormField(
                    controller: _emailController,
                    label: 'Kurumsal E-posta',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value == null || !value.contains('@') ? 'Geçerli bir e-posta girin' : null,
                  ),
                  const SizedBox(height: 16),

                  // 2) Şifre alanı: en az 6 karakter kuralı uygulanır
                  _buildTextFormField(
                    controller: _passwordController,
                    label: 'Şifre',
                    icon: Icons.lock,
                    obscureText: true,
                    validator: (value) => value == null || value.length < 6 ? 'Şifre en az 6 karakter olmalıdır' : null,
                  ),
                  const SizedBox(height: 30),

                  // Giriş butonu veya yükleniyor göstergesi
                  authViewModel.isLoading
                      ? const Center(child: CircularProgressIndicator(color: kAccentColor))
                      : ElevatedButton(
                          onPressed: () => _handleLogin(authViewModel),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kAccentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadius)),
                            elevation: 3,
                          ),
                          child: const Text('Giriş Yap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                  const SizedBox(height: 10),

                  // Şifremi unuttum linki: e-posta girilerek şifre sıfırlama tetiklenir
                  TextButton(onPressed: () => _handlePasswordReset(authViewModel), child: const Text('Şifremi Unuttum?', style: TextStyle(color: kPrimaryColor))),
                  const SizedBox(height: 10),

                  // Kayıt sayfasına yönlendirme
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const RegisterView())),
                    child: const Text('Yeni Hesap Oluştur', style: TextStyle(color: kPrimaryColor)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Yardımcı: TextFormField oluşturmak için parametreli fonksiyon
  // Böylece tekrar eden dekorasyon kodunu tek yerde tutuyoruz.
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      cursorColor: kPrimaryColor,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kPrimaryColor),
        prefixIcon: Icon(icon, color: kPrimaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(kBorderRadius / 2), borderSide: const BorderSide(color: kPrimaryColor, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kBorderRadius / 2), borderSide: const BorderSide(color: kAccentColor, width: 2.0)),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      ),
    );
  }
}