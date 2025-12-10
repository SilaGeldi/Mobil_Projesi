// lib/views/auth/register_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/auth_view_model.dart';
import 'login_view.dart'; // Göreceli yoldan import ediyoruz

// Modern Uygulama İçin Tema Tanımları (Burada tutmak yerine ayrı bir tema dosyası önerilir)
const Color kPrimaryColor = Color(0xFF1E88E5); // Mavi tonu (Başlık)
const Color kAccentColor = Color(0xFF4CAF50); // Parlak yeşil (Buton vurgusu)
const Color kBackgroundColor = Color(0xFFF5F5F5); // Açık gri arka plan
const double kPadding = 30.0;
const double kBorderRadius = 12.0;


class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  // 1. Text Controller'ları Tanımlama
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // Form doğrulama için

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  // 2. Kayıt İşlemi Fonksiyonu (Düzeltilmiş Yönlendirme ve Mesaj Mantığı)
  void _handleRegister(AuthViewModel viewModel) async {
    if (_formKey.currentState!.validate()) {
      bool success = await viewModel.registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        unit: _unitController.text.trim(),
      );

      // Oturum kapatma (signOut) işlemi View Model'de yapıldığı için, 
      // burada sadece başarıyı kontrol edip yönlendirme yapıyoruz.
      if (success && mounted) {
        // 1. Başarı Mesajı
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt başarılı! Lütfen yeni hesabınızla giriş yapın.')),
        );

        // 2. LoginView'a Manuel ve Zorunlu Yönlendirme
        // pushReplacement kullanmak, geri tuşuna basıldığında kayıt sayfasına dönülmesini engeller.
       Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const LoginView()),
);

      } else if (viewModel.errorMessage != null && mounted) {
        // Hata mesajını gösterme (örn: 'email-already-in-use')
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt Hatası: ${viewModel.errorMessage}')),
        );
        viewModel.clearError(); // Hata mesajını temizle
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Akıllı Kampüs Kayıt'),
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
                    'Hesap Oluştur',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // 1. Ad-Soyad Alanı
                  _buildTextFormField(
                    controller: _nameController,
                    label: 'Ad Soyad',
                    icon: Icons.person,
                    validator: (value) => value == null || value.isEmpty ? 'Ad ve soyad zorunludur' : null,
                  ),
                  const SizedBox(height: 16),

                  // 2. E-posta Alanı
                  _buildTextFormField(
                    controller: _emailController,
                    label: 'Kurumsal E-posta',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value == null || !value.contains('@') ? 'Geçerli bir e-posta girin' : null,
                  ),
                  const SizedBox(height: 16),

                  // 3. Şifre Alanı
                  _buildTextFormField(
                    controller: _passwordController,
                    label: 'Şifre (En az 6 karakter)',
                    icon: Icons.lock,
                    obscureText: true,
                    validator: (value) => value == null || value.length < 6 ? 'Şifre en az 6 karakter olmalıdır' : null,
                  ),
                  const SizedBox(height: 16),

                  // 4. Birim Alanı
                  _buildTextFormField(
                    controller: _unitController,
                    label: 'Birim/Fakülte',
                    icon: Icons.school,
                    validator: (value) => value == null || value.isEmpty ? 'Birim bilgisi zorunludur' : null,
                  ),
                  const SizedBox(height: 40),

                  // Kayıt Butonu
                  authViewModel.isLoading
                      ? const Center(child: CircularProgressIndicator(color: kAccentColor))
                      : ElevatedButton(
                          onPressed: () => _handleRegister(authViewModel),
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
                            'Kayıt Ol',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                  const SizedBox(height: 20),

                  // Giriş sayfasına geçiş
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const LoginView()),
                      );
                    },
                    child: const Text(
                      'Zaten hesabım var, Giriş Yap',
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

  // Modern TextFormField yapısını oluşturan yardımcı fonksiyon
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