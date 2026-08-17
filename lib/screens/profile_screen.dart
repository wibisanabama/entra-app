import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../providers/withdrawal_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isResettingPassword = false;

  String _formatCurrency(dynamic amount) {
    num val = 0;
    if (amount is num) val = amount;
    if (amount is String) val = num.tryParse(amount) ?? 0;
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(val);
  }

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
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
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
                          color: Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Icon(Icons.edit_rounded, color: Color(0xFF7C3AED), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Ubah Data Profil',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap',
                        labelStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF7C3AED)),
                        filled: true,
                        fillColor: const Color(0xFF030712),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade800),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade800),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama lengkap tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nomor Telepon / WhatsApp',
                        labelStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF7C3AED)),
                        filled: true,
                        fillColor: const Color(0xFF030712),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade800),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade800),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (formKey.currentState?.validate() ?? false) {
                                  setModalState(() => isSaving = true);
                                  final success = await authProvider.updateProfile(
                                    fullName: nameController.text.trim(),
                                    phone: phoneController.text.trim(),
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
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(authProvider.errorMessage ?? 'Gagal memperbarui profil'),
                                          backgroundColor: Colors.redAccent,
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
            backgroundColor: const Color(0xFF111827),
            title: const Row(
              children: [
                Icon(Icons.mark_email_read_rounded, color: Colors.green),
                SizedBox(width: 8),
                Text('Tautan Terkirim', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Text(
              'Tautan pemulihan kata sandi telah dikirimkan ke $email. Silakan periksa kotak masuk atau folder spam Anda.',
              style: TextStyle(color: Colors.grey.shade300, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Mengerti', style: TextStyle(color: Color(0xFF7C3AED))),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal mengirim permintaan reset kata sandi.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final eventProvider = Provider.of<EventProvider>(context);
    final withdrawalProvider = Provider.of<WithdrawalProvider>(context);

    final user = authProvider.user;
    final stats = eventProvider.stats;
    final balance = withdrawalProvider.balance;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: const Color(0xFF030712),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Profil & Akun Organizer',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (authProvider.token != null) {
            await Future.wait([
              eventProvider.fetchDashboardData(authProvider.token!),
              withdrawalProvider.fetchBalanceAndWithdrawals(authProvider.token!),
            ]);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Identity Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF7C3AED).withValues(alpha: 0.25),
                      const Color(0xFF111827),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Avatar Circle
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF7C3AED),
                            border: Border.all(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.8),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : 'O',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
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
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.email,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  user.role.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.greenAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 8),
                    // User UUID with copy action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'User ID:',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: user.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('User ID disalin ke clipboard!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Text(
                                '${user.id.substring(0, 8)}...',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  color: Color(0xFF7C3AED),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF7C3AED)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3 Quick Metrics
              const Text(
                'Ringkasan Finansial & Operasional',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Saldo Bersih', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                          const SizedBox(height: 4),
                          Text(
                            _formatCurrency(balance.availableBalance),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tiket Terjual', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                          const SizedBox(height: 4),
                          Text(
                            '${stats['tickets_sold'] ?? 0}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Event Aktif', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                          const SizedBox(height: 4),
                          Text(
                            '${eventProvider.events.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Account Management Actions
              const Text(
                'Pengaturan Akun',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 10),

              // Edit Personal Info Tile
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline_rounded, color: Color(0xFF7C3AED)),
                      title: const Text('Informasi Profil', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        'Nama: ${user.name} • Telp: ${user.phone ?? '-'}',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      onTap: () => _showEditProfileBottomSheet(context),
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    ListTile(
                      leading: const Icon(Icons.lock_reset_rounded, color: Color(0xFF7C3AED)),
                      title: const Text('Reset Kata Sandi', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text('Kirim tautan pembaruan kata sandi ke email', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                      trailing: _isResettingPassword
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Color(0xFF7C3AED), strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, color: Color(0xFF7C3AED), size: 18),
                      onTap: _isResettingPassword ? null : () => _handlePasswordReset(context),
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    ListTile(
                      leading: const Icon(Icons.account_balance_wallet_outlined, color: Colors.greenAccent),
                      title: const Text('Manajemen Penarikan Dana', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text('Tarik saldo pendapatan tiket ke rekening bank', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      onTap: () => context.push('/withdrawals'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Server & System Info
              const Text(
                'Informasi Jaringan & Gateway',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Host Server IP', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                        Text(ApiConfig.host, style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Auth Gateway', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                        const Text('Port :8081 (Aktif)', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ticket & Financial', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                        const Text('Port :8083 (Aktif)', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Gate Check-In API', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                        const Text('Port :8086 (Aktif)', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                  label: const Text(
                    'Keluar dari Akun',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF111827),
                        title: const Text('Keluar dari Akun?', style: TextStyle(color: Colors.white)),
                        content: const Text(
                          'Anda akan keluar dari sesi akun organizer pada aplikasi ini.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
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
