import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../providers/withdrawal_provider.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isResettingPassword = false;

  void _showEditProfileBottomSheet(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 28,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE4E4E7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Row(
                      children: [
                        Icon(Icons.edit_rounded, color: Color(0xFF09090B), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Ubah Data Profil',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF09090B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      style: const TextStyle(color: Color(0xFF09090B), fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap',
                        labelStyle: const TextStyle(color: Color(0xFF71717A)),
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF09090B)),
                        filled: true,
                        fillColor: const Color(0xFFF4F4F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama lengkap tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Color(0xFF09090B), fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Nomor Telepon / WhatsApp',
                        labelStyle: const TextStyle(color: Color(0xFF71717A)),
                        prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF09090B)),
                        filled: true,
                        fillColor: const Color(0xFFF4F4F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF09090B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (formKey.currentState?.validate() ?? false) {
                                  setModalState(() => isSaving = true);
                                  final success = await authProvider.updateProfile(
                                    fullName: nameController.text.trim(),
                                    phone: phoneController.text.trim(),
                                    avatarUrl: user.avatarUrl,
                                  );
                                  setModalState(() => isSaving = false);

                                  if (modalContext.mounted) {
                                    Navigator.pop(modalContext);
                                  }

                                  if (context.mounted) {
                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Profil berhasil diperbarui!'),
                                          backgroundColor: Color(0xFF09090B),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(authProvider.errorMessage ?? 'Gagal memperbarui profil'),
                                          backgroundColor: const Color(0xFFEF4444),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Simpan Perubahan',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handlePasswordReset(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = authProvider.user?.email;
    if (email == null) return;

    setState(() => _isResettingPassword = true);
    final result = await authProvider.forgotPassword(email);
    setState(() => _isResettingPassword = false);

    if (context.mounted) {
      if (result['success'] == true) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Row(
              children: [
                Icon(Icons.mark_email_read_rounded, color: Color(0xFF059669)),
                SizedBox(width: 8),
                Text('Tautan Terkirim', style: TextStyle(color: Color(0xFF09090B), fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'Tautan pemulihan kata sandi telah dikirimkan ke $email. Silakan periksa kotak masuk atau folder spam Anda.',
              style: const TextStyle(color: Color(0xFF71717A), fontSize: 13),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF09090B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal mengirim permintaan reset kata sandi.'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF09090B)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF09090B)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Profil & Akun Organizer',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF09090B)),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF09090B),
        onRefresh: () async {
          await authProvider.initAuth();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Identity Card (Borderless, shadowless container with soft contrast surface)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Avatar Circle with photo or initials
                        UserAvatar(
                          avatarUrl: user.avatarUrl,
                          name: user.name,
                          size: 64,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF09090B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.email,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF71717A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Text(
                                  user.role.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // User UUID with copy action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'User ID:',
                          style: TextStyle(color: Color(0xFF71717A), fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: user.id));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('User ID disalin ke clipboard!'),
                                    backgroundColor: Color(0xFF09090B),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          user.id,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            color: Color(0xFF09090B),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF09090B)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Account Management Actions
              const Text(
                'Pengaturan Akun',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF09090B),
                ),
              ),
              const SizedBox(height: 10),

              // Account Settings Tile Container
              Material(
                color: const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline_rounded, color: Color(0xFF09090B)),
                      title: const Text('Informasi Profil', style: TextStyle(color: Color(0xFF09090B), fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nama: ${user.name}',
                              style: const TextStyle(color: Color(0xFF71717A), fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Telp: ${(user.phone != null && user.phone!.isNotEmpty) ? user.phone! : '-'}',
                              style: const TextStyle(color: Color(0xFF71717A), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFA1A1AA)),
                      onTap: () => _showEditProfileBottomSheet(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.lock_reset_rounded, color: Color(0xFF09090B)),
                      title: const Text('Reset Kata Sandi', style: TextStyle(color: Color(0xFF09090B), fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Kirim tautan pembaruan kata sandi ke email', style: TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                      trailing: _isResettingPassword
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Color(0xFF09090B), strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, color: Color(0xFF09090B), size: 18),
                      onTap: _isResettingPassword ? null : () => _handlePasswordReset(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Logout Button (Filled soft red tint, no stroke, no shadow)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
                  label: const Text(
                    'Keluar dari Akun',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEF2F2),
                    foregroundColor: const Color(0xFFEF4444),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        title: const Text(
                          'Keluar dari Akun?',
                          style: TextStyle(color: Color(0xFF09090B), fontWeight: FontWeight.bold),
                        ),
                        content: const Text(
                          'Anda akan keluar dari sesi akun organizer pada aplikasi ini.',
                          style: TextStyle(color: Color(0xFF71717A), fontSize: 13),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Batal', style: TextStyle(color: Color(0xFF71717A), fontWeight: FontWeight.bold)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: const StadiumBorder(),
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      Provider.of<EventProvider>(context, listen: false).clearData();
                      Provider.of<WithdrawalProvider>(context, listen: false).clearData();
                      await authProvider.logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    }
                  },
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
