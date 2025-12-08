// lib/views/auth/register_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/auth_view_model.dart';
import 'package:akilli_kampus_proje/views/auth/login_view.dart'; // Giriş sayfasına yönlendirme için

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

  // 2. Kayıt İşlemi Fonksiyonu
  void _handleRegister(AuthViewModel viewModel) async {
    if (_formKey.currentState!.validate()) {
      bool success = await viewModel.registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        unit: _unitController.text.trim(),
      );

      if (success && mounted) {
        // Kayıt başarılı olduysa, main.dart'taki Consumer otomatik olarak yönlendirecektir.
        // Kullanıcıya bilgi mesajı verebiliriz.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt başarılı! Giriş sayfasına yönlendiriliyorsunuz.')),
        );
      } else if (viewModel.errorMessage != null && mounted) {
        // Hata mesajını gösterme
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt Hatası: ${viewModel.errorMessage}')),
        );
        viewModel.clearError(); // Hata mesajını temizle
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // AuthViewModel'e erişim
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Kayıt Oluştur')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Ad-Soyad Alanı
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Ad Soyad'),
                  validator: (value) => value == null || value.isEmpty ? 'Ad ve soyad zorunludur' : null,
                ),
                const SizedBox(height: 16),

                // E-posta Alanı
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-posta'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value == null || !value.contains('@') ? 'Geçerli bir e-posta girin' : null,
                ),
                const SizedBox(height: 16),

                // Şifre Alanı
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Şifre (En az 6 karakter)'),
                  obscureText: true,
                  validator: (value) => value == null || value.length < 6 ? 'Şifre en az 6 karakter olmalıdır' : null,
                ),
                const SizedBox(height: 16),

                // Birim Alanı
                TextFormField(
                  controller: _unitController,
                  decoration: const InputDecoration(labelText: 'Birim (Örn: Fakülte Adı)'),
                  validator: (value) => value == null || value.isEmpty ? 'Birim bilgisi zorunludur' : null,
                ),
                const SizedBox(height: 32),

                // Kayıt Butonu
                authViewModel.isLoading
                    ? const CircularProgressIndicator() // İşlem sürüyorsa yükleniyor göster
                    : ElevatedButton(
                        onPressed: () => _handleRegister(authViewModel),
                        child: const Text('Kayıt Ol'),
                      ),
                const SizedBox(height: 20),

                // Giriş sayfasına geçiş
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const LoginView()),
                    );
                  },
                  child: const Text('Zaten hesabım var, Giriş Yap'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}