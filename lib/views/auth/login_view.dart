// lib/views/auth/login_view.dart
import 'package:akilli_kampus_proje/views/main/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/auth_view_model.dart';
import 'register_view.dart'; // Kayıt sayfasına yönlendirme için

// Tema tanımlarını RegisterView'dan alıyoruz (ÖNEMLİ: Kendi tema dosyanız yoksa!)
const Color kPrimaryColor = Color(0xFF1E88E5);
const Color kAccentColor = Color(0xFF4CAF50);
const Color kBackgroundColor = Color(0xFFF5F5F5);
const double kPadding = 30.0;
const double kBorderRadius = 12.0;

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // 1. Text Controller'ları Tanımlama
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

// lib/views/auth/login_view.dart (Sadece _handleLogin fonksiyonunu güncelle)

  // 2. Giriş İşlemi Fonksiyonu
// lib/views/auth/login_view.dart (Sadece _handleLogin fonksiyonunu güncelle)

  void _handleLogin(AuthViewModel viewModel) async {
    if (_formKey.currentState!.validate()) {
      bool success = await viewModel.loginUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giriş başarılı!')),
        );

        // 🔹 Rol bilgisine göre yönlendirme:
        final role = viewModel.currentUser?.role;
        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      } else if (viewModel.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${viewModel.errorMessage}')),
        );
        viewModel.clearError();
      }
    }
  }



// 3. Şifre Sıfırlama İşlemi (Simülasyon)
  void _handlePasswordReset(AuthViewModel viewModel) async {
    if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifre sıfırlama için geçerli bir e-posta girin.')),
      );
      return;
    }

    try {
      // Yükleniyor durumunu yönetmek için:
      viewModel.setIsLoading(true); // <--- AuthViewModel'e eklenmesi gereken metot (Aşağıda detaylı)

      await viewModel.resetPassword(email: _emailController.text.trim());

      // Simülasyon mesajını AlertDialog ile göster
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Şifre Sıfırlama'),
              content: Text('Şifre sıfırlama bağlantısı ${_emailController.text} adresine başarıyla gönderilmiştir (Simülasyon).'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Tamam'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Şifre sıfırlama başarısız: ${e.toString()}')),
        );
      }
    } finally {
      viewModel.setIsLoading(false); // Yükleniyor durumunu kapat
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Giriş Yap'),
        backgroundColor: kPrimaryColor,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(kPadding),
          child: Container(
            padding: const EdgeInsets.all(kPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(kBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  spreadRadius: 5,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // BAŞLIK
                  const Text(
                    'Akıllı Kampüs Giriş',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // 1. E-posta Alanı
                  _buildTextFormField(
                    controller: _emailController,
                    label: 'Kurumsal E-posta',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value == null || !value.contains('@') ? 'Geçerli bir e-posta girin' : null,
                  ),
                  const SizedBox(height: 16),

                  // 2. Şifre Alanı
                  _buildTextFormField(
                    controller: _passwordController,
                    label: 'Şifre',
                    icon: Icons.lock,
                    obscureText: true,
                    validator: (value) => value == null || value.length < 6 ? 'Şifre en az 6 karakter olmalıdır' : null,
                  ),
                  const SizedBox(height: 30),

                  // Giriş Butonu
                  authViewModel.isLoading
                      ? const Center(child: CircularProgressIndicator(color: kAccentColor))
                      : ElevatedButton(
                    onPressed: () => _handleLogin(authViewModel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                      ),
                      elevation: 3,
                    ),
                    child: const Text(
                      'Giriş Yap',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Şifre Sıfırlama Alanı (Proje Gereksinimi)
                  TextButton(
                    onPressed: () => _handlePasswordReset(authViewModel),
                    child: const Text(
                      'Şifremi Unuttum?',
                      style: TextStyle(color: kPrimaryColor),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Kayıt sayfasına geçiş
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const RegisterView()),
                      );
                    },
                    child: const Text(
                      'Yeni Hesap Oluştur',
                      style: TextStyle(color: kPrimaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // RegisterView'dan kopyalanan yardımcı fonksiyon
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kBorderRadius / 2),
          borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kBorderRadius / 2),
          borderSide: const BorderSide(color: kAccentColor, width: 2.0),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      ),
    );
  }
}