import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  void _showServerSettingsDialog() {
    final controller = TextEditingController(text: ApiConfig.host);
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Pengaturan Server Host',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Color(0xFF09090B),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sesuaikan host backend untuk pengujian di ponsel fisik (misal: IP Wi-Fi laptop atau localhost jika pakai adb reverse).',
                style: TextStyle(color: Color(0xFF71717A), fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: false,
                decoration: InputDecoration(
                  labelText: 'Host / IP Server',
                  hintText: '192.168.0.130 atau localhost',
                  filled: true,
                  fillColor: const Color(0xFFF4F4F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Pilihan Cepat:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF71717A),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text('192.168.0.130 (Wi-Fi)'),
                    shape: const StadiumBorder(),
                    backgroundColor: const Color(0xFFF4F4F5),
                    labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF09090B)),
                    onPressed: () {
                      controller.text = '192.168.0.130';
                    },
                  ),
                  ActionChip(
                    label: const Text('localhost (ADB Reverse)'),
                    shape: const StadiumBorder(),
                    backgroundColor: const Color(0xFFF4F4F5),
                    labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF09090B)),
                    onPressed: () {
                      controller.text = 'localhost';
                    },
                  ),
                  ActionChip(
                    label: const Text('10.0.2.2 (Emulator)'),
                    shape: const StadiumBorder(),
                    backgroundColor: const Color(0xFFF4F4F5),
                    labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF09090B)),
                    onPressed: () {
                      controller.text = '10.0.2.2';
                    },
                  ),
                ],
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Batal', style: TextStyle(color: Color(0xFF71717A))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF09090B),
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              onPressed: () async {
                final newHost = controller.text.trim();
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(dialogCtx);
                await ApiConfig.setCustomHost(newHost.isEmpty ? null : newHost);
                if (!mounted) return;
                setState(() {});
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Host berhasil diubah ke: ${ApiConfig.host}'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              child: const Text('Simpan Host'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Pengaturan Server Host',
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF09090B)),
            onPressed: _showServerSettingsDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / Icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F5),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE4E4E7)),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 40,
                        color: Color(0xFF09090B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // App Title
                  Text(
                    'Entra',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF09090B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Masuk untuk mengelola event & check-in peserta',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF71717A),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Error Banner
                  if (authProvider.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              authProvider.errorMessage!,
                              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Email Input
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Color(0xFF09090B), fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Email Organizer',
                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF71717A), size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF09090B), width: 1.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email wajib diisi';
                      }
                      if (!value.contains('@')) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Input
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Color(0xFF09090B), fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF71717A), size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: const Color(0xFF71717A),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF09090B), width: 1.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Submit Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF09090B),
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Masuk ke Dashboard',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Server host indicator / quick config
                  Center(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _showServerSettingsDialog,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Server: ${ApiConfig.host}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF71717A),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.edit_outlined,
                              size: 13,
                              color: Color(0xFF71717A),
                            ),
                          ],
                        ),
                      ),
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
}
